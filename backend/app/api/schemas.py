from datetime import date, datetime, timezone, tzinfo
from typing import Annotated, Any, Literal
from uuid import UUID

from pydantic import AwareDatetime, BaseModel, BeforeValidator, ConfigDict, Field, StrictInt
from pydantic_core import PydanticCustomError

from app.domain.day import format_utc_offset
from app.domain.summary import DailySummary
from app.domain.trip import MAX_AMOUNT, PaymentMethod, Trip
from app.domain.user import Role, User

TripId = Annotated[
    str,
    Field(
        min_length=1,
        max_length=64,
        pattern=r"^[A-Za-z0-9_-]+$",
        description="Client-generated id (UUID v4 recommended). Doubles as the idempotency key.",
        examples=["3f2b8c1e-9a4d-4e6b-8f1a-2c7d5e9b0a13"],
    ),
]


def _iso_string_only(value: object) -> object:
    # FastAPI validates the already-decoded JSON in Python mode, where `Strict()` would
    # reject strings and lax mode would accept unix timestamps. Allow ISO strings only.
    if not isinstance(value, str):
        raise PydanticCustomError("datetime_type", "must be an ISO 8601 string with a UTC offset")
    return value


# An ISO 8601 string with an explicit offset; numbers and naive values fail.
Timestamp = Annotated[AwareDatetime, BeforeValidator(_iso_string_only)]


class TripIn(BaseModel):
    """A trip to create. Re-sending the same id and payload is safe (200, no duplicate)."""

    model_config = ConfigDict(
        extra="forbid",
        json_schema_extra={
            "examples": [
                {
                    "id": "3f2b8c1e-9a4d-4e6b-8f1a-2c7d5e9b0a13",
                    "start": "2026-10-01T10:00:00+05:00",
                    "end": "2026-10-01T10:25:00+05:00",
                    "amount": 2200,
                    "payment": "card",
                    "commission": 330,
                }
            ]
        },
    )

    id: TripId
    start: Timestamp = Field(description="Trip start with UTC offset, e.g. 2026-10-01T08:10+05:00")
    end: Timestamp = Field(description="Trip end with UTC offset; must be after start")
    amount: StrictInt = Field(description=f"Fare in whole tenge, 0 < amount <= {MAX_AMOUNT}")
    payment: PaymentMethod
    commission: StrictInt = Field(description="Platform commission in tenge, 0..amount")

    def to_domain(self) -> Trip:
        return Trip(
            id=self.id,
            start=self.start,
            end=self.end,
            amount=self.amount,
            payment=self.payment,
            commission=self.commission,
        )


class TripOut(BaseModel):
    id: str
    start: datetime = Field(description="In the requested timezone")
    end: datetime
    amount: int
    payment: PaymentMethod
    commission: int
    net: int = Field(description="amount - commission")

    @classmethod
    def from_domain(cls, trip: Trip, tz: tzinfo) -> "TripOut":
        return cls(
            id=trip.id,
            start=trip.start.astimezone(tz),
            end=trip.end.astimezone(tz),
            amount=trip.amount,
            payment=trip.payment,
            commission=trip.commission,
            net=trip.net,
        )


class DayTripsOut(BaseModel):
    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {
                    "date": "2026-10-01",
                    "tz": "+05:00",
                    "trips": [
                        {
                            "id": "t1",
                            "start": "2026-10-01T08:10:00+05:00",
                            "end": "2026-10-01T08:32:00+05:00",
                            "amount": 2400,
                            "payment": "card",
                            "commission": 360,
                            "net": 2040,
                        }
                    ],
                }
            ]
        }
    )

    date: date
    tz: str
    trips: list[TripOut] = Field(description="Trips that started on this day, ordered by start")


class SummaryOut(BaseModel):
    """Daily totals. All money in whole tenge."""

    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {
                    "date": "2026-10-01",
                    "tz": "+05:00",
                    "trips_count": 2,
                    "revenue": 3900,
                    "commission": 585,
                    "net": 3315,
                    "cash": 1500,
                    "card": 2400,
                }
            ]
        }
    )

    date: date
    tz: str
    trips_count: int
    revenue: int
    commission: int
    net: int = Field(description="revenue - commission")
    cash: int = Field(description="Revenue paid in cash")
    card: int = Field(description="Revenue paid by card")

    @classmethod
    def from_domain(cls, summary: DailySummary, tz: timezone) -> "SummaryOut":
        return cls(
            date=summary.day,
            tz=format_utc_offset(tz),
            trips_count=summary.trips_count,
            revenue=summary.revenue,
            commission=summary.commission,
            net=summary.net,
            cash=summary.cash,
            card=summary.card,
        )


class HealthOut(BaseModel):
    status: Literal["ok"]
    database: Literal["ok"]


class ErrorBody(BaseModel):
    code: str = Field(examples=["commission_exceeds_amount"])
    message: str = Field(examples=["commission must not exceed amount"])
    field: str | None = Field(examples=["commission"])


class ErrorResponse(BaseModel):
    """Every error response has this shape."""

    error: ErrorBody


class LoginIn(BaseModel):
    model_config = ConfigDict(
        extra="forbid",
        json_schema_extra={"examples": [{"login": "user_1", "password": "password_1"}]},
    )

    login: str = Field(min_length=1, max_length=64)
    password: str = Field(min_length=1, max_length=256)


class UserOut(BaseModel):
    id: UUID
    login: str
    role: Role
    display_name: str

    @classmethod
    def from_domain(cls, user: User) -> "UserOut":
        return cls(id=user.id, login=user.login, role=user.role, display_name=user.display_name)


class AdminUserOut(UserOut):
    is_active: bool

    @classmethod
    def from_domain(cls, user: User) -> "AdminUserOut":
        return cls(
            id=user.id,
            login=user.login,
            role=user.role,
            display_name=user.display_name,
            is_active=user.is_active,
        )


class LoginOut(BaseModel):
    token: str = Field(description="Opaque bearer token. Send as `Authorization: Bearer <token>`.")
    user: UserOut


class UserPatchIn(BaseModel):
    model_config = ConfigDict(
        extra="forbid", json_schema_extra={"examples": [{"is_active": False}]}
    )

    is_active: bool


class RevokedOut(BaseModel):
    revoked: int = Field(description="How many active sessions were ended")


def error_example(
    status_code: int, description: str, code: str, message: str
) -> dict[int | str, dict[str, Any]]:
    """An OpenAPI `responses` entry with the error shape and one example."""
    return {
        status_code: {
            "model": ErrorResponse,
            "description": description,
            "content": {
                "application/json": {
                    "example": {"error": {"code": code, "message": message, "field": None}}
                }
            },
        }
    }
