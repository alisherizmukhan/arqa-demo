import re
from collections.abc import AsyncIterator
from datetime import UTC, date, datetime
from typing import Annotated, cast
from uuid import UUID

from fastapi import Depends, Query, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.api.errors import ApiError, ApiErrorCode
from app.application import access, auth
from app.application.errors import NotAuthenticatedError
from app.application.ports import Accounts, TripRepository
from app.domain.day import (
    DEFAULT_DRIVER_TZ,
    MAX_SUPPORTED_YEAR,
    MIN_SUPPORTED_YEAR,
    DayWindow,
    format_utc_offset,
    parse_utc_offset,
)
from app.domain.user import User
from app.infrastructure.repository import (
    SqlSessionRepository,
    SqlTripRepository,
    SqlUserRepository,
)
from app.infrastructure.settings import Settings

_DATE_PATTERN = re.compile(r"^\d{4}-\d{2}-\d{2}$")
_DEFAULT_TZ = format_utc_offset(DEFAULT_DRIVER_TZ)


async def get_session(request: Request) -> AsyncIterator[AsyncSession]:
    sessionmaker = cast(async_sessionmaker[AsyncSession], request.app.state.sessionmaker)
    async with sessionmaker() as session:
        yield session


SessionDep = Annotated[AsyncSession, Depends(get_session)]


def get_settings(request: Request) -> Settings:
    return cast(Settings, request.app.state.settings)


SettingsDep = Annotated[Settings, Depends(get_settings)]


def get_now() -> datetime:
    """The current time (a dependency, so tests can move the clock)."""
    return datetime.now(UTC)


NowDep = Annotated[datetime, Depends(get_now)]


def get_accounts(session: SessionDep) -> Accounts:
    return Accounts(users=SqlUserRepository(session), sessions=SqlSessionRepository(session))


AccountsDep = Annotated[Accounts, Depends(get_accounts)]

# Reads `Authorization: Bearer <token>` and declares the scheme in OpenAPI.
# auto_error=False: a missing header is handled below (AUTH_REQUIRED=false).
bearer_scheme = HTTPBearer(auto_error=False, description="Token from POST /auth/login")

# AUTH_REQUIRED=false (production until the app supports login): a request
# without a token acts as this driver, exactly like before accounts existed.
LEGACY_DRIVER_LOGIN = "user_1"


async def get_current_user(
    request: Request,
    accounts: AccountsDep,
    settings: SettingsDep,
    now: NowDep,
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer_scheme)],
) -> User:
    """The signed-in user. A token that is sent is always checked, even when
    AUTH_REQUIRED is off; only a request without an Authorization header falls
    back to user_1 (a malformed header is a 401, never the fallback)."""
    if credentials is None and "authorization" in request.headers:
        raise NotAuthenticatedError("the Authorization header must be 'Bearer <token>'")
    if credentials is not None:
        return await auth.authenticate(
            sessions=accounts.sessions, token=credentials.credentials, now=now
        )
    if settings.auth_required:
        raise NotAuthenticatedError
    driver = await accounts.users.get_by_login(LEGACY_DRIVER_LOGIN)
    if driver is None:
        raise ApiError(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            ApiErrorCode.DATABASE_UNAVAILABLE,
            f"driver {LEGACY_DRIVER_LOGIN!r} does not exist yet (seed on startup is off)",
        )
    return driver


CurrentUserDep = Annotated[User, Depends(get_current_user)]


async def get_read_scope(
    session: SessionDep,
    actor: CurrentUserDep,
    driver_id: Annotated[
        UUID | None,
        Query(description="Admin only: one driver's data. Absent: all drivers. Drivers: 403."),
    ] = None,
) -> TripRepository:
    """Trips the signed-in user may read: their own (driver) or all / one
    driver's (admin)."""
    scope = await access.trip_scope(SqlUserRepository(session), actor, driver_id)
    return SqlTripRepository(session, scope)


ReadScopeDep = Annotated[TripRepository, Depends(get_read_scope)]


def _parse_day(raw: str) -> date:
    parsed: date | None = None
    if _DATE_PATTERN.fullmatch(raw):
        try:
            parsed = date.fromisoformat(raw)
        except ValueError:  # e.g. 2026-02-30
            parsed = None
    if parsed is None or not MIN_SUPPORTED_YEAR <= parsed.year <= MAX_SUPPORTED_YEAR:
        raise ApiError(
            status.HTTP_422_UNPROCESSABLE_CONTENT,
            ApiErrorCode.INVALID_DATE,
            f"date must be a calendar date in YYYY-MM-DD format between "
            f"{MIN_SUPPORTED_YEAR} and {MAX_SUPPORTED_YEAR}, got {raw!r}",
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
