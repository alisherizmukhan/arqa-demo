from dataclasses import replace
from datetime import UTC, date, datetime, timedelta

import pytest

from app.application.errors import TripConflictError
from app.application.use_cases import (
    create_trip,
    get_daily_summary,
    get_trips_for_day,
    seed_accounts,
    seed_trips,
)
from app.domain.day import DayWindow
from app.domain.user import DemoAccount, Role
from tests.factories import KZ, load_seed_trips, make_trip
from tests.fakes import InMemoryTripRepository, InMemoryUserRepository, PlainTextHasher

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


async def test_seed_adds_missing_trips_to_existing_data() -> None:
    start = datetime(2026, 10, 5, 9, 0, tzinfo=KZ)
    repo = InMemoryTripRepository([make_trip(id="mine", start=start, end=start + timedelta(1))])
    seed = load_seed_trips()

    assert await seed_trips(repo, seed) == len(seed)
    assert await repo.count() == 1 + len(seed)
    assert repo.trips["mine"].start == start


ACCOUNTS = [
    DemoAccount(login="user_1", password="pw1", role=Role.DRIVER, display_name="Водитель 1"),
    DemoAccount(login="admin", password="adm", role=Role.ADMIN, display_name="Администратор"),
]


async def test_seed_accounts_creates_missing_and_is_idempotent() -> None:
    users = InMemoryUserRepository()

    first = await seed_accounts(users, PlainTextHasher(), ACCOUNTS)
    again = await seed_accounts(users, PlainTextHasher(), ACCOUNTS)

    assert (first.created, first.passwords_updated) == (2, 0)
    assert (again.created, again.passwords_updated) == (0, 0)
    assert users.users["admin"].role is Role.ADMIN
    assert users.hashes["user_1"] == "plain:pw1"


async def test_seed_accounts_resets_a_password_changed_in_settings() -> None:
    users = InMemoryUserRepository()
    await seed_accounts(users, PlainTextHasher(), ACCOUNTS)
    changed = [replace(ACCOUNTS[0], password="new-secret"), ACCOUNTS[1]]

    result = await seed_accounts(users, PlainTextHasher(), changed)

    assert (result.created, result.passwords_updated) == (0, 1)
    assert users.hashes["user_1"] == "plain:new-secret"
    assert users.hashes["admin"] == "plain:adm"
