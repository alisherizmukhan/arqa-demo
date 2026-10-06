from collections.abc import Sequence
from dataclasses import dataclass

from app.application.errors import TripConflictError
from app.application.ports import TripRepository
from app.domain.day import DayWindow
from app.domain.summary import DailySummary, calculate_daily_summary
from app.domain.trip import Trip


async def get_trips_for_day(repo: TripRepository, window: DayWindow) -> list[Trip]:
    return await repo.list_started_between(window.start_utc, window.end_utc)


async def get_daily_summary(repo: TripRepository, window: DayWindow) -> DailySummary:
    return calculate_daily_summary(window, await get_trips_for_day(repo, window))


@dataclass(frozen=True, slots=True)
class CreateTripResult:
    trip: Trip
    created: bool


async def create_trip(repo: TripRepository, trip: Trip) -> CreateTripResult:
    """Idempotent create keyed by the client-generated trip id.

    - new id                    -> created
    - same id, same payload     -> the stored trip, not created
    - same id, different payload -> TripConflictError
    """
    if await repo.insert_if_absent(trip):
        return CreateTripResult(trip=trip, created=True)

    existing = await repo.get(trip.id)
    if existing is None:  # pragma: no cover - trips are never deleted
        raise RuntimeError(f"trip {trip.id!r} conflicted on insert but cannot be read")
    if not existing.has_same_payload(trip):
        raise TripConflictError(trip.id)
    return CreateTripResult(trip=existing, created=False)


async def seed_trips(repo: TripRepository, trips: Sequence[Trip]) -> int:
    """Load initial data into an empty store. Returns how many trips were inserted.

    Safe to run on every startup and from several replicas at once: it is skipped
    when data exists, and each insert is itself idempotent.
    """
    if await repo.count() > 0:
        return 0
    inserted = 0
    for trip in trips:
        inserted += await repo.insert_if_absent(trip)
    return inserted
