import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.api.errors import install_error_handlers
from app.api.routes import router
from app.application.use_cases import seed_trips
from app.infrastructure.db import create_engine, create_sessionmaker
from app.infrastructure.repository import SqlTripRepository
from app.infrastructure.seed import load_trips_from_json
from app.infrastructure.settings import Settings

logger = logging.getLogger("app")


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or Settings()

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        engine = create_engine(settings.async_database_url)
        app.state.sessionmaker = create_sessionmaker(engine)
        if settings.seed_on_startup:
            await _seed(app, settings)
        yield
        await engine.dispose()

    app = FastAPI(
        title="Driver Shift Diary API",
        version="0.1.0",
        description=(
            "Trips per day, daily summary and idempotent trip creation for ride-hailing "
            "drivers. Money is integer tenge. Days are computed in the driver's UTC offset "
            "(`tz`, default `+05:00`); a trip belongs to the day it started. "
            'Errors always look like `{"error": {"code", "message", "field"}}`.'
        ),
        lifespan=lifespan,
    )
    install_error_handlers(app)
    app.include_router(router)
    return app


async def _seed(app: FastAPI, settings: Settings) -> None:
    if not settings.seed_file.is_file():
        logger.warning("seed file %s not found, skipping seed", settings.seed_file)
        return
    trips = load_trips_from_json(settings.seed_file)
    async with app.state.sessionmaker() as session:
        inserted = await seed_trips(SqlTripRepository(session), trips)
    logger.info("seed: inserted %d of %d trips from %s", inserted, len(trips), settings.seed_file)


logging.basicConfig(level=Settings().log_level, format="%(levelname)s %(name)s: %(message)s")
app = create_app()
