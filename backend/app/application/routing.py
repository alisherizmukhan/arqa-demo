"""Trip routes: built once by the routing engine and stored; a straight line
when the engine is unavailable, tried again in the background. Trip creation
never waits on more than one routing call and never fails because of routing."""

import asyncio
import logging
from collections.abc import Awaitable, Callable
from contextlib import AbstractAsyncContextManager
from dataclasses import dataclass
from datetime import datetime

from app.application.errors import MapsUnavailableError, NotFoundError, TripHasNoPlacesError
from app.application.ports import OwnedTrip, Router, TripRepository
from app.domain.route import RouteStatus, TripRoute, next_route_retry
from app.domain.user import Role, User

logger = logging.getLogger(__name__)


async def build_route(router: Router, owned: OwnedTrip) -> TripRoute:
    """The road route between the trip's places, or the straight-line fallback."""
    pickup, dropoff = owned.trip.pickup, owned.trip.dropoff
    if pickup is None or dropoff is None:
        raise TripHasNoPlacesError(owned.trip.id)
    try:
        return await router.route(pickup.point, dropoff.point)
    except MapsUnavailableError as exc:
        logger.warning("route for trip %s: straight line (%s)", owned.trip.id, exc)
        return TripRoute.straight(pickup.point, dropoff.point)


async def route_and_save(
    repo: TripRepository, router: Router, owned: OwnedTrip, now: datetime
) -> OwnedTrip:
    """Build and store the route; a straight line starts the background
    retries afresh (the first one a minute from `now`)."""
    route = await build_route(router, owned)
    retry_at = next_route_retry(0, now) if route.status is RouteStatus.STRAIGHT else None
    await repo.save_route(owned.trip.id, route, attempts=0, retry_at=retry_at)
    return OwnedTrip(trip=owned.trip, driver_id=owned.driver_id, route=route)


async def get_trip(repo: TripRepository, actor: User, trip_id: str) -> OwnedTrip:
    """One trip: a driver only their own (someone else's is 404, as if it did
    not exist); an admin any."""
    owned = await repo.get(trip_id)
    if owned is None or (actor.role is Role.DRIVER and owned.driver_id != actor.id):
        raise NotFoundError(f"trip {trip_id!r} not found")
    return owned


async def rebuild_route(
    repo: TripRepository, router: Router, actor: User, trip_id: str, now: datetime
) -> OwnedTrip:
    """POST /trips/{id}/route: build the route again (after a 'straight'
    fallback). The owner or an admin."""
    owned = await get_trip(repo, actor, trip_id)
    if not owned.trip.has_places:
        raise TripHasNoPlacesError(trip_id)
    return await route_and_save(repo, router, owned, now)


@dataclass(frozen=True, slots=True)
class RetryReport:
    built: int
    failed: int


async def retry_due_routes(
    repo: TripRepository, router: Router, clock: Callable[[], datetime], limit: int
) -> RetryReport:
    """One round of background retries: at most `limit` due routes, one
    engine call each. A failure schedules the next attempt (or stops after
    the last one); the stored straight line stays."""
    due = await repo.list_due_routes(clock(), limit)
    built = 0
    for item in due:
        route = await build_route(router, item.owned)
        attempts = item.attempts + 1
        if route.status is RouteStatus.READY:
            built += 1
            retry_at = None
        else:
            retry_at = next_route_retry(attempts, clock())
        await repo.save_route(item.owned.trip.id, route, attempts=attempts, retry_at=retry_at)
    return RetryReport(built=built, failed=len(due) - built)


async def run_route_retries(
    open_repo: Callable[[], AbstractAsyncContextManager[TripRepository]],
    router: Router,
    clock: Callable[[], datetime],
    *,
    per_minute: int,
    sleep: Callable[[float], Awaitable[None]] = asyncio.sleep,
) -> None:
    """The background loop (started after the app is up, cancelled on
    shutdown): a round of at most `per_minute` routes, then a minute's pause,
    so the engine never gets more than `per_minute` background calls a
    minute. A failing round is logged and the loop goes on."""
    while True:
        try:
            async with open_repo() as repo:
                report = await retry_due_routes(repo, router, clock, per_minute)
            if report.built or report.failed:
                logger.info("routes: %d built, %d still straight", report.built, report.failed)
        except Exception:  # the loop must outlive any one round
            logger.exception("routes: background round failed")
        await sleep(60)
