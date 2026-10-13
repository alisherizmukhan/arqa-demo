from uuid import uuid4

import pytest

from app.application.errors import NotFoundError, TripConflictError, TripHasNoPlacesError
from app.application.routing import get_trip, rebuild_route
from app.application.use_cases import create_trip, seed_trip_places
from app.domain import polyline
from app.domain.errors import DomainValidationError, ErrorCode
from app.domain.geo import GeoPoint, Place, haversine_m
from app.domain.route import RouteStatus
from app.domain.user import Role, User
from tests.factories import ALMATY, BAZAAR, ESENTAI, NOW, make_trip
from tests.fakes import DRIVER_1, DRIVER_2, FakeMaps, InMemoryTripRepository

ME = User(id=DRIVER_1, login="user_1", role=Role.DRIVER, display_name="Водитель 1")
OTHER = User(id=DRIVER_2, login="user_2", role=Role.DRIVER, display_name="Водитель 2")
ADMIN = User(id=uuid4(), login="admin", role=Role.ADMIN, display_name="Администратор")


async def test_new_trip_with_places_gets_its_route_once() -> None:
    repo, maps = InMemoryTripRepository(), FakeMaps()
    trip = make_trip(id="a", pickup=BAZAAR, dropoff=ESENTAI)

    result = await create_trip(repo, trip, DRIVER_1, router=maps, area=ALMATY, now=NOW)

    assert result.created
    assert result.route.status is RouteStatus.READY
    assert isinstance(result.route.distance_m, int)
    assert isinstance(result.route.duration_s, int)
    stored = await repo.get("a")
    assert stored is not None
    assert stored.route == result.route
    assert maps.calls == ["route"]


async def test_retry_returns_the_stored_route_without_routing_again() -> None:
    repo, maps = InMemoryTripRepository(), FakeMaps()
    trip = make_trip(id="a", pickup=BAZAAR, dropoff=ESENTAI)
    first = await create_trip(repo, trip, DRIVER_1, router=maps, area=ALMATY, now=NOW)

    again = await create_trip(repo, trip, DRIVER_1, router=maps, area=ALMATY, now=NOW)

    assert not again.created
    assert again.route == first.route
    assert maps.calls == ["route"]


async def test_same_id_with_other_places_is_a_conflict() -> None:
    repo, maps = InMemoryTripRepository(), FakeMaps()
    await create_trip(
        repo,
        make_trip(id="a", pickup=BAZAAR, dropoff=ESENTAI),
        DRIVER_1,
        router=maps,
        area=ALMATY,
        now=NOW,
    )
    elsewhere = Place(point=GeoPoint(43.238, 76.9455), label="Площадь Республики")

    with pytest.raises(TripConflictError):
        await create_trip(
            repo,
            make_trip(id="a", pickup=BAZAAR, dropoff=elsewhere),
            DRIVER_1,
            router=maps,
            area=ALMATY,
            now=NOW,
        )


async def test_map_service_down_gives_a_straight_line_not_an_error() -> None:
    repo, maps = InMemoryTripRepository(), FakeMaps(fail=True)

    result = await create_trip(
        repo,
        make_trip(id="a", pickup=BAZAAR, dropoff=ESENTAI),
        DRIVER_1,
        router=maps,
        area=ALMATY,
        now=NOW,
    )

    assert result.created
    assert result.route.status is RouteStatus.STRAIGHT
    assert result.route.distance_m == round(haversine_m(BAZAAR.point, ESENTAI.point))
    assert result.route.duration_s is None
    assert result.route.polyline is not None
    assert polyline.decode(result.route.polyline) == [BAZAAR.point, ESENTAI.point]


async def test_trip_without_places_never_calls_the_router() -> None:
    repo, maps = InMemoryTripRepository(), FakeMaps()

    result = await create_trip(repo, make_trip(id="a"), DRIVER_1, router=maps, area=ALMATY, now=NOW)

    assert result.route.status is RouteStatus.NONE
    assert maps.calls == []


async def test_places_outside_the_area_are_rejected_before_anything_is_stored() -> None:
    repo, maps = InMemoryTripRepository(), FakeMaps()
    astana = Place(point=GeoPoint(51.1694, 71.4491), label="Астана")

    with pytest.raises(DomainValidationError) as error:
        await create_trip(
            repo,
            make_trip(id="a", pickup=astana, dropoff=ESENTAI),
            DRIVER_1,
            router=maps,
            area=ALMATY,
            now=NOW,
        )

    assert (error.value.code, error.value.field) == (ErrorCode.OUTSIDE_SERVICE_AREA, "pickup")
    assert await repo.count() == 0
    assert maps.calls == []


async def test_rebuild_turns_a_straight_line_into_a_road_route() -> None:
    repo, maps = InMemoryTripRepository(), FakeMaps(fail=True)
    trip = make_trip(id="a", pickup=BAZAAR, dropoff=ESENTAI)
    await create_trip(repo, trip, DRIVER_1, router=maps, area=ALMATY, now=NOW)
    maps.fail = False

    rebuilt = await rebuild_route(repo, maps, ME, "a", NOW)

    assert rebuilt.route.status is RouteStatus.READY
    stored = await repo.get("a")
    assert stored is not None
    assert stored.route.status is RouteStatus.READY


async def test_rebuild_while_still_down_stays_straight() -> None:
    repo, maps = InMemoryTripRepository(), FakeMaps(fail=True)
    await create_trip(
        repo,
        make_trip(id="a", pickup=BAZAAR, dropoff=ESENTAI),
        DRIVER_1,
        router=maps,
        area=ALMATY,
        now=NOW,
    )

    rebuilt = await rebuild_route(repo, maps, ME, "a", NOW)

    assert rebuilt.route.status is RouteStatus.STRAIGHT


async def test_rebuild_needs_places() -> None:
    repo = InMemoryTripRepository([make_trip(id="plain")])

    with pytest.raises(TripHasNoPlacesError):
        await rebuild_route(repo, FakeMaps(), ME, "plain", NOW)


async def test_a_driver_reads_only_their_own_trip_an_admin_any() -> None:
    repo = InMemoryTripRepository([make_trip(id="mine", pickup=BAZAAR, dropoff=ESENTAI)])

    assert (await get_trip(repo, ME, "mine")).trip.id == "mine"
    assert (await get_trip(repo, ADMIN, "mine")).driver_id == DRIVER_1
    with pytest.raises(NotFoundError):
        await get_trip(repo, OTHER, "mine")
    with pytest.raises(NotFoundError):
        await rebuild_route(repo, FakeMaps(), OTHER, "mine", NOW)
    with pytest.raises(NotFoundError):
        await get_trip(repo, ADMIN, "missing")


async def test_seed_places_go_only_to_trips_without_places() -> None:
    repo = InMemoryTripRepository([make_trip(id="t1"), make_trip(id="t2")])
    theirs = repo.for_driver(DRIVER_2)
    await theirs.insert_if_absent(make_trip(id="u2"))
    mine = Place(point=GeoPoint(43.238, 76.9455), label="мой адрес")
    await repo.set_places_if_missing("t2", mine, ESENTAI)
    seeds = [
        make_trip(id=trip_id, pickup=BAZAAR, dropoff=ESENTAI)
        for trip_id in ("t1", "t2", "u2", "missing")
    ]

    assert await seed_trip_places(repo, seeds) == 1
    assert await seed_trip_places(repo, seeds) == 0

    t1, t2, u2 = await repo.get("t1"), await repo.get("t2"), await repo.get("u2")
    assert t1 is not None
    assert (t1.trip.pickup, t1.route.status) == (BAZAAR, RouteStatus.PENDING)
    assert t2 is not None
    assert t2.trip.pickup == mine
    assert u2 is not None
    assert u2.trip.pickup is None
