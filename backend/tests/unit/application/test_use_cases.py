from datetime import UTC, date, datetime, timedelta

import pytest

from app.application.errors import TripConflictError
from app.application.use_cases import (
    create_trip,
    get_daily_summary,
    get_trips_for_day,
    seed_trips,
)
from app.domain.day import DayWindow
from tests.factories import KZ, load_seed_trips, make_trip
from tests.fakes import InMemoryTripRepository

OCT_1 = DayWindow(date(2026, 10, 1), KZ)


async def test_trips_for_day_are_sorted_and_bounded() -> None:
    repo = InMemoryTripRepository(load_seed_trips())

    trips = await get_trips_for_day(repo, OCT_1)

    assert [t.id for t in trips] == ["t1", "t2"]


async def test_daily_summary_reference_case() -> None:
    summary = await get_daily_summary(InMemoryTripRepository(load_seed_trips()), OCT_1)

    assert (summary.trips_count, summary.revenue, summary.commission, summary.net) == (
        2,
        3900,
        585,
        3315,
    )
    assert (summary.cash, summary.card) == (1500, 2400)


async def test_create_new_trip() -> None:
    repo = InMemoryTripRepository()
    trip = make_trip(id="new")

    result = await create_trip(repo, trip)

    assert result.created
    assert result.trip == trip
    assert await repo.count() == 1


async def test_create_same_trip_twice_returns_existing() -> None:
    repo = InMemoryTripRepository()
    await create_trip(repo, make_trip(id="dup"))

    result = await create_trip(repo, make_trip(id="dup"))

    assert not result.created
    assert await repo.count() == 1


async def test_same_trip_in_other_offset_notation_is_not_a_conflict() -> None:
    repo = InMemoryTripRepository()
    original = make_trip(id="dup")
    await create_trip(repo, original)
    in_utc = make_trip(
        id="dup", start=original.start.astimezone(UTC), end=original.end.astimezone(UTC)
    )

    result = await create_trip(repo, in_utc)

    assert not result.created
    assert result.trip is repo.trips["dup"]


async def test_same_id_different_payload_conflicts() -> None:
    repo = InMemoryTripRepository()
    await create_trip(repo, make_trip(id="dup", amount=2400))

    with pytest.raises(TripConflictError) as exc:
        await create_trip(repo, make_trip(id="dup", amount=2500))

    assert exc.value.trip_id == "dup"
    assert repo.trips["dup"].amount == 2400


async def test_seed_into_empty_store_then_skip() -> None:
    repo = InMemoryTripRepository()
    seed = load_seed_trips()

    assert await seed_trips(repo, seed) == len(seed)
    assert await seed_trips(repo, seed) == 0
    assert await repo.count() == len(seed)


async def test_seed_skipped_when_store_has_data() -> None:
    start = datetime(2026, 10, 5, 9, 0, tzinfo=KZ)
    repo = InMemoryTripRepository([make_trip(id="mine", start=start, end=start + timedelta(1))])

    assert await seed_trips(repo, load_seed_trips()) == 0
    assert await repo.count() == 1
