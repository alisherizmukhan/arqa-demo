from enum import StrEnum


class ErrorCode(StrEnum):
    """Stable machine-readable codes. Clients localize by code, not by message."""

    INVALID_ID = "invalid_id"
    NAIVE_DATETIME = "naive_datetime"
    INVALID_TIME_RANGE = "invalid_time_range"
    INVALID_AMOUNT = "invalid_amount"
    AMOUNT_TOO_LARGE = "amount_too_large"
    INVALID_COMMISSION = "invalid_commission"
    COMMISSION_EXCEEDS_AMOUNT = "commission_exceeds_amount"
    INVALID_PAYMENT = "invalid_payment"
    INVALID_TIMEZONE = "invalid_timezone"
    DATETIME_OUT_OF_RANGE = "datetime_out_of_range"
    TRIP_TOO_LONG = "trip_too_long"


class DomainError(Exception):
    """Base class for business-rule violations."""


class DomainValidationError(DomainError):
    """A single invalid field. Only the first violation is reported."""

    def __init__(self, code: ErrorCode, message: str, field: str | None = None) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.field = field
