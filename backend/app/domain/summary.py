from __future__ import annotations

from collections.abc import Iterable
from dataclasses import dataclass
from datetime import date
from typing import assert_never

from app.domain.day import DayWindow
from app.domain.trip import PaymentMethod, Trip


@dataclass(frozen=True, slots=True, kw_only=True)
class DailySummary:
    """Totals for one local day. All money fields are integer tenge.

    Invariants: net == revenue - commission, cash + card == revenue.
    """

    day: date
    trips_count: int
    revenue: int
    commission: int
    net: int
    cash: int
    card: int


def calculate_daily_summary(window: DayWindow, trips: Iterable[Trip]) -> DailySummary:
    """Sum the trips of one day.

    Every trip must start inside `window`; anything else is a bug in the caller
    (e.g. a wrong repository query), so it fails loudly instead of being skipped.
    """
    trips_count = revenue = commission = cash = card = 0
    for trip in trips:
        if not window.contains(trip.start):
            raise ValueError(f"trip {trip.id} does not start on {window.day.isoformat()}")
        trips_count += 1
        revenue += trip.amount
        commission += trip.commission
        match trip.payment:
            case PaymentMethod.CASH:
                cash += trip.amount
            case PaymentMethod.CARD:
                card += trip.amount
            case _ as unreachable:
                assert_never(unreachable)

    return DailySummary(
        day=window.day,
        trips_count=trips_count,
        revenue=revenue,
        commission=commission,
        net=revenue - commission,
        cash=cash,
        card=card,
    )
