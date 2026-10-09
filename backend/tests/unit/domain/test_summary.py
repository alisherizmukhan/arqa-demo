from datetime import date, datetime, time, timedelta

import pytest
from hypothesis import given
from hypothesis import strategies as st

from app.domain.day import DayWindow
from app.domain.summary import DailySummary, calculate_daily_summary
from app.domain.trip import MAX_AMOUNT, PaymentMethod, Trip
from tests.factories import KZ, load_seed_trips, make_trip, trip_from_json

REFERENCE_DAY = DayWindow(date(2026, 10, 1), KZ)
REFERENCE_SUMMARY = DailySummary(
    day=date(2026, 10, 1),
    trips_count=2,
    revenue=3900,
    commission=585,
    net=3315,
    cash=1500,
    card=2400,
)


def test_reference_case_from_assignment() -> None:
    trips = [
        trip_from_json(
            {
                "id": "t1",
                "start": "2026-10-01T08:10:00+05:00",
                "end": "2026-10-01T08:32:00+05:00",
                "amount": 2400,
                "payment": "card",
                "commission": 360,
            }
        ),
        trip_from_json(
            {
                "id": "t2",
                "start": "2026-10-01T09:05:00+05:00",
                "end": "2026-10-01T09:20:00+05:00",
                "amount": 1500,
                "payment": "cash",
                "commission": 225,
            }
        ),
    ]

    assert calculate_daily_summary(REFERENCE_DAY, trips) == REFERENCE_SUMMARY


def test_reference_case_from_seed_file() -> None:
    """The seed has edge-case trips around 2026-10-01; none may leak into user_1's day."""
    day_trips = [t for t in load_seed_trips() if REFERENCE_DAY.contains(t.start)]

    assert sorted(t.id for t in day_trips) == ["t1", "t2"]
    assert calculate_daily_summary(REFERENCE_DAY, day_trips) == REFERENCE_SUMMARY


def test_empty_day_is_all_zeros() -> None:
    summary = calculate_daily_summary(REFERENCE_DAY, [])

    assert summary == DailySummary(
        day=date(2026, 10, 1), trips_count=0, revenue=0, commission=0, net=0, cash=0, card=0
    )


def test_money_fields_are_ints() -> None:
    summary = calculate_daily_summary(
        REFERENCE_DAY, [make_trip(amount=1001, commission=150, payment=PaymentMethod.CASH)]
    )

    for value in (summary.revenue, summary.commission, summary.net, summary.cash, summary.card):
        assert type(value) is int


def test_trip_crossing_midnight_counts_fully_on_start_day() -> None:
    late = make_trip(
        start=datetime(2026, 10, 1, 23, 50, tzinfo=KZ),
        end=datetime(2026, 10, 2, 0, 20, tzinfo=KZ),
        amount=3200,
        commission=480,
        payment=PaymentMethod.CASH,
    )

    summary = calculate_daily_summary(REFERENCE_DAY, [late])

    assert (summary.trips_count, summary.revenue, summary.cash) == (1, 3200, 3200)


def test_trip_from_another_day_is_a_caller_bug() -> None:
    other_day = make_trip(start=datetime(2026, 10, 2, 0, 0, tzinfo=KZ))

    with pytest.raises(ValueError, match="does not start on 2026-10-01"):
        calculate_daily_summary(REFERENCE_DAY, [other_day])


@st.composite
def trips_on_reference_day(draw: st.DrawFn) -> Trip:
    seconds = draw(st.integers(min_value=0, max_value=24 * 3600 - 1))
    start = datetime.combine(REFERENCE_DAY.day, time.min, tzinfo=KZ) + timedelta(seconds=seconds)
    amount = draw(st.integers(min_value=1, max_value=MAX_AMOUNT))
    return make_trip(
        id=draw(st.from_regex(r"[a-z0-9]{1,16}", fullmatch=True)),
        start=start,
        end=start + timedelta(minutes=draw(st.integers(min_value=1, max_value=180))),
        amount=amount,
        commission=draw(st.integers(min_value=0, max_value=amount)),
        payment=draw(st.sampled_from(PaymentMethod)),
    )


@given(st.lists(trips_on_reference_day(), max_size=50))
def test_summary_invariants(trips: list[Trip]) -> None:
    summary = calculate_daily_summary(REFERENCE_DAY, trips)

    assert summary.trips_count == len(trips)
    assert summary.revenue == sum(t.amount for t in trips)
    assert summary.commission == sum(t.commission for t in trips)
    assert summary.net == summary.revenue - summary.commission
    assert summary.cash + summary.card == summary.revenue
    assert summary.cash == sum(t.amount for t in trips if t.payment is PaymentMethod.CASH)
    assert 0 <= summary.net <= summary.revenue


def test_user_2_reference_case_from_seed_file() -> None:
    day_trips = [t for t in load_seed_trips("user_2") if REFERENCE_DAY.contains(t.start)]

    assert sorted(t.id for t in day_trips) == ["u2-t1", "u2-t2"]
    summary = calculate_daily_summary(REFERENCE_DAY, day_trips)
    assert (summary.trips_count, summary.revenue, summary.commission, summary.net) == (
        2,
        4800,
        720,
        4080,
    )
    assert (summary.cash, summary.card) == (1800, 3000)


def test_all_drivers_reference_case_from_seed_file() -> None:
    day_trips = [t for t in load_seed_trips(None) if REFERENCE_DAY.contains(t.start)]

    summary = calculate_daily_summary(REFERENCE_DAY, day_trips)
    assert (summary.trips_count, summary.revenue, summary.commission, summary.net) == (
        4,
        8700,
        1305,
        7395,
    )
    assert (summary.cash, summary.card) == (3300, 5400)
