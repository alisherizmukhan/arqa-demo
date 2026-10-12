"""Address lookups for the place picker (OpenRouteService behind the backend)."""

from typing import Annotated, Any

from fastapi import APIRouter, Query, status

from app.api.deps import CurrentUserDep, GeoDep
from app.api.routes import AUTH_ERRORS
from app.api.schemas import ErrorResponse, GeoLabelOut, GeoResultOut, GeoSearchOut, error_example
from app.application.geocoding import SEARCH_MAX_LENGTH, SEARCH_MIN_LENGTH
from app.domain.geo import GeoPoint

router = APIRouter(prefix="/geo", tags=["geo"])

_ERRORS: dict[int | str, dict[str, Any]] = {
    **AUTH_ERRORS,
    **error_example(
        status.HTTP_429_TOO_MANY_REQUESTS,
        "Too many map requests from this user (Retry-After says when to retry)",
        "rate_limited",
        "too many map requests, try again later",
    ),
    **error_example(
        status.HTTP_503_SERVICE_UNAVAILABLE,
        "The map service failed, timed out or is over its quota",
        "maps_unavailable",
        "the map service is unavailable, try again later",
    ),
    status.HTTP_422_UNPROCESSABLE_CONTENT: {
        "model": ErrorResponse,
        "description": "Validation error (e.g. outside_service_area)",
    },
}

Latitude = Annotated[float, Query(allow_inf_nan=False, examples=[43.238])]
Longitude = Annotated[float, Query(allow_inf_nan=False, examples=[76.9455])]


@router.get("/reverse", responses=_ERRORS)
async def reverse(lat: Latitude, lng: Longitude, actor: CurrentUserDep, geo: GeoDep) -> GeoLabelOut:
    """The address of a point in Almaty, in Russian: street and house, or a
    place name, without city or country (`label` null when nothing is near).
    Cached for 24 h by the point rounded to ~11 m."""
    return GeoLabelOut(label=await geo.reverse(actor.id, GeoPoint(lat, lng)))


@router.get("/search", responses=_ERRORS)
async def search(
    actor: CurrentUserDep,
    geo: GeoDep,
    q: Annotated[
        str,
        Query(
            min_length=SEARCH_MIN_LENGTH,
            max_length=SEARCH_MAX_LENGTH,
            description="What the driver typed (at least 3 characters)",
            examples=["Зелёный базар"],
        ),
    ],
) -> GeoSearchOut:
    """Autocomplete: up to 5 places in Almaty matching `q`, best first.
    Cached for 24 h by the normalised text."""
    results = await geo.search(actor.id, q)
    return GeoSearchOut(results=[GeoResultOut.from_domain(r) for r in results])
