import asyncio
import contextlib
import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from datetime import UTC, datetime, timedelta

import httpx
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.exc import SQLAlchemyError

from app.api.account_routes import router as account_router
from app.api.errors import install_error_handlers
from app.api.geo_routes import router as geo_router
from app.api.routes import router
from app.api.withdrawal_routes import router as withdrawal_router
from app.application.geocoding import GeoService, RateLimiter, TtlCache
from app.application.ports import Geocoder, Router, TripRepository
from app.application.routing import run_route_retries
from app.application.use_cases import seed_accounts, seed_trip_places, seed_trips
from app.infrastructure.db import create_engine, create_sessionmaker
from app.infrastructure.ors import MapsNotConfigured, OrsClient
from app.infrastructure.passwords import Argon2PasswordHasher
from app.infrastructure.repository import SqlTripRepository, SqlUserRepository
from app.infrastructure.seed import load_seed_trips
from app.infrastructure.settings import Settings

logger = logging.getLogger("app")

GEO_CACHE_ENTRIES = 10_000


class Maps:
    """The routing engine and the geocoder (one object in production), and
    the router the background retries use (longer timeout; by default the
    same one)."""

    def __init__(
        self, router: Router, geocoder: Geocoder, background_router: Router | None = None
    ) -> None:
        self.router = router
        self.geocoder = geocoder
        self.background_router = background_router or router


def _now() -> datetime:
    return datetime.now(UTC)


def create_app(settings: Settings | None = None, maps: Maps | None = None) -> FastAPI:
    """`maps` replaces OpenRouteService (tests); by default ORS when
    ORS_API_KEY is set, else straight-line routes and 503 for lookups."""
    settings = settings or Settings()
    clients: list[httpx.AsyncClient] = []
    if maps is None:
        key = settings.ors_key
        if key is None:
            unconfigured = MapsNotConfigured()
            maps = Maps(unconfigured, unconfigured)
        else:
            clients = [
                httpx.AsyncClient(base_url=settings.ors_base_url, timeout=timeout)
                for timeout in (
                    settings.ors_timeout_seconds,
                    settings.ors_background_timeout_seconds,
                )
            ]
            ors = OrsClient(clients[0], key)
            maps = Maps(ors, ors, OrsClient(clients[1], key))
    background_router = maps.background_router

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        engine = create_engine(settings.async_database_url)
        app.state.sessionmaker = create_sessionmaker(engine)
        try:
            if settings.seed_on_startup:
                await _seed(app, settings)
        except (SQLAlchemyError, OSError):
            # Start anyway: /health then reports the database as unavailable
            # (a crash loop would hide the reason). The next start seeds.
            logger.exception("seed skipped: database unavailable")
        # Routes are built in the background, never before the app answers
        # (/health must not wait on ORS) and never in a request.
        retries = (
            asyncio.create_task(_route_retries(app, background_router, settings), name="routes")
            if settings.route_retries_enabled
            else None
        )
        yield
        if retries is not None:
            retries.cancel()
            with contextlib.suppress(asyncio.CancelledError):
                await retries
        for client in clients:
            await client.aclose()
        await engine.dispose()

    app = FastAPI(
        title="Driver Shift Diary API",
        version="0.1.0",
        description=(
            "Trips per day, daily summary and idempotent trip creation for ride-hailing "
            "drivers. Sign in with `POST /auth/login` and send "
            "`Authorization: Bearer <token>`; drivers see their own data, admins all drivers. "
            "Money is integer tenge. Days are computed in the driver's UTC offset "
            "(`tz`, default `+05:00`); a trip belongs to the day it started. "
            'Errors always look like `{"error": {"code", "message", "field"}}`.'
        ),
        lifespan=lifespan,
    )
    app.state.settings = settings
    app.state.router = maps.router
    cache_ttl = timedelta(hours=settings.geo_cache_hours)
    app.state.geo = GeoService(
        geocoder=maps.geocoder,
        area=settings.service_area,
        limiter=RateLimiter(settings.geo_requests_per_minute, timedelta(minutes=1), _now),
        reverse_cache=TtlCache(cache_ttl, GEO_CACHE_ENTRIES, _now),
        search_cache=TtlCache(cache_ttl, GEO_CACHE_ENTRIES, _now),
    )
    # One hasher per app: it caches the dummy hash used for unknown logins.
    app.state.hasher = Argon2PasswordHasher()
    install_error_handlers(app)
    # Bearer tokens travel in a header, never in cookies: no credentials mode.
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_methods=["GET", "POST", "PATCH"],
        allow_headers=["Content-Type", "Authorization"],
    )
    app.include_router(router)
    app.include_router(account_router)
    app.include_router(withdrawal_router)
    app.include_router(geo_router)
    return app


async def _route_retries(app: FastAPI, router: Router, settings: Settings) -> None:
    @contextlib.asynccontextmanager
    async def open_repo() -> AsyncIterator[TripRepository]:
        async with app.state.sessionmaker() as session:
            yield SqlTripRepository(session)

    await run_route_retries(open_repo, router, _now, per_minute=settings.route_retries_per_minute)


async def _seed(app: FastAPI, settings: Settings) -> None:
    async with app.state.sessionmaker() as session:
        users = SqlUserRepository(session)
        accounts = await seed_accounts(users, Argon2PasswordHasher(), settings.demo_accounts)
        logger.info(
            "seed: %d demo accounts created, %d passwords reset, %d unblocked",
            accounts.created,
            accounts.passwords_updated,
            accounts.reactivated,
        )
        if not settings.seed_file.is_file():
            logger.warning("seed file %s not found, skipping seed trips", settings.seed_file)
            return
        seeds = load_seed_trips(settings.seed_file)
        inserted = placed = 0
        for login in sorted({seed.driver for seed in seeds}):
            driver = await users.get_by_login(login)
            if driver is None:
                raise RuntimeError(f"seed file names unknown driver {login!r}")
            trips = [seed.trip for seed in seeds if seed.driver == login]
            repo = SqlTripRepository(session, driver.id)
            inserted += await seed_trips(repo, trips)
            placed += await seed_trip_places(repo, trips)
    logger.info("seed: inserted %d of %d trips from %s", inserted, len(seeds), settings.seed_file)
    if placed:
        logger.info("seed: added places to %d existing seed trips", placed)


logging.basicConfig(level=Settings().log_level, format="%(levelname)s %(name)s: %(message)s")
app = create_app()
