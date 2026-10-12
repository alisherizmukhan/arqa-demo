import math

import pytest
from hypothesis import given
from hypothesis import strategies as st

from app.domain import polyline
from app.domain.errors import DomainValidationError, ErrorCode
from app.domain.geo import (
    GeoPoint,
    Place,
    ensure_in_area,
    haversine_m,
    validate_places,
)
from app.domain.route import RouteStatus, TripRoute
from tests.factories import ALMATY, BAZAAR, ESENTAI, make_trip

# Google's reference example (developers.google.com/maps/documentation/utilities/polylinealgorithm).
GOOGLE_EXAMPLE = "_p~iF~ps|U_ulLnnqC_mqNvxq`@"
GOOGLE_POINTS = [GeoPoint(38.5, -120.2), GeoPoint(40.7, -120.95), GeoPoint(43.252, -126.453)]


def test_polyline_matches_googles_reference_example() -> None:
    assert polyline.encode(GOOGLE_POINTS) == GOOGLE_EXAMPLE
    assert polyline.decode(GOOGLE_EXAMPLE) == GOOGLE_POINTS


def test_polyline_of_nothing_is_empty() -> None:
    assert polyline.encode([]) == ""
    assert polyline.decode("") == []


@given(
    st.lists(
        st.tuples(
            st.floats(min_value=-90, max_value=90, allow_nan=False),
            st.floats(min_value=-180, max_value=180, allow_nan=False),
        ),
        max_size=20,
    )
)
def test_polyline_round_trip_keeps_five_decimals(coords: list[tuple[float, float]]) -> None:
    decoded = polyline.decode(polyline.encode([GeoPoint(lat, lng) for lat, lng in coords]))

    assert len(decoded) == len(coords)
    for point, (lat, lng) in zip(decoded, coords, strict=True):
        assert point.lat == pytest.approx(lat, abs=0.6e-5)
        assert point.lng == pytest.approx(lng, abs=0.6e-5)


@pytest.mark.parametrize("bad", ["_p~iF~ps|U_", "_p~iF", "abc def", "\x7f\x7f"])
def test_polyline_decode_rejects_garbage(bad: str) -> None:
    with pytest.raises(ValueError, match="polyline"):
        polyline.decode(bad)


def test_haversine_between_two_almaty_places() -> None:
    # Зелёный базар -> Есентай Молл: 4 920 m north-south, 2 203 m east-west.
    assert haversine_m(BAZAAR.point, ESENTAI.point) == pytest.approx(5_391, abs=5)
    assert haversine_m(BAZAAR.point, BAZAAR.point) == 0


def test_one_degree_of_latitude_is_about_111_km() -> None:
    assert haversine_m(GeoPoint(43, 77), GeoPoint(44, 77)) == pytest.approx(111_195, rel=1e-3)


def test_straight_route_is_two_points_with_rounded_length() -> None:
    route = TripRoute.straight(BAZAAR.point, ESENTAI.point)

    assert route.status is RouteStatus.STRAIGHT
    assert route.polyline is not None
    assert polyline.decode(route.polyline) == [BAZAAR.point, ESENTAI.point]
    assert route.distance_m == round(haversine_m(BAZAAR.point, ESENTAI.point))
    assert route.duration_s is None


def test_places_are_optional() -> None:
    validate_places(None, None)
    assert not make_trip().has_places
    assert make_trip(pickup=BAZAAR, dropoff=ESENTAI).has_places


@pytest.mark.parametrize(
    ("pickup", "dropoff", "field"),
    [(BAZAAR, None, "dropoff"), (None, ESENTAI, "pickup")],
)
def test_both_places_or_neither(pickup: Place | None, dropoff: Place | None, field: str) -> None:
    with pytest.raises(DomainValidationError) as error:
        make_trip(pickup=pickup, dropoff=dropoff)

    assert error.value.code is ErrorCode.INCOMPLETE_ROUTE
    assert error.value.field == field


def test_start_and_end_must_be_more_than_50_m_apart() -> None:
    # 0.0004° of latitude is ~44 m.
    near = Place(point=GeoPoint(BAZAAR.point.lat + 0.0004, BAZAAR.point.lng))
    with pytest.raises(DomainValidationError) as error:
        make_trip(pickup=BAZAAR, dropoff=near)
    assert error.value.code is ErrorCode.SAME_PLACES

    # ~56 m is fine.
    make_trip(pickup=BAZAAR, dropoff=Place(point=GeoPoint(BAZAAR.point.lat + 0.0005, 76.95519)))


def test_label_is_at_most_200_characters() -> None:
    make_trip(pickup=Place(point=BAZAAR.point, label="ж" * 200), dropoff=ESENTAI)

    with pytest.raises(DomainValidationError) as error:
        make_trip(pickup=BAZAAR, dropoff=Place(point=ESENTAI.point, label="ж" * 201))

    assert error.value.code is ErrorCode.LABEL_TOO_LONG
    assert error.value.field == "dropoff.label"


@pytest.mark.parametrize(
    "point", [GeoPoint(math.nan, 76.9), GeoPoint(43.2, math.inf), GeoPoint(91, 76.9)]
)
def test_coordinates_must_be_a_real_point(point: GeoPoint) -> None:
    with pytest.raises(DomainValidationError) as error:
        make_trip(pickup=Place(point=point), dropoff=ESENTAI)

    assert error.value.code is ErrorCode.OUTSIDE_SERVICE_AREA
    assert error.value.field == "pickup"


def test_service_area_bounds_are_inclusive() -> None:
    assert ALMATY.contains(GeoPoint(43.05, 76.70))
    assert ALMATY.contains(GeoPoint(43.45, 77.20))
    assert not ALMATY.contains(GeoPoint(43.0499, 76.9))
    assert not ALMATY.contains(GeoPoint(43.2, 77.2001))


def test_ensure_in_area_names_the_first_place_outside() -> None:
    astana = Place(point=GeoPoint(51.1694, 71.4491))
    ensure_in_area(ALMATY, pickup=BAZAAR, dropoff=None)

    with pytest.raises(DomainValidationError) as error:
        ensure_in_area(ALMATY, pickup=BAZAAR, dropoff=astana)
    assert (error.value.code, error.value.field) == (ErrorCode.OUTSIDE_SERVICE_AREA, "dropoff")

    with pytest.raises(DomainValidationError):
        ensure_in_area(ALMATY, point=astana.point)


def test_places_are_part_of_the_payload() -> None:
    trip = make_trip(pickup=BAZAAR, dropoff=ESENTAI)

    assert trip.has_same_payload(make_trip(pickup=BAZAAR, dropoff=ESENTAI))
    assert not trip.has_same_payload(make_trip())
    relabelled = Place(point=ESENTAI.point, label="Esentai Mall")
    assert not trip.has_same_payload(make_trip(pickup=BAZAAR, dropoff=relabelled))
    moved = Place(point=GeoPoint(43.2186, 76.928), label=ESENTAI.label)
    assert not trip.has_same_payload(make_trip(pickup=BAZAAR, dropoff=moved))
