"""OpenRouteService: driving directions and geocoding (Pelias), docs/MAPS.md.

The key travels only from here to ORS: never to the app, never into logs."""

import logging
import math
import re
from typing import Any

import httpx

from app.application.errors import MapsUnavailableError
from app.application.ports import GeoResult
from app.domain.geo import GeoPoint, ServiceArea
from app.domain.route import RouteStatus, TripRoute

logger = logging.getLogger(__name__)

# How far ORS may move a point to reach a road (m). Its default (350) fails
# for points inside large areas such as the airport or a market.
SNAP_RADIUS_M = 1000

# Reverse geocoding: only these layers (localities would give «Алматы»).
REVERSE_LAYERS = "address,venue,street"
# An address farther than this from the point is not "the point's address".
ADDRESS_MAX_DISTANCE_KM = 0.075

_CYRILLIC = re.compile(r"[\u0400-\u04FF]")


class OrsClient:
    """Router and Geocoder over the ORS HTTP API. Every failure (timeout,
    network, 4xx/5xx including the 403 / 429 quota answers, an unreadable
    body) is MapsUnavailableError."""

    def __init__(self, http: httpx.AsyncClient, api_key: str) -> None:
        self._http = http
        self._api_key = api_key

    async def _call(self, method: str, path: str, **kwargs: Any) -> Any:
        try:
            response = await self._http.request(
                method, path, headers={"Authorization": self._api_key}, **kwargs
            )
        except httpx.HTTPError as exc:
            raise MapsUnavailableError(f"ORS {path}: {type(exc).__name__}") from exc
        if response.status_code != httpx.codes.OK:
            # 403 = daily quota used up, 429 = per-minute limit (ORS FAQ).
            raise MapsUnavailableError(f"ORS {path}: HTTP {response.status_code}")
        try:
            return response.json()
        except ValueError as exc:
            raise MapsUnavailableError(f"ORS {path}: not JSON") from exc

    async def route(self, a: GeoPoint, b: GeoPoint) -> TripRoute:
        body = {
            "coordinates": [[a.lng, a.lat], [b.lng, b.lat]],
            "radiuses": [SNAP_RADIUS_M, SNAP_RADIUS_M],
        }
        data = await self._call("POST", "/v2/directions/driving-car", json=body)
        try:
            route = data["routes"][0]
            geometry = route["geometry"]
            distance = float(route["summary"].get("distance", 0))
            duration = float(route["summary"].get("duration", 0))
        except (KeyError, IndexError, TypeError, ValueError) as exc:
            raise MapsUnavailableError("ORS directions: unexpected response") from exc
        if not isinstance(geometry, str) or not geometry or not math.isfinite(distance + duration):
            raise MapsUnavailableError("ORS directions: unexpected response")
        return TripRoute(
            status=RouteStatus.READY,
            polyline=geometry,
            distance_m=round(distance),
            duration_s=round(duration),
        )

    async def reverse(self, point: GeoPoint) -> str | None:
        data = await self._call(
            "GET",
            "/geocode/reverse",
            params={
                "point.lat": point.lat,
                "point.lon": point.lng,
                "layers": REVERSE_LAYERS,
                "size": 5,
                "lang": "ru",
            },
        )
        return reverse_label(_features(data))

    async def search(self, text: str, area: ServiceArea, limit: int) -> list[GeoResult]:
        data = await self._call(
            "GET",
            "/geocode/autocomplete",
            params={
                "text": text,
                **_search_lang(text),
                "size": limit,
                "boundary.country": "KZ",
                "boundary.rect.min_lat": area.south,
                "boundary.rect.max_lat": area.north,
                "boundary.rect.min_lon": area.west,
                "boundary.rect.max_lon": area.east,
            },
        )
        results = []
        for feature in _features(data):
            label = place_label(feature["properties"])
            lng, lat = feature["geometry"]["coordinates"][:2]
            if label:
                results.append(GeoResult(label=label, point=GeoPoint(float(lat), float(lng))))
        return results


def _search_lang(text: str) -> dict[str, str]:
    """Russian names for a Cyrillic query («Достык», not «Достық»). A Latin
    query with lang=ru gets English names («Abay Avenue»), without it the
    default (mostly Russian) ones, so then no lang (docs/MAPS.md, stage 1).
    Where OSM has no Russian name, ORS falls back to the default name itself."""
    return {"lang": "ru"} if _CYRILLIC.search(text) else {}


def _features(data: Any) -> list[dict[str, Any]]:
    try:
        features = data["features"]
        return [
            f
            for f in features
            if isinstance(f.get("properties"), dict) and len(f["geometry"]["coordinates"]) >= 2
        ]
    except (KeyError, TypeError) as exc:
        raise MapsUnavailableError("ORS geocode: unexpected response") from exc


def place_label(props: dict[str, Any]) -> str | None:
    """A short label: a place's name, or «street, house», or the street —
    never ORS's own label, which ends in region and country."""
    layer = props.get("layer")
    name = (props.get("name") or "").strip() or None
    street = (props.get("street") or "").strip() or None
    house = (props.get("housenumber") or "").strip() or None
    if layer == "address" and street:
        return f"{street}, {house}" if house else street
    if layer == "street":
        return street or name
    return name


def reverse_label(features: list[dict[str, Any]]) -> str | None:
    """The address of a point: the nearest house address within 75 m (more
    stable than the shops inside a mall), else the nearest named place, else
    the street. ORS sorts by distance."""
    by_layer: dict[str, dict[str, Any]] = {}
    for feature in features:
        by_layer.setdefault(feature["properties"].get("layer", ""), feature["properties"])
    address = by_layer.get("address")
    if address is not None and (address.get("distance") or 0) <= ADDRESS_MAX_DISTANCE_KM:
        return place_label(address)
    for layer in ("venue", "street", "address"):
        if layer in by_layer and (label := place_label(by_layer[layer])):
            return label
    return None


_NO_KEY = "ORS_API_KEY is not set"


class MapsNotConfigured:
    """Router and Geocoder when ORS_API_KEY is not set (tests, local runs
    without a key): routes fall back to a straight line, lookups are 503."""

    async def route(self, a: GeoPoint, b: GeoPoint) -> TripRoute:
        del a, b
        raise MapsUnavailableError(_NO_KEY)

    async def reverse(self, point: GeoPoint) -> str | None:
        del point
        raise MapsUnavailableError(_NO_KEY)

    async def search(self, text: str, area: ServiceArea, limit: int) -> list[GeoResult]:
        del text, area, limit
        raise MapsUnavailableError(_NO_KEY)
