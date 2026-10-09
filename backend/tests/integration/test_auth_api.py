from datetime import UTC, datetime, timedelta
from typing import Any

import pytest
from fastapi import FastAPI
from httpx import AsyncClient
from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.api.deps import get_now
from app.application.auth import hash_token
from app.domain.user import User
from app.infrastructure.models import SessionRow
from app.infrastructure.passwords import Argon2PasswordHasher
from app.infrastructure.repository import SqlUserRepository
from tests.integration.conftest import TOKENS, bearer

PASSWORDS = {"user_1": "password_1", "user_2": "password_2", "admin": "admin"}


@pytest.fixture
async def real_passwords(
    sessionmaker: async_sessionmaker[AsyncSession], users: dict[str, User]
) -> None:
    """Give the demo accounts their real (argon2id) passwords."""
    hasher = Argon2PasswordHasher()
    async with sessionmaker() as session:
        repo = SqlUserRepository(session)
        for login, password in PASSWORDS.items():
            await repo.set_password_hash(login, hasher.hash(password))


async def _login(client: AsyncClient, login: str, password: str) -> tuple[int, Any]:
    response = await client.post("/auth/login", json={"login": login, "password": password})
    return response.status_code, response.json()


@pytest.mark.usefixtures("real_passwords")
@pytest.mark.parametrize(
    ("login", "role", "name"),
    [
        ("user_1", "driver", "Водитель 1"),
        ("user_2", "driver", "Водитель 2"),
        ("admin", "admin", "Администратор"),
    ],
)
async def test_login_returns_token_and_user(
    anonymous: AsyncClient, login: str, role: str, name: str
) -> None:
    status, body = await _login(anonymous, login, PASSWORDS[login])

    assert status == 200
    assert set(body) == {"token", "user"}
    assert set(body["user"]) == {"id", "login", "role", "display_name"}
    assert body["user"]["login"] == login
    assert body["user"]["role"] == role
    assert body["user"]["display_name"] == name

    me = await anonymous.get("/auth/me", headers={"Authorization": f"Bearer {body['token']}"})
    assert me.status_code == 200
    assert me.json() == body["user"]


@pytest.mark.usefixtures("real_passwords")
async def test_only_the_token_hash_is_stored(
    anonymous: AsyncClient, sessionmaker: async_sessionmaker[AsyncSession]
) -> None:
    _, body = await _login(anonymous, "user_1", "password_1")

    async with sessionmaker() as session:
        hashes = set(await session.scalars(select(SessionRow.token_hash)))
    assert hash_token(body["token"]) in hashes
    assert body["token"] not in hashes


@pytest.mark.usefixtures("real_passwords")
async def test_wrong_password_and_unknown_login_get_the_same_401(anonymous: AsyncClient) -> None:
    wrong = await anonymous.post("/auth/login", json={"login": "user_1", "password": "nope"})
    unknown = await anonymous.post("/auth/login", json={"login": "ghost", "password": "nope"})

    for response in (wrong, unknown):
        assert response.status_code == 401
        assert response.json()["error"]["code"] == "invalid_credentials"
        assert response.headers["www-authenticate"] == "Bearer"
    assert wrong.json() == unknown.json()


@pytest.mark.usefixtures("real_passwords")
async def test_ten_failures_lock_the_login(app: FastAPI, anonymous: AsyncClient) -> None:
    start = datetime(2026, 10, 9, 12, 0, tzinfo=UTC)
    clock = {"now": start}
    app.dependency_overrides[get_now] = lambda: clock["now"]
    try:
        for minute in range(10):
            clock["now"] = start + timedelta(minutes=minute)
            status, _ = await _login(anonymous, "user_1", "nope")
            assert status == 401

        clock["now"] = start + timedelta(minutes=10)
        locked = await anonymous.post(
            "/auth/login", json={"login": "user_1", "password": "password_1"}
        )
        assert locked.status_code == 429
        assert locked.json()["error"]["code"] == "rate_limited"
        assert locked.headers["retry-after"] == "300"
        # Per login: another account can still sign in.
        assert (await _login(anonymous, "user_2", "password_2"))[0] == 200

        clock["now"] = start + timedelta(minutes=15, seconds=1)
        assert (await _login(anonymous, "user_1", "password_1"))[0] == 200
    finally:
        app.dependency_overrides.pop(get_now)


@pytest.mark.usefixtures("real_passwords")
async def test_blocked_account_login(
    anonymous: AsyncClient, sessionmaker: async_sessionmaker[AsyncSession], users: dict[str, User]
) -> None:
    async with sessionmaker() as session:
        await SqlUserRepository(session).set_active(users["user_1"].id, False)

    right = await anonymous.post("/auth/login", json={"login": "user_1", "password": "password_1"})
    wrong = await anonymous.post("/auth/login", json={"login": "user_1", "password": "nope"})

    assert right.status_code == 403
    assert right.json()["error"]["code"] == "account_disabled"
    assert wrong.status_code == 401


async def test_login_validation_is_422(anonymous: AsyncClient) -> None:
    response = await anonymous.post("/auth/login", json={"login": "user_1"})

    assert response.status_code == 422
    assert response.json()["error"] == {
        "code": "missing_field",
        "message": "Field required",
        "field": "password",
    }


@pytest.mark.parametrize(
    ("method", "path"),
    [
        ("GET", "/trips?date=2026-10-01"),
        ("GET", "/summary?date=2026-10-01"),
        ("POST", "/trips"),
        ("GET", "/auth/me"),
        ("POST", "/auth/logout"),
        ("GET", "/admin/users"),
        ("PATCH", "/admin/users/00000000-0000-4000-8000-000000000001"),
        ("POST", "/admin/users/00000000-0000-4000-8000-000000000001/revoke-sessions"),
    ],
)
@pytest.mark.parametrize(
    "headers",
    [
        {},
        {"Authorization": "Bearer not-a-real-token"},
        {"Authorization": "Basic dXNlcl8xOnBhc3N3b3JkXzE="},
        {"Authorization": "Bearer"},
    ],
    ids=["no-header", "unknown-token", "basic-scheme", "empty-bearer"],
)
async def test_every_protected_endpoint_needs_a_valid_token(
    anonymous: AsyncClient, method: str, path: str, headers: dict[str, str]
) -> None:
    response = await anonymous.request(method, path, headers=headers, json={})

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "unauthorized"
    assert response.headers["www-authenticate"] == "Bearer"


async def test_health_needs_no_token(anonymous: AsyncClient) -> None:
    assert (await anonymous.get("/health")).status_code == 200


async def test_logout_revokes_only_the_current_session(
    anonymous: AsyncClient, sessionmaker: async_sessionmaker[AsyncSession], users: dict[str, User]
) -> None:
    async with sessionmaker() as session:
        await session.execute(
            text("INSERT INTO sessions (user_id, token_hash) VALUES (:u, :h)"),
            {"u": users["user_1"].id, "h": hash_token("second-device")},
        )
        await session.commit()

    response = await anonymous.post("/auth/logout", headers=bearer("user_1"))

    assert response.status_code == 204
    assert (await anonymous.get("/auth/me", headers=bearer("user_1"))).status_code == 401
    other = await anonymous.get("/auth/me", headers={"Authorization": "Bearer second-device"})
    assert other.status_code == 200


async def test_blocked_users_token_is_rejected(
    anonymous: AsyncClient, sessionmaker: async_sessionmaker[AsyncSession], users: dict[str, User]
) -> None:
    async with sessionmaker() as session:
        await SqlUserRepository(session).set_active(users["user_2"].id, False)

    response = await anonymous.get("/auth/me", headers=bearer("user_2"))

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "unauthorized"


async def test_last_used_at_is_updated_at_most_hourly(
    app: FastAPI, anonymous: AsyncClient, sessionmaker: async_sessionmaker[AsyncSession]
) -> None:
    async def last_used() -> datetime:
        async with sessionmaker() as session:
            value = await session.scalar(
                select(SessionRow.last_used_at).where(
                    SessionRow.token_hash == hash_token(TOKENS["user_1"])
                )
            )
        assert value is not None
        return value

    created = await last_used()
    clock = {"now": created + timedelta(minutes=30)}
    app.dependency_overrides[get_now] = lambda: clock["now"]
    try:
        await anonymous.get("/auth/me", headers=bearer("user_1"))
        assert await last_used() == created

        clock["now"] = created + timedelta(hours=2)
        await anonymous.get("/auth/me", headers=bearer("user_1"))
        assert await last_used() == clock["now"]
    finally:
        app.dependency_overrides.pop(get_now)
