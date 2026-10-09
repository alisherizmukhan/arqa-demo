from collections.abc import Sequence
from dataclasses import dataclass
from uuid import UUID

from app.application.errors import TripConflictError
from app.application.ports import OwnedTrip, PasswordHasher, TripRepository, UserRepository
from app.domain.day import DayWindow
from app.domain.summary import DailySummary, calculate_daily_summary
from app.domain.trip import Trip
from app.domain.user import DemoAccount


async def get_trips_for_day(repo: TripRepository, window: DayWindow) -> list[OwnedTrip]:
    return await repo.list_started_between(window.start_utc, window.end_utc)


async def get_daily_summary(repo: TripRepository, window: DayWindow) -> DailySummary:
    owned = await get_trips_for_day(repo, window)
    return calculate_daily_summary(window, [o.trip for o in owned])


@dataclass(frozen=True, slots=True)
class CreateTripResult:
    trip: Trip
    created: bool


async def create_trip(repo: TripRepository, trip: Trip, driver_id: UUID) -> CreateTripResult:
    """Idempotent create keyed by the client-generated trip id, for `driver_id`
    (`repo` is that driver's scope).

    - new id                                   -> created
    - same id, same driver, same payload       -> the stored trip, not created
    - same id, same driver, different payload  -> TripConflictError
    - same id, another driver                  -> TripConflictError (same message:
      nothing about the other driver's trip is revealed)
    """
    if await repo.insert_if_absent(trip):
        return CreateTripResult(trip=trip, created=True)

    existing = await repo.get(trip.id)
    if existing is None:  # pragma: no cover - trips are never deleted by the API
        raise RuntimeError(f"trip {trip.id!r} conflicted on insert but cannot be read")
    if existing.driver_id != driver_id or not existing.trip.has_same_payload(trip):
        raise TripConflictError(trip.id)
    return CreateTripResult(trip=existing.trip, created=False)


async def seed_trips(repo: TripRepository, trips: Sequence[Trip]) -> int:
    """Insert the seed trips that are missing. Returns how many were inserted.

    Safe on every startup and from several replicas at once: each insert is
    idempotent (keyed by the trip id), so existing trips are never touched and a
    database that already has data still gets new seed trips.
    """
    inserted = 0
    for trip in trips:
        inserted += await repo.insert_if_absent(trip)
    return inserted


@dataclass(frozen=True, slots=True)
class SeedAccountsResult:
    created: int
    passwords_updated: int
    reactivated: int = 0


async def seed_accounts(
    users: UserRepository, hasher: PasswordHasher, accounts: Sequence[DemoAccount]
) -> SeedAccountsResult:
    """Create the demo accounts that are missing; reset a password that no
    longer matches the configured one (so production changes it via env);
    unblock a demo account that was blocked. Runs on every start in demo mode,
    so the shared demo accounts always work.

    Plaintext passwords only pass through here: they are hashed, never stored
    or logged.
    """
    created = updated = reactivated = 0
    for account in accounts:
        if await users.insert_if_absent(
            login=account.login,
            password_hash=hasher.hash(account.password),
            role=account.role,
            display_name=account.display_name,
        ):
            created += 1
            continue
        stored = await users.password_hash(account.login)
        if stored is None or not hasher.verify(stored, account.password):
            await users.set_password_hash(account.login, hasher.hash(account.password))
            updated += 1
        user = await users.get_by_login(account.login)
        if user is not None and not user.is_active:
            await users.set_active(user.id, True)
            reactivated += 1
    return SeedAccountsResult(created=created, passwords_updated=updated, reactivated=reactivated)
