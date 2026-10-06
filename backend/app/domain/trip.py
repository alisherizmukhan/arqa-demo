from __future__ import annotations

import re
from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum

from app.domain.errors import DomainValidationError, ErrorCode

TRIP_ID_PATTERN = re.compile(r"^[A-Za-z0-9_-]{1,64}$")

# Sanity cap (tenge). Keeps sums far inside BIGINT and rejects typos like an extra "000000".
MAX_AMOUNT = 10_000_000


class PaymentMethod(StrEnum):
    CASH = "cash"
    CARD = "card"

    @classmethod
    def parse(cls, value: str) -> PaymentMethod:
        try:
            return cls(value)
        except ValueError:
            raise DomainValidationError(
                ErrorCode.INVALID_PAYMENT,
                f"payment must be one of: {', '.join(m.value for m in cls)}",
                field="payment",
            ) from None


@dataclass(frozen=True, slots=True, kw_only=True)
class Trip:
    """A single trip. Money is integer tenge; timestamps are timezone-aware.

    Constructing a Trip validates it, so an invalid Trip cannot exist.
    """

    id: str
    start: datetime
    end: datetime
    amount: int
    payment: PaymentMethod
    commission: int

    def __post_init__(self) -> None:
        _validate(self)

    @property
    def net(self) -> int:
        return self.amount - self.commission

    def has_same_payload(self, other: Trip) -> bool:
        """Compare everything except the id. Datetimes compare as instants,
        so 08:10+05:00 and 03:10Z are the same payload."""
        return (
            self.start == other.start
            and self.end == other.end
            and self.amount == other.amount
            and self.payment == other.payment
            and self.commission == other.commission
        )


def _is_int(value: object) -> bool:
    # bool is a subclass of int; True must not pass as 1 tenge.
    return type(value) is int


def _is_aware(value: datetime) -> bool:
    return value.tzinfo is not None and value.utcoffset() is not None


def _validate(trip: Trip) -> None:
    if not isinstance(trip.id, str) or not TRIP_ID_PATTERN.fullmatch(trip.id):
        raise DomainValidationError(
            ErrorCode.INVALID_ID, "id must be 1-64 chars of [A-Za-z0-9_-]", field="id"
        )
    for name in ("start", "end"):
        if not _is_aware(getattr(trip, name)):
            raise DomainValidationError(
                ErrorCode.NAIVE_DATETIME,
                f"{name} must include a UTC offset, e.g. 2026-10-01T08:10:00+05:00",
                field=name,
            )
    if trip.end <= trip.start:
        raise DomainValidationError(
            ErrorCode.INVALID_TIME_RANGE, "end must be after start", field="end"
        )
    if not isinstance(trip.payment, PaymentMethod):
        PaymentMethod.parse(str(trip.payment))
    if not _is_int(trip.amount) or trip.amount <= 0:
        raise DomainValidationError(
            ErrorCode.INVALID_AMOUNT, "amount must be a positive integer", field="amount"
        )
    if trip.amount > MAX_AMOUNT:
        raise DomainValidationError(
            ErrorCode.AMOUNT_TOO_LARGE, f"amount must not exceed {MAX_AMOUNT}", field="amount"
        )
    if not _is_int(trip.commission) or trip.commission < 0:
        raise DomainValidationError(
            ErrorCode.INVALID_COMMISSION,
            "commission must be a non-negative integer",
            field="commission",
        )
    if trip.commission > trip.amount:
        raise DomainValidationError(
            ErrorCode.COMMISSION_EXCEEDS_AMOUNT,
            "commission must not exceed amount",
            field="commission",
        )
