import pytest
from httpx import AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.application.auth import hash_token
from app.domain.user import User
from tests.integration.conftest import bearer

UNKNOWN = "00000000-0000-4000-8000-000000000999"


async def test_admin_lists_users_drivers_first(anonymous: AsyncClient) -> None:
    response = await anonymous.get("/admin/users", headers=bearer("admin"))

    assert response.status_code == 200
    users = response.json()
    assert [u["login"] for u in users] == ["user_1", "user_2", "admin"]
    assert set(users[0]) == {"id", "login", "role", "display_name", "is_active"}
    assert all(u["is_active"] for u in users)
    assert "password_hash" not in str(users)


@pytest.mark.parametrize("login", ["user_1", "user_2"])
@pytest.mark.parametrize(
    "call",
    [
        ("GET", "/admin/users", None),
        ("PATCH", "/admin/users/{id}", {"is_active": False}),
        ("POST", "/admin/users/{id}/revoke-sessions", None),
    ],
    ids=["list", "block", "revoke"],
)
async def test_drivers_get_403_on_admin_endpoints(
    anonymous: AsyncClient,
    users: dict[str, User],
    login: str,
    call: tuple[str, str, dict[str, bool] | None],
) -> None:
    method, path, body = call
    url = path.format(id=users["user_2"].id)

    response = await anonymous.request(method, url, json=body, headers=bearer(login))

    assert response.status_code == 403
    assert response.json()["error"]["code"] == "forbidden"
    # Nothing changed: user_2 is still active and signed in.
    assert (await anonymous.get("/auth/me", headers=bearer("user_2"))).status_code == 200


async def test_block_and_unblock(anonymous: AsyncClient, users: dict[str, User]) -> None:
    url = f"/admin/users/{users['user_2'].id}"

    blocked = await anonymous.patch(url, json={"is_active": False}, headers=bearer("admin"))

    assert blocked.status_code == 200
    assert blocked.json()["is_active"] is False
    # Blocking ended the session; unblocking does not bring it back.
    assert (await anonymous.get("/auth/me", headers=bearer("user_2"))).status_code == 401
    unblocked = await anonymous.patch(url, json={"is_active": True}, headers=bearer("admin"))
    assert unblocked.json()["is_active"] is True
    assert (await anonymous.get("/auth/me", headers=bearer("user_2"))).status_code == 401


async def test_admin_cannot_block_themselves(
    anonymous: AsyncClient, users: dict[str, User]
) -> None:
    response = await anonymous.patch(
        f"/admin/users/{users['admin'].id}", json={"is_active": False}, headers=bearer("admin")
    )

    assert response.status_code == 403
    assert (await anonymous.get("/auth/me", headers=bearer("admin"))).status_code == 200


async def test_revoke_sessions_signs_the_user_out_everywhere(
    anonymous: AsyncClient, sessionmaker: async_sessionmaker[AsyncSession], users: dict[str, User]
) -> None:
    async with sessionmaker() as session:
        await session.execute(
            text("INSERT INTO sessions (user_id, token_hash) VALUES (:u, :h)"),
            {"u": users["user_1"].id, "h": hash_token("phone-2")},
        )
        await session.commit()

    response = await anonymous.post(
        f"/admin/users/{users['user_1'].id}/revoke-sessions", headers=bearer("admin")
    )

    assert response.status_code == 200
    assert response.json() == {"revoked": 2}
    for token in ("test-token-user_1", "phone-2"):
        me = await anonymous.get("/auth/me", headers={"Authorization": f"Bearer {token}"})
        assert me.status_code == 401
    # The account itself stays active.
    listed = (await anonymous.get("/admin/users", headers=bearer("admin"))).json()
    assert next(u for u in listed if u["login"] == "user_1")["is_active"] is True


@pytest.mark.parametrize(
    ("method", "path", "body"),
    [
        ("PATCH", f"/admin/users/{UNKNOWN}", {"is_active": False}),
        ("POST", f"/admin/users/{UNKNOWN}/revoke-sessions", None),
    ],
)
async def test_unknown_user_is_404(
    anonymous: AsyncClient, method: str, path: str, body: dict[str, bool] | None
) -> None:
    response = await anonymous.request(method, path, json=body, headers=bearer("admin"))

    assert response.status_code == 404
    assert response.json()["error"]["code"] == "not_found"


async def test_patch_validation_is_422(anonymous: AsyncClient, users: dict[str, User]) -> None:
    url = f"/admin/users/{users['user_1'].id}"

    for body in ({}, {"is_active": "nope"}, {"is_active": True, "role": "admin"}):
        response = await anonymous.patch(url, json=body, headers=bearer("admin"))
        assert response.status_code == 422
