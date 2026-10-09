import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.exc import SQLAlchemyError

from app.api.errors import install_error_handlers
from app.api.routes import router
from app.application.use_cases import seed_accounts, seed_trips
from app.infrastructure.db import create_engine, create_sessionmaker
from app.infrastructure.passwords import Argon2PasswordHasher
from app.infrastructure.repository import SqlTripRepository, SqlUserRepository
from app.infrastructure.seed import load_seed_trips
from app.infrastructure.settings import Settings

logger = logging.getLogger("app")


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or Settings()

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        engine = create_engine(settings.async_database_url)
        app.state.sessionmaker = create_sessionmaker(engine)
        if settings.seed_on_startup:
            try:
                await _seed(app, settings)
            except (SQLAlchemyError, OSError):
                # Start anyway: /health then reports the database as unavailable
                # (a crash loop would hide the reason). The next start seeds.
                logger.exception("seed skipped: database unavailable")
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
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_methods=["GET", "POST"],
        allow_headers=["Content-Type"],
    )
    app.include_router(router)
    return app


async def _seed(app: FastAPI, settings: Settings) -> None:
    async with app.state.sessionmaker() as session:
        users = SqlUserRepository(session)
        accounts = await seed_accounts(users, Argon2PasswordHasher(), settings.demo_accounts)
        logger.info(
            "seed: %d demo accounts created, %d passwords reset",
            accounts.created,
            accounts.passwords_updated,
        )
        if not settings.seed_file.is_file():
            logger.warning("seed file %s not found, skipping seed trips", settings.seed_file)
            return
        seeds = load_seed_trips(settings.seed_file)
        inserted = 0
        for login in sorted({seed.driver for seed in seeds}):
            driver = await users.get_by_login(login)
            if driver is None:
                raise RuntimeError(f"seed file names unknown driver {login!r}")
            trips = [seed.trip for seed in seeds if seed.driver == login]
            inserted += await seed_trips(SqlTripRepository(session, driver.id), trips)
    logger.info("seed: inserted %d of %d trips from %s", inserted, len(seeds), settings.seed_file)


logging.basicConfig(level=Settings().log_level, format="%(levelname)s %(name)s: %(message)s")
app = create_app()
