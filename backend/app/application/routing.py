"""Trip routes: built once by the routing engine and stored; a straight line
when the engine is unavailable. Trip creation never waits on more than one
routing call and never fails because of routing."""

import logging

from app.application.errors import MapsUnavailableError, NotFoundError, TripHasNoPlacesError
from app.application.ports import OwnedTrip, Router, TripRepository
from app.domain.route import TripRoute
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


async def route_and_save(repo: TripRepository, router: Router, owned: OwnedTrip) -> OwnedTrip:
    route = await build_route(router, owned)
    await repo.save_route(owned.trip.id, route)
    return OwnedTrip(trip=owned.trip, driver_id=owned.driver_id, route=route)


async def get_trip(repo: TripRepository, actor: User, trip_id: str) -> OwnedTrip:
    """One trip: a driver only their own (someone else's is 404, as if it did
    not exist); an admin any."""
    owned = await repo.get(trip_id)
    if owned is None or (actor.role is Role.DRIVER and owned.driver_id != actor.id):
        raise NotFoundError(f"trip {trip_id!r} not found")
    return owned


async def rebuild_route(
    repo: TripRepository, router: Router, actor: User, trip_id: str
) -> OwnedTrip:
    """POST /trips/{id}/route: build the route again (after a 'straight'
    fallback). The owner or an admin."""
    owned = await get_trip(repo, actor, trip_id)
    if not owned.trip.has_places:
        raise TripHasNoPlacesError(trip_id)
    return await route_and_save(repo, router, owned)


async def complete_pending_routes(repo: TripRepository, router: Router, limit: int) -> int:
    """Build the routes still pending (seed trips, or a create interrupted
    before its route was saved). Returns how many were built."""
    pending = await repo.list_pending_routes(limit)
    for owned in pending:
        await route_and_save(repo, router, owned)
    return len(pending)
