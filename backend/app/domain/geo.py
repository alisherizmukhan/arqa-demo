"""Points on the map, the service area and straight-line distance."""

from __future__ import annotations

import math
from dataclasses import dataclass

from app.domain.errors import DomainValidationError, ErrorCode

# Mean Earth radius (m), the usual value for the haversine formula.
EARTH_RADIUS_M = 6_371_008.8

# A trip's start and end closer than this are the same place (a mis-tap).
MIN_TRIP_DISTANCE_M = 50

MAX_LABEL_LENGTH = 200


@dataclass(frozen=True, slots=True)
class GeoPoint:
    lat: float
    lng: float


@dataclass(frozen=True, slots=True, kw_only=True)
class Place:
    """Where a trip started or ended: a point and the address the driver saw."""

    point: GeoPoint
    label: str | None = None


@dataclass(frozen=True, slots=True, kw_only=True)
class ServiceArea:
    """The rectangle the app works in (Almaty). Comes from config."""

    south: float
    north: float
    west: float
    east: float

    def contains(self, point: GeoPoint) -> bool:
        return self.south <= point.lat <= self.north and self.west <= point.lng <= self.east


def haversine_m(a: GeoPoint, b: GeoPoint) -> float:
    """Great-circle distance in metres."""
    lat1, lat2 = math.radians(a.lat), math.radians(b.lat)
    dlat = lat2 - lat1
    dlng = math.radians(b.lng - a.lng)
    h = math.sin(dlat / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlng / 2) ** 2
    return 2 * EARTH_RADIUS_M * math.asin(math.sqrt(h))


def validate_places(pickup: Place | None, dropoff: Place | None) -> None:
    """Rules that need no config: both or neither, real coordinates, short
    labels, start and end apart. The service area is checked by
    `ensure_in_area`, because its bounds are config."""
    if (pickup is None) != (dropoff is None):
        raise DomainValidationError(
            ErrorCode.INCOMPLETE_ROUTE,
            "set both pickup and dropoff, or neither",
            field="dropoff" if dropoff is None else "pickup",
        )
    if pickup is None or dropoff is None:
        return
    for name, place in (("pickup", pickup), ("dropoff", dropoff)):
        lat, lng = place.point.lat, place.point.lng
        if not (math.isfinite(lat) and math.isfinite(lng)) or abs(lat) > 90 or abs(lng) > 180:
            raise DomainValidationError(
                ErrorCode.OUTSIDE_SERVICE_AREA, "not a point on the map", field=name
            )
        if place.label is not None and len(place.label) > MAX_LABEL_LENGTH:
            raise DomainValidationError(
                ErrorCode.LABEL_TOO_LONG,
                f"label must be at most {MAX_LABEL_LENGTH} characters",
                field=f"{name}.label",
            )
    if haversine_m(pickup.point, dropoff.point) <= MIN_TRIP_DISTANCE_M:
        raise DomainValidationError(
            ErrorCode.SAME_PLACES,
            f"pickup and dropoff must be more than {MIN_TRIP_DISTANCE_M} m apart",
            field="dropoff",
        )


def ensure_in_area(area: ServiceArea, **places: Place | GeoPoint | None) -> None:
    """422 `outside_service_area` for the first place outside the area."""
    for name, place in places.items():
        if place is None:
            continue
        point = place.point if isinstance(place, Place) else place
        if not area.contains(point):
            raise DomainValidationError(
                ErrorCode.OUTSIDE_SERVICE_AREA,
                "the point is outside the service area (Almaty)",
                field=name,
            )
