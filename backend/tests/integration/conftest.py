"""Integration tests run against a real Postgres (docker compose, or the CI service).

TEST_DATABASE_URL defaults to the docker-compose test database. Locally the tests
are skipped if it is unreachable; in CI (CI=true) that is a failure instead.
"""

import os
import socket
import uuid
from collections.abc import AsyncIterator
from pathlib import Path
from typing import Any
from urllib.parse import urlsplit

import pytest
from alembic import command
from alembic.config import Config
from asgi_lifespan import LifespanManager
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient
from sqlalchemy import func, select, text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.infrastructure.models import TripRow
from app.infrastructure.settings import Settings
from app.main import create_app

TEST_DATABASE_URL = os.environ.get(
    "TEST_DATABASE_URL", "postgresql://postgres:postgres@localhost:5433/driver_diary_test"
)
ALEMBIC_INI = Path(__file__).resolve().parents[2] / "alembic.ini"


def _reachable(url: str) -> bool:
    parts = urlsplit(url)
    try:
        with socket.create_connection((parts.hostname or "localhost", parts.port or 5432), 1):
            return True
    except OSError:
        return False


@pytest.fixture(scope="session")
def database_url() -> str:
    """Reachable test DB with a fresh schema (down + up also checks the downgrade)."""
    if not _reachable(TEST_DATABASE_URL):
        message = f"Postgres not reachable at {TEST_DATABASE_URL}; run `docker compose up -d db`"
        if os.environ.get("CI"):
            pytest.fail(message)
        pytest.skip(message)
    config = Config(str(ALEMBIC_INI))
    config.attributes["database_url"] = TEST_DATABASE_URL
    config.attributes["configure_logger"] = False
    command.downgrade(config, "base")
    command.upgrade(config, "head")
    return TEST_DATABASE_URL


@pytest.fixture
async def app(database_url: str) -> AsyncIterator[FastAPI]:
    application = create_app(Settings(database_url=database_url, seed_on_startup=False))
    async with LifespanManager(application):
        async with application.state.sessionmaker() as session:
            await session.execute(text("TRUNCATE trips"))
            await session.commit()
        yield application


@pytest.fixture
def sessionmaker(app: FastAPI) -> async_sessionmaker[AsyncSession]:
    maker: async_sessionmaker[AsyncSession] = app.state.sessionmaker
    return maker


@pytest.fixture
async def client(app: FastAPI) -> AsyncIterator[AsyncClient]:
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        yield c


async def count_trips(
    sessionmaker: async_sessionmaker[AsyncSession], trip_id: str | None = None
) -> int:
    stmt = select(func.count()).select_from(TripRow)
    if trip_id is not None:
        stmt = stmt.where(TripRow.id == trip_id)
    async with sessionmaker() as session:
        return await session.scalar(stmt) or 0


def trip_payload(**overrides: Any) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "id": str(uuid.uuid4()),
        "start": "2026-10-01T10:00:00+05:00",
        "end": "2026-10-01T10:25:00+05:00",
        "amount": 2200,
        "payment": "card",
        "commission": 330,
    }
    payload.update(overrides)
    return payload
