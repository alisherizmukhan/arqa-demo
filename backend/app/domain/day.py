"""Day boundaries in the driver's timezone.

A trip belongs to the local calendar day of its *start*. A day is the half-open
interval [00:00, next day 00:00) in the driver's UTC offset.

Offsets are fixed (e.g. +05:00 for Kazakhstan, which has no DST), so a local day
is always exactly 24 hours and `datetime.combine` never hits a DST gap.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from datetime import UTC, date, datetime, time, timedelta, timezone

from app.domain.errors import DomainValidationError, ErrorCode

DEFAULT_DRIVER_TZ = timezone(timedelta(hours=5))

_OFFSET_PATTERN = re.compile(r"^(?P<sign>[+-])(?P<hours>\d{2}):(?P<minutes>\d{2})$")
_MAX_OFFSET = timedelta(hours=14)


def parse_utc_offset(value: str) -> timezone:
    """Parse '+05:00' / '-03:30' / 'Z' into a fixed-offset timezone."""
    if value == "Z":
        return UTC
    match = _OFFSET_PATTERN.fullmatch(value)
    if match is None:
        raise _invalid_tz(value)
    hours, minutes = int(match["hours"]), int(match["minutes"])
    offset = timedelta(hours=hours, minutes=minutes)
    if minutes >= 60 or offset > _MAX_OFFSET:
        raise _invalid_tz(value)
    return timezone(-offset if match["sign"] == "-" else offset)


def format_utc_offset(tz: timezone) -> str:
    """Inverse of parse_utc_offset (UTC renders as '+00:00')."""
    total_minutes = int(tz.utcoffset(None).total_seconds()) // 60
    sign = "-" if total_minutes < 0 else "+"
    hours, minutes = divmod(abs(total_minutes), 60)
    return f"{sign}{hours:02d}:{minutes:02d}"


def _invalid_tz(value: str) -> DomainValidationError:
    return DomainValidationError(
        ErrorCode.INVALID_TIMEZONE,
        f"tz must be a UTC offset like +05:00 (between -14:00 and +14:00), got {value!r}",
        field="tz",
    )


def local_day(moment: datetime, tz: timezone) -> date:
    """Calendar day of an aware instant as seen in `tz`."""
    if moment.tzinfo is None or moment.utcoffset() is None:
        raise ValueError("local_day requires a timezone-aware datetime")
    return moment.astimezone(tz).date()


@dataclass(frozen=True, slots=True)
class DayWindow:
    """One local calendar day, exposed as a half-open UTC interval for queries."""

    day: date
    tz: timezone

    @property
    def start_utc(self) -> datetime:
        return datetime.combine(self.day, time.min, tzinfo=self.tz).astimezone(UTC)

    @property
    def end_utc(self) -> datetime:
        return self.start_utc + timedelta(days=1)

    def contains(self, moment: datetime) -> bool:
        return local_day(moment, self.tz) == self.day
