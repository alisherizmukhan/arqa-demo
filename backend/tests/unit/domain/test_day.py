from datetime import UTC, date, datetime, timedelta, timezone

import pytest
from hypothesis import given
from hypothesis import strategies as st

from app.domain.day import (
    DEFAULT_DRIVER_TZ,
    DayWindow,
    format_utc_offset,
    local_day,
    parse_utc_offset,
)
from app.domain.errors import DomainValidationError, ErrorCode
from tests.factories import KZ

OCT_1 = DayWindow(date(2026, 10, 1), KZ)


def test_default_driver_timezone_is_kazakhstan() -> None:
    assert DEFAULT_DRIVER_TZ.utcoffset(None) == timedelta(hours=5)


@pytest.mark.parametrize(
    ("raw", "offset"),
    [
        ("+05:00", timedelta(hours=5)),
        ("-03:30", -timedelta(hours=3, minutes=30)),
        ("+05:45", timedelta(hours=5, minutes=45)),
        ("+00:00", timedelta(0)),
        ("Z", timedelta(0)),
        ("+14:00", timedelta(hours=14)),
        ("-14:00", -timedelta(hours=14)),
    ],
)
def test_parse_utc_offset_accepts(raw: str, offset: timedelta) -> None:
    assert parse_utc_offset(raw).utcoffset(None) == offset


@pytest.mark.parametrize(
    "raw",
    ["", "05:00", " 05:00", "+5:00", "+05", "+0500", "+15:00", "+05:60", "UTC", "Asia/Almaty"],
)
def test_parse_utc_offset_rejects(raw: str) -> None:
    with pytest.raises(DomainValidationError) as exc:
        parse_utc_offset(raw)

    assert exc.value.code is ErrorCode.INVALID_TIMEZONE
    assert exc.value.field == "tz"


@pytest.mark.parametrize("raw", ["+05:00", "-03:30", "+00:00", "+14:00"])
def test_format_utc_offset_round_trips(raw: str) -> None:
    assert format_utc_offset(parse_utc_offset(raw)) == raw


def test_day_window_in_utc() -> None:
    assert OCT_1.start_utc == datetime(2026, 9, 30, 19, 0, tzinfo=UTC)
    assert OCT_1.end_utc == datetime(2026, 10, 1, 19, 0, tzinfo=UTC)


@pytest.mark.parametrize(
    ("moment", "inside"),
    [
        (datetime(2026, 10, 1, 0, 0, 0, tzinfo=KZ), True),
        (datetime(2026, 10, 1, 23, 59, 59, tzinfo=KZ), True),
        (datetime(2026, 10, 1, 23, 59, 59, 999_999, tzinfo=KZ), True),
        (datetime(2026, 10, 2, 0, 0, 0, tzinfo=KZ), False),
        (datetime(2026, 9, 30, 23, 59, 59, tzinfo=KZ), False),
        # Same instants written in UTC.
        (datetime(2026, 9, 30, 19, 0, 0, tzinfo=UTC), True),
        (datetime(2026, 10, 1, 18, 59, 59, tzinfo=UTC), True),
        (datetime(2026, 10, 1, 19, 0, 0, tzinfo=UTC), False),
        (datetime(2026, 9, 30, 18, 59, 59, tzinfo=UTC), False),
    ],
)
def test_day_boundaries(moment: datetime, inside: bool) -> None:
    assert OCT_1.contains(moment) is inside
    assert (OCT_1.start_utc <= moment < OCT_1.end_utc) is inside


def test_trip_crossing_midnight_belongs_to_start_day_only() -> None:
    start = datetime(2026, 9, 30, 23, 50, tzinfo=KZ)

    assert DayWindow(date(2026, 9, 30), KZ).contains(start)
    assert not OCT_1.contains(start)


@pytest.mark.parametrize(
    ("tz", "expected_day"),
    [
        (KZ, date(2026, 10, 2)),
        (UTC, date(2026, 10, 1)),
        (timezone(-timedelta(hours=5)), date(2026, 10, 1)),
    ],
)
def test_day_depends_on_driver_timezone(tz: timezone, expected_day: date) -> None:
    # Seed trip t5: 19:30Z is already 00:30 next day in +05:00.
    assert local_day(datetime(2026, 10, 1, 19, 30, tzinfo=UTC), tz) == expected_day


def test_local_day_rejects_naive_datetime() -> None:
    with pytest.raises(ValueError, match="timezone-aware"):
        local_day(datetime(2026, 10, 1, 8, 0), KZ)  # noqa: DTZ001 - naive on purpose


offsets = st.integers(min_value=-14 * 60, max_value=14 * 60).map(
    lambda minutes: timezone(timedelta(minutes=minutes))
)
aware_moments = st.datetimes(
    min_value=datetime(2000, 1, 2),  # noqa: DTZ001 - hypothesis bounds must be naive
    max_value=datetime(2100, 1, 1),  # noqa: DTZ001
    timezones=offsets,
)


@given(moment=aware_moments, tz=offsets)
def test_utc_window_agrees_with_local_calendar_day(moment: datetime, tz: timezone) -> None:
    """The repository queries by UTC interval; it must match the local-date definition."""
    window = DayWindow(local_day(moment, tz), tz)

    assert window.start_utc <= moment < window.end_utc
    assert window.end_utc - window.start_utc == timedelta(days=1)
