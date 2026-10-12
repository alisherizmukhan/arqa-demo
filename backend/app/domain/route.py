"""A trip's road route, built by the server (never sent by the client)."""

from __future__ import annotations

from dataclasses import dataclass
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
