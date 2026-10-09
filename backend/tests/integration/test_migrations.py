"""Migration 0002 on a database that already has trips (the deployed one does)."""

import asyncio
from collections.abc import Iterator
from pathlib import Path

import pytest
from alembic import command
from alembic.config import Config
from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine

from app.infrastructure.settings import Settings

ALEMBIC_INI = Path(__file__).resolve().parents[2] / "alembic.ini"


def _config(database_url: str) -> Config:
    config = Config(str(ALEMBIC_INI))
    config.attributes["database_url"] = database_url
    config.attributes["configure_logger"] = False
    return config


def _run(database_url: str, *statements: str) -> list[tuple[object, ...]]:
    """Run SQL in its own event loop (the migration tests are synchronous:
    alembic's env.py calls asyncio.run itself)."""
    return asyncio.run(_run_async(database_url, *statements))


async def _run_async(database_url: str, *statements: str) -> list[tuple[object, ...]]:
    engine = create_async_engine(Settings(database_url=database_url).async_database_url)
    rows: list[tuple[object, ...]] = []
    async with engine.begin() as connection:
        for statement in statements:
            result = await connection.execute(text(statement))
            if result.returns_rows:
                rows = [tuple(row) for row in result]
    await engine.dispose()
    return rows


@pytest.fixture
def at_0001(database_url: str) -> Iterator[Config]:
    """The schema as deployed before the accounts iteration; head again afterwards."""
    config = _config(database_url)
    command.downgrade(config, "base")
    command.upgrade(config, "0001")
    yield config
    command.downgrade(config, "base")
    command.upgrade(config, "head")


def test_existing_trips_are_backfilled_to_user_1(database_url: str, at_0001: Config) -> None:
    _run(
        database_url,
        "INSERT INTO trips (id, start_at, end_at, amount, payment, commission) VALUES"
        " ('old-1', '2026-10-01T03:10Z', '2026-10-01T03:32Z', 2400, 'card', 360),"
        " ('old-2', '2026-10-07T03:14Z', '2026-10-07T03:23Z', 500, 'card', 0)",
    )

    command.upgrade(at_0001, "head")

    rows = _run(
        database_url,
        "SELECT t.id, u.login, u.role, u.password_hash FROM trips t"
        " JOIN users u ON u.id = t.driver_id ORDER BY t.id",
    )
    assert rows == [
        ("old-1", "user_1", "driver", "!"),
        ("old-2", "user_1", "driver", "!"),
    ]
    nullable = _run(
        database_url,
        "SELECT is_nullable FROM information_schema.columns"
        " WHERE table_name = 'trips' AND column_name = 'driver_id'",
    )
    assert nullable == [("NO",)]


def test_empty_database_gets_no_placeholder_user(database_url: str, at_0001: Config) -> None:
    command.upgrade(at_0001, "head")

    assert _run(database_url, "SELECT count(*) FROM users") == [(0,)]
