import re
from collections.abc import AsyncIterator
from datetime import date
from typing import Annotated, cast

from fastapi import Depends, Query, Request, status
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.api.errors import ApiError, ApiErrorCode
from app.application.ports import TripRepository
from app.domain.day import DEFAULT_DRIVER_TZ, DayWindow, format_utc_offset, parse_utc_offset
from app.infrastructure.repository import SqlTripRepository

_DATE_PATTERN = re.compile(r"^\d{4}-\d{2}-\d{2}$")
_DEFAULT_TZ = format_utc_offset(DEFAULT_DRIVER_TZ)


async def get_session(request: Request) -> AsyncIterator[AsyncSession]:
    sessionmaker = cast(async_sessionmaker[AsyncSession], request.app.state.sessionmaker)
    async with sessionmaker() as session:
        yield session


SessionDep = Annotated[AsyncSession, Depends(get_session)]


def get_repository(session: SessionDep) -> TripRepository:
    return SqlTripRepository(session)


RepositoryDep = Annotated[TripRepository, Depends(get_repository)]


def _parse_day(raw: str) -> date:
    parsed: date | None = None
    if _DATE_PATTERN.fullmatch(raw):
        try:
            parsed = date.fromisoformat(raw)
        except ValueError:  # e.g. 2026-02-30
            parsed = None
    if parsed is None:
        raise ApiError(
            status.HTTP_422_UNPROCESSABLE_CONTENT,
            ApiErrorCode.INVALID_DATE,
            f"date must be a calendar date in YYYY-MM-DD format, got {raw!r}",
            field="date",
        )
    return parsed


def get_day_window(
    date: Annotated[
        str,
        Query(
            description="Local calendar day, YYYY-MM-DD",
            openapi_examples={"reference day": {"value": "2026-10-01"}},
        ),
    ],
    tz: Annotated[
        str,
        Query(
            description=(
                "Driver's UTC offset, ±HH:MM or Z. Encode '+' as %2B; "
                "an unencoded '+' (decoded to a space) is accepted too."
            ),
            openapi_examples={
                "Kazakhstan": {"value": "+05:00"},
                "UTC": {"value": "Z"},
            },
        ),
    ] = _DEFAULT_TZ,
) -> DayWindow:
    # In a query string an unencoded '+' decodes to ' ': "?tz=+05:00" arrives as " 05:00".
    if tz.startswith(" "):
        tz = "+" + tz[1:]
    return DayWindow(_parse_day(date), parse_utc_offset(tz))


DayWindowDep = Annotated[DayWindow, Depends(get_day_window)]
