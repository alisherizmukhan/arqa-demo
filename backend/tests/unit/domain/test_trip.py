from datetime import UTC, datetime, timedelta
from typing import Any

import pytest

from app.domain.errors import DomainValidationError, ErrorCode
from app.domain.trip import MAX_AMOUNT, PaymentMethod
from tests.factories import KZ, make_trip

START = datetime(2026, 10, 1, 8, 10, tzinfo=KZ)


def test_valid_trip() -> None:
    trip = make_trip(amount=2400, commission=360)

    assert trip.net == 2040


@pytest.mark.parametrize(
    ("amount", "commission"), [(1, 0), (2400, 0), (2400, 2400), (MAX_AMOUNT, 0)]
)
def test_boundary_values_are_allowed(amount: int, commission: int) -> None:
    make_trip(amount=amount, commission=commission)


@pytest.mark.parametrize(
    ("overrides", "code", "field"),
    [
        ({"amount": 0}, ErrorCode.INVALID_AMOUNT, "amount"),
        ({"amount": -100}, ErrorCode.INVALID_AMOUNT, "amount"),
        ({"amount": 2400.0}, ErrorCode.INVALID_AMOUNT, "amount"),
        ({"amount": True}, ErrorCode.INVALID_AMOUNT, "amount"),
        ({"amount": MAX_AMOUNT + 1}, ErrorCode.AMOUNT_TOO_LARGE, "amount"),
        ({"commission": -1}, ErrorCode.INVALID_COMMISSION, "commission"),
        ({"commission": 36.5}, ErrorCode.INVALID_COMMISSION, "commission"),
        ({"commission": 2401}, ErrorCode.COMMISSION_EXCEEDS_AMOUNT, "commission"),
        ({"end": START}, ErrorCode.INVALID_TIME_RANGE, "end"),
        ({"end": START - timedelta(seconds=1)}, ErrorCode.INVALID_TIME_RANGE, "end"),
        (
            {"start": datetime(2026, 10, 1, 8, 10), "end": datetime(2026, 10, 1, 8, 30)},  # noqa: DTZ001
            ErrorCode.NAIVE_DATETIME,
            "start",
        ),
        ({"end": datetime(2026, 10, 1, 8, 30)}, ErrorCode.NAIVE_DATETIME, "end"),  # noqa: DTZ001
        ({"id": ""}, ErrorCode.INVALID_ID, "id"),
        ({"id": "has space"}, ErrorCode.INVALID_ID, "id"),
        ({"id": "x" * 65}, ErrorCode.INVALID_ID, "id"),
        ({"payment": "crypto"}, ErrorCode.INVALID_PAYMENT, "payment"),
    ],
)
def test_invalid_trip_is_rejected(overrides: dict[str, Any], code: ErrorCode, field: str) -> None:
    overrides.setdefault("start", START)

    with pytest.raises(DomainValidationError) as exc:
        make_trip(**overrides)

    assert exc.value.code is code
    assert exc.value.field == field


def test_uuid_id_is_accepted() -> None:
    make_trip(id="3f2b8c1e-9a4d-4e6b-8f1a-2c7d5e9b0a13")


@pytest.mark.parametrize("raw", ["cash", "card"])
def test_payment_parse(raw: str) -> None:
    assert PaymentMethod.parse(raw).value == raw


@pytest.mark.parametrize("raw", ["CASH", "Card", "crypto", ""])
def test_payment_parse_is_strict(raw: str) -> None:
    with pytest.raises(DomainValidationError) as exc:
        PaymentMethod.parse(raw)

    assert exc.value.code is ErrorCode.INVALID_PAYMENT


def test_same_payload_compares_instants_not_offsets() -> None:
    local = make_trip(start=START, end=START + timedelta(minutes=22))
    utc = make_trip(
        start=START.astimezone(UTC), end=(START + timedelta(minutes=22)).astimezone(UTC)
    )

    assert local.has_same_payload(utc)


def test_same_payload_ignores_id() -> None:
    assert make_trip(id="a").has_same_payload(make_trip(id="b"))


@pytest.mark.parametrize(
    "changes",
    [
        {"amount": 2500},
        {"commission": 361},
        {"payment": PaymentMethod.CASH},
        {"end": START + timedelta(minutes=23)},
    ],
)
def test_different_payload_is_detected(changes: dict[str, Any]) -> None:
    assert not make_trip(start=START).has_same_payload(make_trip(start=START, **changes))


@pytest.mark.parametrize(
    ("start", "end", "code", "field"),
    [
        (
            datetime(1999, 12, 31, 23, 59, 59, tzinfo=UTC),
            datetime(2000, 1, 1, 0, 30, tzinfo=UTC),
            ErrorCode.DATETIME_OUT_OF_RANGE,
            "start",
        ),
        (
            datetime(2099, 12, 31, 23, 50, tzinfo=UTC),
            datetime(2100, 1, 1, 0, 10, tzinfo=UTC),
            ErrorCode.DATETIME_OUT_OF_RANGE,
            "end",
        ),
        (
            datetime(1, 1, 1, 1, 0, tzinfo=KZ),
            datetime(1, 1, 1, 2, 0, tzinfo=KZ),
            ErrorCode.DATETIME_OUT_OF_RANGE,
            "start",
        ),
        (START, START + timedelta(hours=24, seconds=1), ErrorCode.TRIP_TOO_LONG, "end"),
        (START, START + timedelta(days=3 * 365), ErrorCode.TRIP_TOO_LONG, "end"),
    ],
)
def test_implausible_times_are_rejected(
    start: datetime, end: datetime, code: ErrorCode, field: str
) -> None:
    with pytest.raises(DomainValidationError) as exc:
        make_trip(start=start, end=end)

    assert exc.value.code is code
    assert exc.value.field == field


@pytest.mark.parametrize(
    ("start", "end"),
    [
        (datetime(2000, 1, 1, tzinfo=UTC), datetime(2000, 1, 1, 0, 20, tzinfo=UTC)),
        (
            datetime(2099, 12, 31, 23, 0, tzinfo=UTC),
            datetime(2099, 12, 31, 23, 59, 59, tzinfo=UTC),
        ),
        (START, START + timedelta(hours=24)),
    ],
)
def test_boundary_times_are_allowed(start: datetime, end: datetime) -> None:
    make_trip(start=start, end=end)
