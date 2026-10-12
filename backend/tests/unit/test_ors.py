"""OrsClient against a fake ORS (httpx.MockTransport): no network."""

import json
from collections.abc import Callable
from typing import Any

import httpx
import pytest

from app.application.errors import MapsUnavailableError
from app.domain.geo import GeoPoint
from app.domain.route import RouteStatus
from app.infrastructure.ors import MapsNotConfigured, OrsClient, place_label, reverse_label
from app.infrastructure.settings import Settings
from tests.factories import ALMATY, BAZAAR, ESENTAI

KEY = "test-key"


def client(handler: Callable[[httpx.Request], httpx.Response]) -> OrsClient:
    http = httpx.AsyncClient(
        base_url="https://ors.test", transport=httpx.MockTransport(handler), timeout=5
    )
    return OrsClient(http, KEY)


def feature(layer: str, lat: float, lng: float, **props: Any) -> dict[str, Any]:
    return {
        "geometry": {"type": "Point", "coordinates": [lng, lat]},
        "properties": {"layer": layer, **props},
    }


DIRECTIONS = {
    "routes": [
        {
            "summary": {"distance": 7429.4, "duration": 783.3},
            "geometry": "{v`gG_iutMJzCJjEFbCTbI",
        }
    ]
}


async def test_route_sends_lng_lat_and_returns_integers() -> None:
    seen: list[httpx.Request] = []

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        return httpx.Response(200, json=DIRECTIONS)

    route = await client(handler).route(BAZAAR.point, ESENTAI.point)

    assert route.status is RouteStatus.READY
    assert (route.distance_m, route.duration_s) == (7429, 783)
    assert route.polyline == "{v`gG_iutMJzCJjEFbCTbI"
    request = seen[0]
    assert request.url.path == "/v2/directions/driving-car"
    assert request.headers["Authorization"] == KEY
    body = json.loads(request.content)
    assert body["coordinates"] == [[76.95519, 43.26275], [76.928, 43.2185]]
    assert body["radiuses"] == [1000, 1000]


@pytest.mark.parametrize("status", [400, 403, 404, 429, 500, 502])
async def test_any_error_status_means_unavailable(status: int) -> None:
    ors = client(lambda _: httpx.Response(status, json={"error": "quota"}))

    with pytest.raises(MapsUnavailableError, match=f"HTTP {status}"):
        await ors.route(BAZAAR.point, ESENTAI.point)
    with pytest.raises(MapsUnavailableError):
        await ors.reverse(BAZAAR.point)


async def test_timeout_and_network_errors_mean_unavailable() -> None:
    def timeout(request: httpx.Request) -> httpx.Response:
        raise httpx.ReadTimeout("slow", request=request)

    def refused(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectError("refused", request=request)

    with pytest.raises(MapsUnavailableError, match="ReadTimeout"):
        await client(timeout).route(BAZAAR.point, ESENTAI.point)
    with pytest.raises(MapsUnavailableError, match="ConnectError"):
        await client(refused).search("базар", ALMATY, 5)


@pytest.mark.parametrize(
    "body",
    [
        b"not json",
        b"{}",
        b'{"routes": []}',
        b'{"routes": [{"summary": {}, "geometry": ""}]}',
        b'{"routes": [{"summary": {"distance": "x"}, "geometry": "abc"}]}',
        b'{"routes": [{"summary": {"distance": 1e999}, "geometry": "abc"}]}',
    ],
)
async def test_unexpected_directions_answer_means_unavailable(body: bytes) -> None:
    ors = client(lambda _: httpx.Response(200, content=body))

    with pytest.raises(MapsUnavailableError):
        await ors.route(BAZAAR.point, ESENTAI.point)


async def test_reverse_prefers_a_near_house_address() -> None:
    seen: list[httpx.Request] = []
    answer = {
        "features": [
            feature("venue", 43.2378, 76.9455, name="Торговый центр «Алмалы»", distance=0.02),
            feature(
                "address",
                43.2378,
                76.9455,
                name="2 площадь Республики",
                street="площадь Республики",
                housenumber="2",
                distance=0.02,
            ),
        ]
    }

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        return httpx.Response(200, json=answer)

    label = await client(handler).reverse(GeoPoint(43.238, 76.9455))

    assert label == "площадь Республики, 2"
    params = seen[0].url.params
    assert (params["point.lat"], params["point.lon"]) == ("43.238", "76.9455")
    assert params["lang"] == "ru"
    assert params["layers"] == "address,venue,street"


def test_reverse_label_falls_back_to_a_place_then_the_street() -> None:
    far_address = feature(
        "address", 43.2, 76.9, street="улица Кичикова", housenumber="5", distance=0.3
    )
    airport = feature("venue", 43.35, 77.04, name="Almaty International Airport", distance=0.003)
    street = feature("street", 43.34, 77.04, name="улица Кичикова", street="улица Кичикова")

    assert reverse_label([airport, far_address, street]) == "Almaty International Airport"
    assert reverse_label([far_address, street]) == "улица Кичикова"
    assert reverse_label([far_address]) == "улица Кичикова, 5"
    assert reverse_label([]) is None


@pytest.mark.parametrize(
    ("props", "label"),
    [
        ({"layer": "venue", "name": "Зелёный базар", "street": "Жибек Жолы"}, "Зелёный базар"),
        (
            {"layer": "address", "street": "улица Розыбакиева", "housenumber": "112"},
            "улица Розыбакиева, 112",
        ),
        ({"layer": "address", "street": "улица Розыбакиева"}, "улица Розыбакиева"),
        ({"layer": "street", "name": "проспект Абая", "street": None}, "проспект Абая"),
        ({"layer": "venue", "name": "  "}, None),
    ],
)
def test_place_label_has_no_city_or_country(props: dict[str, Any], label: str | None) -> None:
    assert place_label({**props, "label": "…, AC, Казахстан"}) == label


async def test_search_is_limited_to_the_area_in_russian() -> None:
    seen: list[httpx.Request] = []
    answer = {
        "features": [
            feature("venue", 43.26275, 76.95519, name="Зелёный базар"),
            feature("venue", 43.2, 76.9, name=""),  # no label: skipped
            {"properties": {"layer": "venue"}, "geometry": {"coordinates": [1]}},  # broken
        ]
    }

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        return httpx.Response(200, json=answer)

    results = await client(handler).search("зелёный базар", ALMATY, 5)

    assert [(r.label, r.point) for r in results] == [("Зелёный базар", BAZAAR.point)]
    params = seen[0].url.params
    assert seen[0].url.path == "/geocode/autocomplete"
    assert (params["text"], params["lang"], params["size"]) == ("зелёный базар", "ru", "5")
    assert params["boundary.rect.min_lat"] == "43.05"
    assert params["boundary.rect.max_lon"] == "77.2"


async def test_geocode_answer_without_features_means_unavailable() -> None:
    ors = client(lambda _: httpx.Response(200, json={"type": "FeatureCollection"}))

    with pytest.raises(MapsUnavailableError):
        await ors.search("базар", ALMATY, 5)


async def test_without_a_key_routes_and_lookups_are_unavailable() -> None:
    maps = MapsNotConfigured()

    with pytest.raises(MapsUnavailableError, match="ORS_API_KEY"):
        await maps.route(BAZAAR.point, ESENTAI.point)
    with pytest.raises(MapsUnavailableError):
        await maps.reverse(BAZAAR.point)
    with pytest.raises(MapsUnavailableError):
        await maps.search("базар", ALMATY, 5)


def test_blank_key_counts_as_no_key() -> None:
    assert Settings(ors_api_key="  ").ors_key is None  # type: ignore[arg-type]
    assert Settings(ors_api_key="k").ors_key == "k"  # type: ignore[arg-type]
    assert Settings().service_area == ALMATY
    secret = "secret-ors-key-123"
    assert secret not in repr(Settings(ors_api_key=secret))  # type: ignore[arg-type]


@pytest.mark.parametrize(
    ("text", "lang"),
    [("зелёный базар", "ru"), ("достык 5", "ru"), ("Esentai Mall", None), ("Abay", None)],
)
async def test_search_asks_for_russian_only_for_cyrillic_text(text: str, lang: str | None) -> None:
    seen: list[httpx.Request] = []

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        return httpx.Response(200, json={"features": []})

    await client(handler).search(text, ALMATY, 5)

    assert seen[0].url.params.get("lang") == lang
