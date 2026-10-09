from pathlib import Path

import pytest
from asgi_lifespan import LifespanManager
from sqlalchemy import func, select, text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.domain.user import User
from app.infrastructure.models import TripRow, UserRow
from app.infrastructure.passwords import Argon2PasswordHasher
from app.infrastructure.seed import load_seed_trips
from app.infrastructure.settings import Settings
from app.main import create_app
from tests.factories import SEED_FILE
from tests.integration.conftest import count_trips, seed_trips_file


async def test_seed_trips_is_idempotent(
    sessionmaker: async_sessionmaker[AsyncSession], users: dict[str, User]
) -> None:
    total = len(load_seed_trips(SEED_FILE))

    assert await seed_trips_file(sessionmaker, users) == total
    assert await seed_trips_file(sessionmaker, users) == 0
    assert await count_trips(sessionmaker) == total


async def _start(database_url: str, admin_password: str = "admin") -> None:
    settings = Settings(
        database_url=database_url, seed_on_startup=True, seed_admin_password=admin_password
    )
    async with LifespanManager(create_app(settings)):
        pass


async def _clear(sessionmaker: async_sessionmaker[AsyncSession]) -> None:
    async with sessionmaker() as session:
        await session.execute(text("TRUNCATE trips, withdrawals, sessions, users"))
        await session.commit()


async def _hashes(sessionmaker: async_sessionmaker[AsyncSession]) -> dict[str, str]:
    async with sessionmaker() as session:
        rows = await session.execute(select(UserRow.login, UserRow.password_hash))
        return dict(rows.all())


async def test_startup_seeds_accounts_and_trips_once(
    database_url: str, sessionmaker: async_sessionmaker[AsyncSession]
) -> None:
    await _clear(sessionmaker)

    await _start(database_url)
    await _start(database_url)  # restart: nothing duplicated

    hashes = await _hashes(sessionmaker)
    assert set(hashes) == {"user_1", "user_2", "admin"}
    hasher = Argon2PasswordHasher()
    for login, password in [("user_1", "password_1"), ("user_2", "password_2"), ("admin", "admin")]:
        assert hashes[login].startswith("$argon2id$")
        assert password not in hashes[login]
        assert hasher.verify(hashes[login], password)
    assert await count_trips(sessionmaker) == len(load_seed_trips(SEED_FILE))

    async with sessionmaker() as session:
        owners = await session.execute(
            select(UserRow.login, func.count())
            .join(TripRow, TripRow.driver_id == UserRow.id)
            .group_by(UserRow.login)
        )
        by_login = dict(owners.all())
    assert by_login["user_2"] == 2
    assert by_login["user_1"] == len(load_seed_trips(SEED_FILE)) - 2
    assert "admin" not in by_login


async def test_seed_adds_its_trips_to_a_database_with_data(
    database_url: str, sessionmaker: async_sessionmaker[AsyncSession], users: dict[str, User]
) -> None:
    # The `app` fixture created the accounts (placeholder hashes) and no trips.
    async with sessionmaker() as session:
        await session.execute(
            text(
                "INSERT INTO trips (id, driver_id, start_at, end_at, amount, payment, commission)"
                " VALUES ('mine', :d, '2026-10-05T04:00Z', '2026-10-05T04:20Z', 1000, 'cash', 0)"
            ),
            {"d": users["user_1"].id},
        )
        await session.commit()

    await _start(database_url)

    assert await count_trips(sessionmaker) == 1 + len(load_seed_trips(SEED_FILE))
    assert await count_trips(sessionmaker, "mine") == 1
    # The placeholder hashes did not match the configured passwords: reset.
    assert all(h.startswith("$argon2id$") for h in (await _hashes(sessionmaker)).values())


async def test_password_from_env_replaces_the_stored_one(
    database_url: str, sessionmaker: async_sessionmaker[AsyncSession]
) -> None:
    await _clear(sessionmaker)
    await _start(database_url)

    await _start(database_url, admin_password="s3cret-from-env")

    hashes = await _hashes(sessionmaker)
    hasher = Argon2PasswordHasher()
    assert hasher.verify(hashes["admin"], "s3cret-from-env")
    assert not hasher.verify(hashes["admin"], "admin")
    assert hasher.verify(hashes["user_1"], "password_1")


async def test_seed_off_creates_nothing(
    database_url: str, sessionmaker: async_sessionmaker[AsyncSession]
) -> None:
    await _clear(sessionmaker)

    app = create_app(Settings(database_url=database_url, seed_on_startup=False))
    async with LifespanManager(app):
        pass

    assert await _hashes(sessionmaker) == {}
    assert await count_trips(sessionmaker) == 0


async def test_missing_seed_file_still_seeds_accounts(
    database_url: str,
    sessionmaker: async_sessionmaker[AsyncSession],
    tmp_path: Path,
    caplog: pytest.LogCaptureFixture,
) -> None:
    await _clear(sessionmaker)

    settings = Settings(
        database_url=database_url, seed_on_startup=True, seed_file=tmp_path / "missing.json"
    )
    async with LifespanManager(create_app(settings)):
        pass

    assert set(await _hashes(sessionmaker)) == {"user_1", "user_2", "admin"}
    assert await count_trips(sessionmaker) == 0
    assert "not found, skipping seed trips" in caplog.text


async def test_seed_file_with_an_unknown_driver_stops_startup(
    database_url: str, sessionmaker: async_sessionmaker[AsyncSession], tmp_path: Path
) -> None:
    await _clear(sessionmaker)
    bad = tmp_path / "trips.json"
    bad.write_text(
        '[{"id": "x1", "driver": "nobody", "start": "2026-10-01T08:00:00+05:00",'
        ' "end": "2026-10-01T08:20:00+05:00", "amount": 1000, "payment": "cash",'
        ' "commission": 0}]',
        encoding="utf-8",
    )
    app = create_app(Settings(database_url=database_url, seed_on_startup=True, seed_file=bad))

    with pytest.raises(RuntimeError, match="unknown driver 'nobody'"):
        async with LifespanManager(app):
            pass
