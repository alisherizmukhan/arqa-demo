"""Background retries of routes the engine could not build (docs/MAPS.md):
the schedule, the per-round limit, recovery, and the loop surviving a bad
round. The fake engine is down (`fail`) or slow; nothing touches the network."""

import asyncio
import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from datetime import datetime, timedelta

import pytest

from app.application.routing import (
    RetryReport,
    rebuild_route,
    retry_due_routes,
    run_route_retries,
)
from app.application.use_cases import create_trip
from app.domain.route import MAX_ROUTE_ATTEMPTS, RouteStatus, next_route_retry
from app.domain.user import Role, User
from tests.factories import ALMATY, BAZAAR, ESENTAI, NOW, make_trip
from tests.fakes import DRIVER_1, FakeMaps, InMemoryTripRepository

ME = User(id=DRIVER_1, login="user_1", role=Role.DRIVER, display_name="Водитель 1")


class Clock:
    def __init__(self, now: datetime = NOW) -> None:
        self.now = now

    def __call__(self) -> datetime:
        return self.now


def minutes(n: float) -> timedelta:
    return timedelta(minutes=n)


async def _straight_trip(repo: InMemoryTripRepository, trip_id: str = "a") -> None:
    """A trip created while the map service was down."""
    await create_trip(
        repo,
        make_trip(id=trip_id, pickup=BAZAAR, dropoff=ESENTAI),
        DRIVER_1,
        router=FakeMaps(fail=True),
        area=ALMATY,
        now=NOW,
    )


def test_the_schedule_is_1_5_30_minutes_then_6_hours_and_stops_after_10() -> None:
    delays = [next_route_retry(n, NOW) for n in range(MAX_ROUTE_ATTEMPTS + 1)]

    assert [d - NOW if d else None for d in delays] == [
        minutes(1),
        minutes(5),
        minutes(30),
        *[timedelta(hours=6)] * 7,
        None,
    ]


async def test_a_straight_line_at_create_is_retried_a_minute_later() -> None:
    repo = InMemoryTripRepository()

    await _straight_trip(repo)

    assert repo.retries["a"] == (0, NOW + minutes(1))


async def test_a_straight_line_is_not_retried_before_it_is_due() -> None:
    repo, maps = InMemoryTripRepository(), FakeMaps()
    await _straight_trip(repo)

    report = await retry_due_routes(repo, maps, Clock(NOW + minutes(0.5)), limit=4)

    assert (report.built, report.failed) == (0, 0)
    assert maps.calls == []


async def test_a_due_straight_line_becomes_the_road_route() -> None:
    repo, maps = InMemoryTripRepository(), FakeMaps()
    await _straight_trip(repo)

    report = await retry_due_routes(repo, maps, Clock(NOW + minutes(1)), limit=4)

    assert (report.built, report.failed) == (1, 0)
    stored = await repo.get("a")
    assert stored is not None
    assert stored.route.status is RouteStatus.READY
    assert repo.retries["a"] == (1, None)


async def test_each_failure_waits_longer_and_retries_stop_after_10_attempts() -> None:
    repo, down = InMemoryTripRepository(), FakeMaps(fail=True)
    await _straight_trip(repo)
    clock = Clock(NOW)
    waits = []

    for _ in range(MAX_ROUTE_ATTEMPTS):
        clock.now = repo.retries["a"][1] or clock.now
        await retry_due_routes(repo, down, clock, limit=4)
        retry_at = repo.retries["a"][1]
        waits.append(retry_at - clock.now if retry_at else None)

    assert waits == [minutes(5), minutes(30), *[timedelta(hours=6)] * 7, None]
    assert len(down.calls) == MAX_ROUTE_ATTEMPTS
    assert repo.retries["a"] == (MAX_ROUTE_ATTEMPTS, None)
    # Spent: never due again, the straight line stays.
    later = Clock(NOW + timedelta(days=30))
    assert await retry_due_routes(repo, down, later, limit=4) == RetryReport(built=0, failed=0)
    assert len(down.calls) == MAX_ROUTE_ATTEMPTS
    stored = await repo.get("a")
    assert stored is not None
    assert stored.route.status is RouteStatus.STRAIGHT


async def test_pending_seed_routes_are_built_first_and_a_round_has_a_limit() -> None:
    repo, maps = InMemoryTripRepository(), FakeMaps()
    await _straight_trip(repo, "late")
    for n in range(6):
        await repo.insert_if_absent(make_trip(id=f"seed{n}", pickup=BAZAAR, dropoff=ESENTAI))
    await repo.insert_if_absent(make_trip(id="plain"))

    clock = Clock(NOW + minutes(1))
    first = await retry_due_routes(repo, maps, clock, limit=4)
    second = await retry_due_routes(repo, maps, clock, limit=4)

    assert (first.built, second.built) == (4, 3)
    assert len(maps.calls) == 7  # never more than the limit per round
    statuses = {trip_id: owned.route.status for trip_id, owned in repo._store.items()}
    assert statuses.pop("plain") is RouteStatus.NONE
    assert set(statuses.values()) == {RouteStatus.READY}
    # The straight line came after every pending seed route.
    assert repo.retries["late"] == (1, None)


async def test_a_pending_route_that_fails_becomes_straight_and_is_scheduled() -> None:
    repo, down = InMemoryTripRepository(), FakeMaps(fail=True)
    await repo.insert_if_absent(make_trip(id="seed", pickup=BAZAAR, dropoff=ESENTAI))

    await retry_due_routes(repo, down, Clock(), limit=4)

    stored = await repo.get("seed")
    assert stored is not None
    assert stored.route.status is RouteStatus.STRAIGHT
    assert repo.retries["seed"] == (1, NOW + minutes(5))


async def test_a_manual_rebuild_that_fails_starts_the_schedule_again() -> None:
    repo = InMemoryTripRepository()
    await _straight_trip(repo)
    await retry_due_routes(repo, FakeMaps(fail=True), Clock(NOW + minutes(1)), limit=4)
    assert repo.retries["a"][0] == 1

    later = NOW + minutes(3)
    await rebuild_route(repo, FakeMaps(fail=True), ME, "a", later)

    assert repo.retries["a"] == (0, later + minutes(1))


async def test_the_loop_runs_one_limited_round_a_minute_and_survives_a_bad_round(
    caplog: pytest.LogCaptureFixture,
) -> None:
    repo, maps = InMemoryTripRepository(), FakeMaps()
    for n in range(5):
        await repo.insert_if_absent(make_trip(id=f"seed{n}", pickup=BAZAAR, dropoff=ESENTAI))
    opened = 0

    @asynccontextmanager
    async def open_repo() -> AsyncIterator[InMemoryTripRepository]:
        nonlocal opened
        opened += 1
        if opened == 1:
            raise ConnectionError("database restarting")
        yield repo

    pauses: list[float] = []

    async def sleep(seconds: float) -> None:
        pauses.append(seconds)
        if len(pauses) == 3:
            raise asyncio.CancelledError

    with caplog.at_level(logging.INFO), pytest.raises(asyncio.CancelledError):
        await run_route_retries(open_repo, maps, Clock(), per_minute=3, sleep=sleep)

    assert pauses == [60, 60, 60]
    assert len(maps.calls) == 5  # rounds 2 and 3: 3 + 2, never more than 3 a minute
    assert "background round failed" in caplog.text
    assert all(o.route.status is RouteStatus.READY for o in repo._store.values())
