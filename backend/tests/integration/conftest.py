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

from app.application.auth import hash_token
from app.application.use_cases import seed_trips
from app.domain.user import User
from app.infrastructure.models import TripRow
from app.infrastructure.repository import (
    SqlSessionRepository,
    SqlTripRepository,
    SqlUserRepository,
)
from app.infrastructure.seed import load_seed_trips
from app.infrastructure.settings import Settings
from app.main import create_app
from tests.conftest import STARTUP_TIMEOUT
from tests.factories import SEED_FILE

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


# Fast placeholder for tests that only need the accounts to exist; argon2
# hashing is covered by the seed and login tests.
TEST_PASSWORD_HASH = "!"

# A ready session per demo account (the `app` fixture stores their hashes).
TOKENS = {login: f"test-token-{login}" for login in ("user_1", "user_2", "admin")}


def bearer(login: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {TOKENS[login]}"}


@pytest.fixture
async def app(database_url: str) -> AsyncIterator[FastAPI]:
    """The API on empty tables plus the three demo accounts (no trips)."""
    application = create_app(Settings(database_url=database_url, seed_on_startup=False))
    async with LifespanManager(application, startup_timeout=STARTUP_TIMEOUT):
        async with application.state.sessionmaker() as session:
            await session.execute(
                text("TRUNCATE trips, withdrawals, sessions, users, login_failures")
            )
            await session.commit()
            users = SqlUserRepository(session)
            sessions = SqlSessionRepository(session)
            for account in Settings().demo_accounts:
                await users.insert_if_absent(
                    login=account.login,
                    password_hash=TEST_PASSWORD_HASH,
                    role=account.role,
                    display_name=account.display_name,
                )
                user = await users.get_by_login(account.login)
                assert user is not None
                await sessions.create(
                    user_id=user.id, token_hash=hash_token(TOKENS[account.login]), user_agent=None
                )
        yield application


@pytest.fixture
async def users(app: FastAPI) -> dict[str, User]:
    """The demo accounts by login."""
    found: dict[str, User] = {}
    async with app.state.sessionmaker() as session:
        repo = SqlUserRepository(session)
        for login in ("user_1", "user_2", "admin"):
            user = await repo.get_by_login(login)
            assert user is not None
            found[login] = user
    return found


async def seed_trips_file(
    sessionmaker: async_sessionmaker[AsyncSession], users: dict[str, User]
) -> int:
    """Load data/trips.json, each trip for its driver."""
    seeds = load_seed_trips(SEED_FILE)
    inserted = 0
    async with sessionmaker() as session:
        for login, user in users.items():
            trips = [seed.trip for seed in seeds if seed.driver == login]
            inserted += await seed_trips(SqlTripRepository(session, user.id), trips)
    return inserted


@pytest.fixture
def sessionmaker(app: FastAPI) -> async_sessionmaker[AsyncSession]:
    maker: async_sessionmaker[AsyncSession] = app.state.sessionmaker
    return maker


@pytest.fixture
async def client(app: FastAPI) -> AsyncIterator[AsyncClient]:
    """Signed in as user_1 (the driver with the reference day)."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test", headers=bearer("user_1")
    ) as c:
        yield c


@pytest.fixture
async def anonymous(app: FastAPI) -> AsyncIterator[AsyncClient]:
    """No Authorization header."""
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
