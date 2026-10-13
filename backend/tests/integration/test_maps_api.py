"""Trips with places, routes and address lookups through the HTTP API, on a
real database; the map service is FakeMaps (no network)."""

from datetime import UTC, datetime, timedelta
from typing import Any

import pytest
from asgi_lifespan import LifespanManager
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.application.routing import retry_due_routes
from app.domain import polyline
from app.domain.geo import GeoPoint, haversine_m
from app.infrastructure.models import TripRow
from app.infrastructure.repository import SqlTripRepository
from app.infrastructure.settings import Settings
from app.main import Maps, create_app
from tests.conftest import STARTUP_TIMEOUT
from tests.factories import BAZAAR, ESENTAI
from tests.fakes import FakeMaps
from tests.integration.conftest import bearer, count_trips, trip_payload

PICKUP: dict[str, Any] = {
    "lat": BAZAAR.point.lat,
    "lng": BAZAAR.point.lng,
    "label": BAZAAR.label,
}
DROPOFF = {"lat": ESENTAI.point.lat, "lng": ESENTAI.point.lng, "label": ESENTAI.label}


def with_places(**overrides: Any) -> dict[str, Any]:
    return trip_payload(pickup=PICKUP, dropoff=DROPOFF, **overrides)


async def test_trip_with_places_gets_a_road_route(client: AsyncClient, fake_maps: FakeMaps) -> None:
    payload = with_places()

    response = await client.post("/trips", json=payload)

    assert response.status_code == 201
    body = response.json()
    assert body["pickup"] == PICKUP
    assert body["dropoff"] == DROPOFF
    route = body["route"]
    assert route["status"] == "ready"
    assert isinstance(route["distance_m"], int)
    assert isinstance(route["duration_s"], int)
    points = polyline.decode(route["polyline"])
    assert (points[0], points[-1]) == (BAZAAR.point, ESENTAI.point)
    assert fake_maps.calls == ["route"]

    one = await client.get(f"/trips/{payload['id']}")
    assert one.status_code == 200
    assert one.json() == body
    day = await client.get("/trips", params={"date": "2026-10-01"})
    assert day.json()["trips"] == [body]


async def test_same_request_again_is_200_and_routes_nothing(
    client: AsyncClient, fake_maps: FakeMaps
) -> None:
    payload = with_places()
    first = await client.post("/trips", json=payload)

    again = await client.post("/trips", json=payload)

    assert again.status_code == 200
    assert again.json() == first.json()
    assert fake_maps.calls == ["route"]


@pytest.mark.parametrize(
    "change",
    [
        {"dropoff": {**DROPOFF, "label": "Esentai Mall"}},
        {"dropoff": {**DROPOFF, "lat": 43.2186}},
        {"pickup": None, "dropoff": None},
    ],
)
async def test_same_id_with_other_places_is_409(
    client: AsyncClient, change: dict[str, Any]
) -> None:
    payload = with_places()
    await client.post("/trips", json=payload)

    response = await client.post("/trips", json={**payload, **change})

    assert response.status_code == 409
    assert response.json()["error"]["code"] == "trip_conflict"


async def test_map_service_down_still_creates_the_trip_with_a_straight_line(
    client: AsyncClient, fake_maps: FakeMaps
) -> None:
    fake_maps.fail = True
    payload = with_places()

    response = await client.post("/trips", json=payload)

    assert response.status_code == 201
    route = response.json()["route"]
    assert route["status"] == "straight"
    assert route["distance_m"] == round(haversine_m(BAZAAR.point, ESENTAI.point))
    assert route["duration_s"] is None
    assert polyline.decode(route["polyline"]) == [BAZAAR.point, ESENTAI.point]

    # Later the service is back: the owner asks for the route again.
    fake_maps.fail = False
    rebuilt = await client.post(f"/trips/{payload['id']}/route")
    assert rebuilt.status_code == 200
    assert rebuilt.json()["route"]["status"] == "ready"
    stored = await client.get(f"/trips/{payload['id']}")
    assert stored.json()["route"] == rebuilt.json()["route"]


@pytest.mark.parametrize(
    "case",
    [
        ({"dropoff": None}, "incomplete_route", "dropoff"),
        ({"pickup": None}, "incomplete_route", "pickup"),
        ({"pickup": {"lat": 51.1694, "lng": 71.4491}}, "outside_service_area", "pickup"),
        ({"dropoff": {"lat": 43.5, "lng": 76.9}}, "outside_service_area", "dropoff"),
        ({"dropoff": {**PICKUP, "lat": PICKUP["lat"] + 0.0002}}, "same_places", "dropoff"),
        ({"pickup": {**PICKUP, "label": "ж" * 201}}, "label_too_long", "pickup.label"),
        ({"pickup": {**PICKUP, "lat": "43.26"}}, "invalid_type", "pickup.lat"),
        ({"pickup": {**PICKUP, "lat": True}}, "invalid_type", "pickup.lat"),
        ({"pickup": [43.26, 76.95]}, "invalid_type", "pickup"),
        ({"pickup": {"lat": 43.26}}, "missing_field", "pickup.lng"),
        ({"pickup": {**PICKUP, "alt": 900}}, "unknown_field", "pickup.alt"),
        ({"route": {"status": "ready"}}, "unknown_field", "route"),
    ],
)
async def test_invalid_places_are_422_and_nothing_is_stored(
    client: AsyncClient,
    sessionmaker: async_sessionmaker[AsyncSession],
    fake_maps: FakeMaps,
    case: tuple[dict[str, Any], str, str],
) -> None:
    change, code, field = case
    payload = {**with_places(), **change}

    response = await client.post("/trips", json=payload)

    assert response.status_code == 422
    assert response.json()["error"]["code"] == code
    assert response.json()["error"]["field"] == field
    assert await count_trips(sessionmaker, payload["id"]) == 0
    assert fake_maps.calls == []


async def test_nan_coordinates_are_rejected(client: AsyncClient) -> None:
    # Python's JSON parser accepts the NaN literal; the schema must not.
    raw = (
        '{"id": "nan-1", "start": "2026-10-01T10:00:00+05:00", "end": "2026-10-01T10:25:00+05:00",'
        ' "amount": 2200, "payment": "card", "commission": 330,'
        ' "pickup": {"lat": NaN, "lng": 76.9}, "dropoff": {"lat": 43.2185, "lng": 76.928}}'
    )

    response = await client.post(
        "/trips", content=raw, headers={"Content-Type": "application/json"}
    )

    assert response.status_code == 422
    assert response.json()["error"]["field"] == "pickup.lat"


async def test_a_driver_cannot_read_or_reroute_another_drivers_trip(
    app: FastAPI, client: AsyncClient
) -> None:
    payload = with_places()
    await client.post("/trips", json=payload)
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test", headers=bearer("user_2")
    ) as other:
        assert (await other.get(f"/trips/{payload['id']}")).status_code == 404
        response = await other.post(f"/trips/{payload['id']}/route")
        assert response.status_code == 404
        assert response.json()["error"]["code"] == "not_found"


async def test_an_admin_reads_and_reroutes_any_trip(app: FastAPI, client: AsyncClient) -> None:
    payload = with_places()
    created = (await client.post("/trips", json=payload)).json()
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test", headers=bearer("admin")
    ) as admin:
        one = await admin.get(f"/trips/{payload['id']}", params={"tz": "Z"})
        rebuilt = await admin.post(f"/trips/{payload['id']}/route")

    assert one.status_code == 200
    assert one.json()["driver_id"] == created["driver_id"]
    assert one.json()["start"] == "2026-10-01T05:00:00Z"
    assert rebuilt.status_code == 200


async def test_unknown_trip_and_trip_without_places(client: AsyncClient) -> None:
    assert (await client.get("/trips/nope")).status_code == 404
    assert (await client.post("/trips/nope/route")).status_code == 404

    plain = trip_payload()
    await client.post("/trips", json=plain)
    one = await client.get(f"/trips/{plain['id']}")
    assert one.json()["route"]["status"] == "none"
    response = await client.post(f"/trips/{plain['id']}/route")
    assert response.status_code == 409
    assert response.json()["error"]["code"] == "no_places"


async def test_trip_by_id_needs_a_token(anonymous: AsyncClient) -> None:
    assert (await anonymous.get("/trips/t1")).status_code == 401
    reverse = await anonymous.get("/geo/reverse", params={"lat": 43.2, "lng": 76.9})
    assert reverse.status_code == 401


async def test_reverse_geocode_is_cached(client: AsyncClient, fake_maps: FakeMaps) -> None:
    fake_maps.labels[(43.238, 76.9455)] = "площадь Республики, 2"

    first = await client.get("/geo/reverse", params={"lat": 43.23801, "lng": 76.94549})
    second = await client.get("/geo/reverse", params={"lat": 43.23802, "lng": 76.9455})

    assert first.status_code == second.status_code == 200
    assert first.json() == second.json() == {"label": "площадь Республики, 2"}
    assert fake_maps.calls == ["reverse"]


async def test_reverse_outside_almaty_is_422(client: AsyncClient) -> None:
    response = await client.get("/geo/reverse", params={"lat": 51.17, "lng": 71.45})

    assert response.status_code == 422
    assert response.json()["error"]["code"] == "outside_service_area"


async def test_search_returns_places_in_almaty(client: AsyncClient, fake_maps: FakeMaps) -> None:
    from app.application.ports import GeoResult  # noqa: PLC0415

    fake_maps.places = [GeoResult("зелёный базар", GeoPoint(43.26275, 76.95519))]

    response = await client.get("/geo/search", params={"q": "Зелёный"})

    assert response.status_code == 200
    assert response.json() == {
        "results": [{"label": "зелёный базар", "lat": 43.26275, "lng": 76.95519}]
    }


@pytest.mark.parametrize("q", ["ab", "x" * 101])
async def test_search_text_length_is_checked(client: AsyncClient, q: str) -> None:
    response = await client.get("/geo/search", params={"q": q})

    assert response.status_code == 422
    assert response.json()["error"]["field"] == "q"


async def test_map_service_down_is_503_for_lookups(
    client: AsyncClient, fake_maps: FakeMaps
) -> None:
    fake_maps.fail = True

    reverse = await client.get("/geo/reverse", params={"lat": 43.2, "lng": 76.9})
    search = await client.get("/geo/search", params={"q": "базар"})

    for response in (reverse, search):
        assert response.status_code == 503
        assert response.json()["error"]["code"] == "maps_unavailable"
        # The reason (no key, quota, timeout) is not shown to clients.
        assert "fake" not in response.text


async def test_lookups_are_rate_limited_per_user(database_url: str, app: FastAPI) -> None:
    # `app` prepared the accounts and tokens; this app shares the database.
    del app
    limited = create_app(
        Settings(database_url=database_url, seed_on_startup=False, geo_requests_per_minute=2),
        maps=Maps(FakeMaps(), FakeMaps()),
    )
    async with (
        LifespanManager(limited, startup_timeout=STARTUP_TIMEOUT),
        AsyncClient(
            transport=ASGITransport(app=limited), base_url="http://test", headers=bearer("user_1")
        ) as user_1,
        AsyncClient(
            transport=ASGITransport(app=limited), base_url="http://test", headers=bearer("user_2")
        ) as user_2,
    ):
        params = {"lat": 43.2, "lng": 76.9}
        assert (await user_1.get("/geo/reverse", params=params)).status_code == 200
        assert (await user_1.get("/geo/search", params={"q": "базар"})).status_code == 200
        third = await user_1.get("/geo/reverse", params=params)
        assert (await user_2.get("/geo/reverse", params=params)).status_code == 200

    assert third.status_code == 429
    assert third.json()["error"]["code"] == "rate_limited"
    assert 1 <= int(third.headers["Retry-After"]) <= 60


async def test_a_straight_line_is_retried_in_the_background_once_due(
    client: AsyncClient,
    fake_maps: FakeMaps,
    sessionmaker: async_sessionmaker[AsyncSession],
) -> None:
    fake_maps.fail = True
    payload = with_places()
    before = datetime.now(UTC)
    created = await client.post("/trips", json=payload)
    assert created.json()["route"]["status"] == "straight"

    async with sessionmaker() as session:
        row = await session.get(TripRow, payload["id"])
        assert row is not None
        assert row.route_attempts == 0
        assert row.route_retry_at is not None
        assert before + timedelta(minutes=1) <= row.route_retry_at
        assert row.route_retry_at <= datetime.now(UTC) + timedelta(minutes=1)
        due_at = row.route_retry_at

    fake_maps.fail = False
    async with sessionmaker() as session:
        early = await retry_due_routes(
            SqlTripRepository(session), fake_maps, lambda: due_at - timedelta(seconds=1), 4
        )
    async with sessionmaker() as session:
        on_time = await retry_due_routes(SqlTripRepository(session), fake_maps, lambda: due_at, 4)

    assert (early.built, on_time.built) == (0, 1)
    one = await client.get(f"/trips/{payload['id']}")
    assert one.json()["route"]["status"] == "ready"
    async with sessionmaker() as session:
        row = await session.get(TripRow, payload["id"])
        assert row is not None
        assert (row.route_attempts, row.route_retry_at) == (1, None)
