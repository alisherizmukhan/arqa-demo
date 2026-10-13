"""A trip's road route, built by the server (never sent by the client)."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta
from enum import StrEnum

from app.domain import polyline
from app.domain.geo import GeoPoint, haversine_m


class RouteStatus(StrEnum):
    NONE = "none"  # the trip has no places
    PENDING = "pending"  # places set, route not built yet
    READY = "ready"  # built by the routing engine
    STRAIGHT = "straight"  # the routing engine failed: a straight line instead
    FAILED = "failed"  # reserved: nothing could be stored


@dataclass(frozen=True, slots=True, kw_only=True)
class TripRoute:
    status: RouteStatus
    polyline: str | None = None
    distance_m: int | None = None
    duration_s: int | None = None

    @classmethod
    def none(cls) -> TripRoute:
        return cls(status=RouteStatus.NONE)

    @classmethod
    def pending(cls) -> TripRoute:
        return cls(status=RouteStatus.PENDING)

    @classmethod
    def straight(cls, a: GeoPoint, b: GeoPoint) -> TripRoute:
        """The fallback: a straight line and its length; no duration (unknown)."""
        return cls(
            status=RouteStatus.STRAIGHT,
            polyline=polyline.encode([a, b]),
            distance_m=round(haversine_m(a, b)),
        )


NO_ROUTE = TripRoute.none()

# A route the engine could not build (a straight line, or pending) is tried
# again in the background (docs/MAPS.md): 1 min, 5 min and 30 min after a
# failure, then every 6 h, at most this many background attempts per trip.
ROUTE_RETRY_DELAYS = (
    timedelta(minutes=1),
    timedelta(minutes=5),
    timedelta(minutes=30),
    timedelta(hours=6),
)
MAX_ROUTE_ATTEMPTS = 10


def next_route_retry(attempts: int, now: datetime) -> datetime | None:
    """When to try a failed route again after `attempts` background attempts
    (0 when only the request's own call failed); None once they are spent."""
    if attempts >= MAX_ROUTE_ATTEMPTS:
        return None
    return now + ROUTE_RETRY_DELAYS[min(attempts, len(ROUTE_RETRY_DELAYS) - 1)]
