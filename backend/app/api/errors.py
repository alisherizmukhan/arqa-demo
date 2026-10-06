"""One error shape for everything: {"error": {"code", "message", "field"}}."""

import logging
from enum import StrEnum
from typing import Any

from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.api.schemas import ErrorBody, ErrorResponse
from app.application.errors import TripConflictError
from app.domain.errors import DomainValidationError, ErrorCode

logger = logging.getLogger(__name__)


class ApiErrorCode(StrEnum):
    MISSING_FIELD = "missing_field"
    UNKNOWN_FIELD = "unknown_field"
    INVALID_TYPE = "invalid_type"
    INVALID_DATETIME = "invalid_datetime"
    INVALID_DATE = "invalid_date"
    INVALID_JSON = "invalid_json"
    INVALID_REQUEST = "invalid_request"
    TRIP_CONFLICT = "trip_conflict"
    NOT_FOUND = "not_found"
    METHOD_NOT_ALLOWED = "method_not_allowed"
    HTTP_ERROR = "http_error"
    DATABASE_UNAVAILABLE = "database_unavailable"
    INTERNAL_ERROR = "internal_error"


class ApiError(Exception):
    def __init__(self, status_code: int, code: str, message: str, field: str | None = None) -> None:
        super().__init__(message)
        self.status_code = status_code
        self.code = code
        self.message = message
        self.field = field


def error_response(
    status_code: int, code: str, message: str, field: str | None = None
) -> JSONResponse:
    body = ErrorResponse(error=ErrorBody(code=code, message=message, field=field))
    return JSONResponse(status_code=status_code, content=body.model_dump())


# Pydantic error type -> our code. Field-specific overrides below.
_PYDANTIC_CODES: dict[str, str] = {
    "missing": ApiErrorCode.MISSING_FIELD,
    "extra_forbidden": ApiErrorCode.UNKNOWN_FIELD,
    "json_invalid": ApiErrorCode.INVALID_JSON,
    "timezone_aware": ErrorCode.NAIVE_DATETIME,
    "datetime_type": ApiErrorCode.INVALID_DATETIME,
    "datetime_parsing": ApiErrorCode.INVALID_DATETIME,
    "datetime_from_date_parsing": ApiErrorCode.INVALID_DATETIME,
    "int_type": ApiErrorCode.INVALID_TYPE,
    "int_parsing": ApiErrorCode.INVALID_TYPE,
    "int_from_float": ApiErrorCode.INVALID_TYPE,
    "string_type": ApiErrorCode.INVALID_TYPE,
    "enum": ErrorCode.INVALID_PAYMENT,
}
_FIELD_CODES: dict[str, str] = {"id": ErrorCode.INVALID_ID, "payment": ErrorCode.INVALID_PAYMENT}


def _from_pydantic_error(error: dict[str, Any]) -> tuple[str, str, str | None]:
    loc = [str(part) for part in error.get("loc", ())]
    # loc is ("body", "amount") or ("query", "date"); a bare ("body",) has no field.
    field = ".".join(loc[1:]) if len(loc) > 1 and error["type"] != "json_invalid" else None
    code = _PYDANTIC_CODES.get(error["type"])
    if code is None or (code == ApiErrorCode.INVALID_TYPE and field in _FIELD_CODES):
        code = _FIELD_CODES.get(field or "", ApiErrorCode.INVALID_REQUEST)
    return code, str(error.get("msg", "invalid request")), field


def install_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(RequestValidationError)
    async def _request_validation(_: Request, exc: RequestValidationError) -> JSONResponse:
        errors = list(exc.errors())
        code, message, field = (
            _from_pydantic_error(errors[0])
            if errors
            else (ApiErrorCode.INVALID_REQUEST, "invalid request", None)
        )
        return error_response(status.HTTP_422_UNPROCESSABLE_CONTENT, code, message, field)

    @app.exception_handler(DomainValidationError)
    async def _domain_validation(_: Request, exc: DomainValidationError) -> JSONResponse:
        return error_response(
            status.HTTP_422_UNPROCESSABLE_CONTENT, exc.code, exc.message, exc.field
        )

    @app.exception_handler(TripConflictError)
    async def _conflict(_: Request, exc: TripConflictError) -> JSONResponse:
        return error_response(
            status.HTTP_409_CONFLICT, ApiErrorCode.TRIP_CONFLICT, str(exc), field="id"
        )

    @app.exception_handler(ApiError)
    async def _api_error(_: Request, exc: ApiError) -> JSONResponse:
        return error_response(exc.status_code, exc.code, exc.message, exc.field)

    @app.exception_handler(StarletteHTTPException)
    async def _http(_: Request, exc: StarletteHTTPException) -> JSONResponse:
        code = {
            status.HTTP_404_NOT_FOUND: ApiErrorCode.NOT_FOUND,
            status.HTTP_405_METHOD_NOT_ALLOWED: ApiErrorCode.METHOD_NOT_ALLOWED,
        }.get(exc.status_code, ApiErrorCode.HTTP_ERROR)
        response = error_response(exc.status_code, code, str(exc.detail))
        if exc.headers:
            response.headers.update(exc.headers)
        return response

    @app.exception_handler(Exception)
    async def _unhandled(_: Request, exc: Exception) -> JSONResponse:
        logger.exception("unhandled error", exc_info=exc)
        return error_response(
            status.HTTP_500_INTERNAL_SERVER_ERROR,
            ApiErrorCode.INTERNAL_ERROR,
            "internal server error",
        )
