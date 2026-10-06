from datetime import UTC
from typing import Any

from fastapi import APIRouter, Body, Response, status
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from app.api.deps import DayWindowDep, RepositoryDep, SessionDep
from app.api.errors import ApiError, ApiErrorCode
from app.api.schemas import DayTripsOut, ErrorResponse, HealthOut, SummaryOut, TripIn, TripOut
from app.application import use_cases
from app.domain.day import format_utc_offset

router = APIRouter()

_ERRORS: dict[int | str, dict[str, Any]] = {
    status.HTTP_422_UNPROCESSABLE_CONTENT: {
        "model": ErrorResponse,
        "description": "Validation error",
    },
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


@router.get("/trips", tags=["trips"], responses=_ERRORS)
async def list_trips(window: DayWindowDep, repo: RepositoryDep) -> DayTripsOut:
    """Trips that **started** on the given local day, ordered by start.

    A trip crossing midnight belongs to the day it started.
    """
    trips = await use_cases.get_trips_for_day(repo, window)
    return DayTripsOut(
        date=window.day,
        tz=format_utc_offset(window.tz),
        trips=[TripOut.from_domain(t, window.tz) for t in trips],
    )


@router.get("/summary", tags=["trips"], responses=_ERRORS)
async def daily_summary(window: DayWindowDep, repo: RepositoryDep) -> SummaryOut:
    """Trip count, revenue, commission, net payout and cash/card split for a local day."""
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
        status.HTTP_409_CONFLICT: {
            "model": ErrorResponse,
            "description": "This id already exists with a different payload",
        },
        **_ERRORS,
    },
)
async def create_trip(
    response: Response,
    repo: RepositoryDep,
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
    """Create a trip. Idempotent by `id`: the client generates it once and reuses it
    on retries. Same id + same payload → 200 with the stored trip; same id +
    different payload → 409. Enforced by the database primary key, so concurrent
    retries are safe."""
    result = await use_cases.create_trip(repo, trip_in.to_domain())
    response.status_code = status.HTTP_201_CREATED if result.created else status.HTTP_200_OK
    # Echo timestamps in the offset the client used for this request.
    return TripOut.from_domain(result.trip, trip_in.start.tzinfo or UTC)
