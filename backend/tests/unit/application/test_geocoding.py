from datetime import UTC, datetime, timedelta

import pytest

from app.application.errors import GeoRateLimitedError, MapsUnavailableError
from app.application.geocoding import GeoService, RateLimiter, TtlCache
from app.application.ports import GeoResult
from app.domain.errors import DomainValidationError, ErrorCode
from app.domain.geo import GeoPoint
from tests.factories import ALMATY
from tests.fakes import DRIVER_1, DRIVER_2, FakeMaps


class Clock:
    def __init__(self) -> None:
        self.now = datetime(2026, 10, 12, 12, 0, tzinfo=UTC)

    def __call__(self) -> datetime:
        return self.now


def make_service(maps: FakeMaps, clock: Clock, limit: int = 100) -> GeoService:
    day = timedelta(hours=24)
    return GeoService(
        geocoder=maps,
        area=ALMATY,
        limiter=RateLimiter(limit, timedelta(minutes=1), clock),
        reverse_cache=TtlCache(day, 3, clock),
        search_cache=TtlCache(day, 3, clock),
    )


async def test_reverse_is_cached_for_24_hours_by_the_rounded_point() -> None:
    maps, clock = FakeMaps(), Clock()
    geo = make_service(maps, clock)

    first = await geo.reverse(DRIVER_1, GeoPoint(43.23801, 76.94552))
    # ~5 m away: the same rounded point, the same answer, no new lookup.
    second = await geo.reverse(DRIVER_2, GeoPoint(43.23804, 76.94549))
    assert first == second == "проспект Абая, 10"
    assert maps.calls == ["reverse"]

    clock.now += timedelta(hours=24)
    await geo.reverse(DRIVER_1, GeoPoint(43.23801, 76.94552))
    assert maps.calls == ["reverse", "reverse"]


async def test_reverse_asks_for_the_rounded_point() -> None:
    maps, clock = FakeMaps(), Clock()
    maps.labels[(43.238, 76.9455)] = "площадь Республики, 2"

    label = await make_service(maps, clock).reverse(DRIVER_1, GeoPoint(43.23801, 76.94548))

    assert label == "площадь Республики, 2"


async def test_nothing_found_is_cached_too() -> None:
    maps, clock = FakeMaps(), Clock()
    maps.labels[(43.1, 76.8)] = None
    geo = make_service(maps, clock)

    assert await geo.reverse(DRIVER_1, GeoPoint(43.1, 76.8)) is None
    assert await geo.reverse(DRIVER_1, GeoPoint(43.1, 76.8)) is None
    assert maps.calls == ["reverse"]


async def test_failures_are_not_cached() -> None:
    maps, clock = FakeMaps(fail=True), Clock()
    geo = make_service(maps, clock)

    with pytest.raises(MapsUnavailableError):
        await geo.reverse(DRIVER_1, GeoPoint(43.2, 76.9))
    maps.fail = False
    assert await geo.reverse(DRIVER_1, GeoPoint(43.2, 76.9)) == "проспект Абая, 10"


async def test_reverse_outside_almaty_is_422_without_a_lookup() -> None:
    maps = FakeMaps()

    with pytest.raises(DomainValidationError) as error:
        await make_service(maps, Clock()).reverse(DRIVER_1, GeoPoint(51.17, 71.45))

    assert error.value.code is ErrorCode.OUTSIDE_SERVICE_AREA
    assert maps.calls == []


async def test_search_normalises_the_text_and_keeps_only_places_in_almaty() -> None:
    maps, clock = FakeMaps(), Clock()
    inside = [GeoResult(f"зелёный базар {i}", GeoPoint(43.26, 76.95)) for i in range(6)]
    outside = GeoResult("зелёный базар, Астана", GeoPoint(51.17, 71.45))
    maps.places = [outside, *inside]
    geo = make_service(maps, clock)

    results = await geo.search(DRIVER_1, "  Зелёный   БАЗАР ")

    assert [r.label for r in results] == [p.label for p in inside[:4]]
    assert maps.calls == ["search:зелёный базар"]
    await geo.search(DRIVER_1, "зелёный базар")
    assert len(maps.calls) == 1


async def test_search_needs_three_characters_after_trimming() -> None:
    maps = FakeMaps()

    assert await make_service(maps, Clock()).search(DRIVER_1, "  жж  ") == []
    assert maps.calls == []


def test_cache_drops_the_oldest_entry_when_full() -> None:
    clock = Clock()
    cache: TtlCache[str, int] = TtlCache(timedelta(hours=1), 2, clock)
    cache.put("a", 1)
    cache.put("b", 2)
    cache.put("c", 3)

    assert cache.get("a") == (False, None)
    assert cache.get("b") == (True, 2)
    assert cache.get("c") == (True, 3)


def test_rate_limit_is_per_user_and_slides() -> None:
    clock = Clock()
    limiter = RateLimiter(2, timedelta(minutes=1), clock)
    limiter.check(DRIVER_1)
    clock.now += timedelta(seconds=20)
    limiter.check(DRIVER_1)
    limiter.check(DRIVER_2)  # another user has their own budget

    with pytest.raises(GeoRateLimitedError) as error:
        limiter.check(DRIVER_1)
    assert error.value.retry_after == timedelta(seconds=40)

    clock.now += timedelta(seconds=40)
    limiter.check(DRIVER_1)


async def test_rate_limit_counts_cached_lookups_too() -> None:
    maps, clock = FakeMaps(), Clock()
    geo = make_service(maps, clock, limit=2)
    await geo.reverse(DRIVER_1, GeoPoint(43.2, 76.9))
    await geo.reverse(DRIVER_1, GeoPoint(43.2, 76.9))

    with pytest.raises(GeoRateLimitedError):
        await geo.search(DRIVER_1, "базар")
