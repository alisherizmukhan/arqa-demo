"""The app answers before any route is built: a hanging map service never
delays startup or /health (Railway's healthcheck), and shutdown stops the
background round cleanly."""

import asyncio
import time

from asgi_lifespan import LifespanManager
from httpx import ASGITransport, AsyncClient
from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.domain.geo import GeoPoint
from app.domain.route import TripRoute
from app.infrastructure.models import TripRow
from app.infrastructure.settings import Settings
from app.main import Maps, create_app
from tests.conftest import STARTUP_TIMEOUT
from tests.fakes import FakeMaps


class HangingRouter:
    """A map service that never answers (until the call is cancelled)."""

    def __init__(self) -> None:
        self.started = asyncio.Event()
        self.cancelled = False

    async def route(self, a: GeoPoint, b: GeoPoint) -> TripRoute:
        del a, b
        self.started.set()
        try:
            await asyncio.Event().wait()
        except asyncio.CancelledError:
            self.cancelled = True
            raise
        raise AssertionError("unreachable")


async def test_health_answers_while_the_map_service_hangs(
    database_url: str, sessionmaker: async_sessionmaker[AsyncSession]
) -> None:
    async with sessionmaker() as session:
        await session.execute(text("TRUNCATE trips, withdrawals, sessions, users"))
        await session.commit()
    hanging, geocoder = HangingRouter(), FakeMaps()
    app = create_app(
        Settings(database_url=database_url, seed_on_startup=True, route_retries_enabled=True),
        maps=Maps(geocoder, geocoder, background_router=hanging),
    )

    began = time.monotonic()
    async with LifespanManager(app, startup_timeout=STARTUP_TIMEOUT):
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
            health = await c.get("/health")
        answered = time.monotonic() - began
        # The background round is stuck on the first seed route meanwhile.
        await asyncio.wait_for(hanging.started.wait(), timeout=10)

    assert health.status_code == 200
    assert answered < STARTUP_TIMEOUT
    assert hanging.cancelled  # shutdown cancelled the stuck call
    assert geocoder.calls == []  # requests never used the background router
    async with sessionmaker() as session:
        statuses = set(await session.scalars(select(TripRow.route_status)))
    # Nothing was built; the seed routes wait for the next start's round.
    assert "pending" in statuses
    assert "ready" not in statuses
