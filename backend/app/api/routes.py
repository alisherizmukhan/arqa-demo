from datetime import UTC
from typing import Any

from fastapi import APIRouter, Body, Response, status
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from app.api.deps import CurrentUserDep, DayWindowDep, ReadScopeDep, SessionDep
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
from app.application import access, use_cases
from app.domain.day import format_utc_offset
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
        trips=[TripOut.from_domain(t, window.tz) for t in trips],
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
async def create_trip(
    response: Response,
    session: SessionDep,
    actor: CurrentUserDep,
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
    database primary key, so concurrent retries are safe."""
    driver_id = access.require_driver(actor)
    repo = SqlTripRepository(session, driver_id)
    result = await use_cases.create_trip(repo, trip_in.to_domain(), driver_id)
    response.status_code = status.HTTP_201_CREATED if result.created else status.HTTP_200_OK
    # Echo timestamps in the offset the client used for this request.
    return TripOut.from_domain(result.trip, trip_in.start.tzinfo or UTC)
