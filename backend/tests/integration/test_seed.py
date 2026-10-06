from asgi_lifespan import LifespanManager
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.application.use_cases import seed_trips
from app.infrastructure.repository import SqlTripRepository
from app.infrastructure.seed import load_trips_from_json
from app.infrastructure.settings import Settings
from app.main import create_app
from tests.factories import SEED_FILE, make_trip
from tests.integration.conftest import count_trips


async def test_seed_is_idempotent(sessionmaker: async_sessionmaker[AsyncSession]) -> None:
    trips = load_trips_from_json(SEED_FILE)

    async with sessionmaker() as session:
        repo = SqlTripRepository(session)
        assert await seed_trips(repo, trips) == len(trips) == 10
        assert await seed_trips(repo, trips) == 0

    assert await count_trips(sessionmaker) == 10


async def test_seed_skipped_when_table_has_data(
    sessionmaker: async_sessionmaker[AsyncSession],
) -> None:
    async with sessionmaker() as session:
        repo = SqlTripRepository(session)
        await repo.insert_if_absent(make_trip(id="existing"))
        assert await seed_trips(repo, load_trips_from_json(SEED_FILE)) == 0

    assert await count_trips(sessionmaker) == 1


async def test_app_startup_seeds_empty_table(
    database_url: str, sessionmaker: async_sessionmaker[AsyncSession]
) -> None:
    # `sessionmaker` comes from the per-test app fixture, which truncated the table.
    seeded_app = create_app(Settings(database_url=database_url, seed_on_startup=True))

    async with LifespanManager(seeded_app):
        pass
    async with LifespanManager(seeded_app):  # restart: must not duplicate
        pass

    assert await count_trips(sessionmaker) == 10
