from datetime import UTC, timezone
from typing import Annotated, Any

from fastapi import APIRouter, Body, Path, Query, Response, status
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from app.api.deps import (
    CurrentUserDep,
    DayWindowDep,
    GeoDep,
    ReadScopeDep,
    RouterDep,
    SessionDep,
    SettingsDep,
)
from app.api.errors import ApiError, ApiErrorCode
from app.api.schemas import (
    DayTripsOut,
    ErrorResponse,
    HealthOut,
    SummaryOut,
    TripIn,
    TripOut,
    error_example,
)
from app.application import access, routing, use_cases
from app.domain.day import format_utc_offset, parse_utc_offset
from app.infrastructure.repository import SqlTripRepository

router = APIRouter()

_ERRORS: dict[int | str, dict[str, Any]] = {
    status.HTTP_422_UNPROCESSABLE_CONTENT: {
        "model": ErrorResponse,
        "description": "Validation error",
    },
}

# Shared by every endpoint that needs a signed-in user.
AUTH_ERRORS: dict[int | str, dict[str, Any]] = error_example(
    status.HTTP_401_UNAUTHORIZED,
    "No token, or an unknown, revoked or blocked user's token",
    "unauthorized",
    "a valid bearer token is required",
)
_READ_ERRORS: dict[int | str, dict[str, Any]] = {
    **AUTH_ERRORS,
    **error_example(
        status.HTTP_403_FORBIDDEN,
        "A driver passed driver_id",
        "forbidden",
        "drivers cannot choose a driver_id",
    ),
    **error_example(
        status.HTTP_404_NOT_FOUND,
        "Admin: driver_id is not a driver",
        "not_found",
        "driver 6f1c… not found",
    ),
    **_ERRORS,
}


@router.get("/health", tags=["meta"], responses={503: {"model": ErrorResponse}})
async def health(session: SessionDep) -> HealthOut:
    """Liveness + database connectivity (used by the Railway healthcheck)."""
    try:
        await session.execute(text("SELECT 1"))
    except (SQLAlchemyError, OSError) as exc:
        raise ApiError(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            ApiErrorCode.DATABASE_UNAVAILABLE,
            "database is unavailable",
        ) from exc
    return HealthOut(status="ok", database="ok")


@router.get("/trips", tags=["trips"], responses=_READ_ERRORS)
async def list_trips(window: DayWindowDep, repo: ReadScopeDep) -> DayTripsOut:
    """Trips that **started** on the given local day, ordered by start.

    A trip crossing midnight belongs to the day it started. A driver gets their
    own trips; an admin gets all drivers, or one with `driver_id`.
    """
    trips = await use_cases.get_trips_for_day(repo, window)
    return DayTripsOut(
        date=window.day,
        tz=format_utc_offset(window.tz),
        trips=[TripOut.from_domain(o.trip, window.tz, o.driver_id, o.route) for o in trips],
    )


@router.get("/summary", tags=["trips"], responses=_READ_ERRORS)
async def daily_summary(window: DayWindowDep, repo: ReadScopeDep) -> SummaryOut:
    """Trip count, revenue, commission, net payout and cash/card split for a local day
    (the signed-in driver's; for an admin, all drivers or `driver_id`)."""
    return SummaryOut.from_domain(await use_cases.get_daily_summary(repo, window), window.tz)


@router.post(
    "/trips",
    tags=["trips"],
    status_code=status.HTTP_201_CREATED,
    responses={
        status.HTTP_201_CREATED: {"description": "Created"},
        status.HTTP_200_OK: {
            "model": TripOut,
            "description": "Already exists with the same payload (safe retry); nothing created",
        },
        **error_example(
            status.HTTP_409_CONFLICT,
            "This id already exists with a different payload, or belongs to another driver",
            "trip_conflict",
            "trip '3f2b8c1e-9a4d-4e6b-8f1a-2c7d5e9b0a13' already exists with a different payload",
        ),
        **AUTH_ERRORS,
        **error_example(
            status.HTTP_403_FORBIDDEN,
            "Not a driver (admins do not create trips)",
            "forbidden",
            "only drivers can do this",
        ),
        **_ERRORS,
    },
)
async def create_trip(  # noqa: PLR0913, PLR0917 - FastAPI dependencies
    response: Response,
    session: SessionDep,
    actor: CurrentUserDep,
    router: RouterDep,
    settings: SettingsDep,
    trip_in: TripIn = Body(  # noqa: B008 - FastAPI's way to declare body examples
        openapi_examples={
            "new trip": {
                "summary": "New trip",
                "value": {
                    "id": "3f2b8c1e-9a4d-4e6b-8f1a-2c7d5e9b0a13",
                    "start": "2026-10-01T10:00:00+05:00",
                    "end": "2026-10-01T10:25:00+05:00",
                    "amount": 2200,
                    "payment": "card",
                    "commission": 330,
                },
            },
            "with places": {
                "summary": "New trip with start and end on the map (the server builds the route)",
                "value": {
                    "id": "c4e1a7d2-5b3f-4a8e-9c6d-0f2b7e1a3d58",
                    "start": "2026-10-01T10:00:00+05:00",
                    "end": "2026-10-01T10:25:00+05:00",
                    "amount": 2200,
                    "payment": "card",
                    "commission": 330,
                    "pickup": {"lat": 43.26275, "lng": 76.95519, "label": "Зелёный базар"},
                    "dropoff": {"lat": 43.2185, "lng": 76.928, "label": "Есентай Молл"},
                },
            },
            "invalid": {
                "summary": "Invalid: commission > amount (422)",
                "value": {
                    "id": "8a1c0f4e-2b7d-4c3a-9e5f-1d6b8a2c4e7f",
                    "start": "2026-10-01T10:00:00+05:00",
                    "end": "2026-10-01T10:25:00+05:00",
                    "amount": 1000,
                    "payment": "cash",
                    "commission": 1500,
                },
            },
        }
    ),
) -> TripOut:
    """Create a trip for the signed-in driver. Idempotent by `id`: the client
    generates it once and reuses it on retries. Same id + same payload → 200 with
    the stored trip; same id + different payload → 409; an id already used by
    another driver → 409 (nothing about that trip is returned). Enforced by the
    database primary key, so concurrent retries are safe.

    Optional `pickup` / `dropoff` (both or neither, inside Almaty, more than
    50 m apart) are part of the compared payload. With them the server builds
    the road route once (`route.status` ready); if the map service fails the
    trip is still created, with a straight line (`straight`)."""
    driver_id = access.require_driver(actor)
    repo = SqlTripRepository(session, driver_id)
    result = await use_cases.create_trip(
        repo, trip_in.to_domain(), driver_id, router=router, area=settings.service_area
    )
    response.status_code = status.HTTP_201_CREATED if result.created else status.HTTP_200_OK
    # Echo timestamps in the offset the client used for this request.
    return TripOut.from_domain(result.trip, trip_in.start.tzinfo or UTC, driver_id, result.route)


TripIdPath = Annotated[str, Path(max_length=64, description="The trip's id")]
TzQuery = Annotated[
    str, Query(description="UTC offset for the timestamps in the answer, ±HH:MM or Z")
]
_ONE_TRIP_ERRORS: dict[int | str, dict[str, Any]] = {
    **AUTH_ERRORS,
    **error_example(
        status.HTTP_404_NOT_FOUND,
        "No such trip, or another driver's trip",
        "not_found",
        "trip 't1' not found",
    ),
    **_ERRORS,
}


def _tz(raw: str) -> timezone:
    # An unencoded '+' in a query string arrives as a space.
    return parse_utc_offset("+" + raw[1:] if raw.startswith(" ") else raw)


@router.get("/trips/{trip_id}", tags=["trips"], responses=_ONE_TRIP_ERRORS)
async def get_trip(
    trip_id: TripIdPath, session: SessionDep, actor: CurrentUserDep, tz: TzQuery = "+05:00"
) -> TripOut:
    """One trip with its places and route: a driver their own (another
    driver's trip is 404), an admin any."""
    owned = await routing.get_trip(SqlTripRepository(session), actor, trip_id)
    return TripOut.from_domain(owned.trip, _tz(tz), owned.driver_id, owned.route)


@router.post(
    "/trips/{trip_id}/route",
    tags=["trips"],
    responses={
        **_ONE_TRIP_ERRORS,
        **error_example(
            status.HTTP_409_CONFLICT,
            "The trip has no pickup and dropoff",
            "no_places",
            "trip 't9' has no pickup and dropoff, so it has no route",
        ),
        **error_example(
            status.HTTP_429_TOO_MANY_REQUESTS,
            "Too many map requests from this user",
            "rate_limited",
            "too many map requests, try again later",
        ),
    },
)
async def rebuild_route(  # noqa: PLR0913, PLR0917 - FastAPI dependencies
    trip_id: TripIdPath,
    session: SessionDep,
    actor: CurrentUserDep,
    router: RouterDep,
    geo: GeoDep,
    tz: TzQuery = "+05:00",
) -> TripOut:
    """Build the trip's route again, e.g. after a `straight` fallback. The
    owner or an admin. If the map service is still unavailable the answer is
    200 with a straight line again."""
    geo.limiter.check(actor.id)
    owned = await routing.rebuild_route(SqlTripRepository(session), router, actor, trip_id)
    return TripOut.from_domain(owned.trip, _tz(tz), owned.driver_id, owned.route)
