"""AUTH_REQUIRED=false: production until the app supports login. Requests without
a token act as user_1 (exactly like before accounts); tokens still work and are
still checked."""

from collections.abc import AsyncIterator

import pytest
from asgi_lifespan import LifespanManager
from httpx import ASGITransport, AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.domain.user import User
from app.infrastructure.settings import Settings
from app.main import create_app
from tests.conftest import STARTUP_TIMEOUT
from tests.integration.conftest import bearer, seed_trips_file, trip_payload

DAY = {"date": "2026-10-01", "tz": "+05:00"}


@pytest.fixture
async def open_api(
    database_url: str,
    users: dict[str, User],
    sessionmaker: async_sessionmaker[AsyncSession],
) -> AsyncIterator[AsyncClient]:
    """The same database as the `app` fixture (accounts, tokens), served by an
    app with AUTH_REQUIRED=false."""
    await seed_trips_file(sessionmaker, users)
    app = create_app(
        Settings(database_url=database_url, seed_on_startup=False, auth_required=False)
    )
    async with (
        LifespanManager(app, startup_timeout=STARTUP_TIMEOUT),
        AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c,
    ):
        yield c


async def test_no_token_acts_as_user_1(open_api: AsyncClient) -> None:
    summary = (await open_api.get("/summary", params=DAY)).json()
    trips = (await open_api.get("/trips", params=DAY)).json()["trips"]
    me = await open_api.get("/auth/me")

    assert (summary["revenue"], summary["commission"], summary["net"]) == (3900, 585, 3315)
    assert [t["id"] for t in trips] == ["t1", "t2"]
    assert me.json()["login"] == "user_1"


async def test_no_token_creates_trips_for_user_1(open_api: AsyncClient) -> None:
    payload = trip_payload(id="legacy-client")

    first = await open_api.post("/trips", json=payload)
    again = await open_api.post("/trips", json=payload)

    assert (first.status_code, again.status_code) == (201, 200)
    mine = (await open_api.get("/trips", params=DAY, headers=bearer("user_1"))).json()
    assert "legacy-client" in [t["id"] for t in mine["trips"]]


async def test_a_token_still_selects_its_user(open_api: AsyncClient) -> None:
    summary = (await open_api.get("/summary", params=DAY, headers=bearer("user_2"))).json()
    everyone = (await open_api.get("/summary", params=DAY, headers=bearer("admin"))).json()

    assert summary["revenue"] == 4800
    assert everyone["revenue"] == 8700


@pytest.mark.parametrize(
    "header", ["Bearer not-a-real-token", "Basic dXNlcl8xOnBhc3N3b3JkXzE=", "Bearer"]
)
async def test_a_bad_token_is_still_401(open_api: AsyncClient, header: str) -> None:
    response = await open_api.get("/summary", params=DAY, headers={"Authorization": header})

    assert response.status_code == 401


async def test_driver_rules_still_apply_to_the_fallback(
    open_api: AsyncClient, users: dict[str, User]
) -> None:
    response = await open_api.get("/summary", params={**DAY, "driver_id": str(users["user_2"].id)})
    admin = await open_api.get("/admin/users")

    assert response.status_code == 403
    assert admin.status_code == 403


async def test_without_user_1_the_fallback_is_unavailable(
    open_api: AsyncClient, sessionmaker: async_sessionmaker[AsyncSession]
) -> None:
    async with sessionmaker() as session:
        await session.execute(text("TRUNCATE trips, withdrawals, sessions, users, login_failures"))
        await session.commit()

    response = await open_api.get("/trips", params=DAY)

    assert response.status_code == 503
    assert response.json()["error"]["code"] == "database_unavailable"
