"""Balance and withdrawals (вывод денег)."""

from typing import Annotated, Any
from uuid import UUID

from fastapi import APIRouter, Query, Response, status

from app.api.deps import CurrentUserDep, NowDep, SessionDep
from app.api.routes import AUTH_ERRORS
from app.api.schemas import (
    BalanceOut,
    ErrorResponse,
    RejectIn,
    WithdrawalIn,
    WithdrawalOut,
    error_example,
)
from app.application import access, withdrawals
from app.domain.withdrawal import WithdrawalStatus
from app.infrastructure.repository import SqlUserRepository
from app.infrastructure.withdrawals import SqlWithdrawalStore

router = APIRouter()

_VALIDATION: dict[int | str, dict[str, Any]] = {
    status.HTTP_422_UNPROCESSABLE_CONTENT: {
        "model": ErrorResponse,
        "description": "Validation error",
    }
}
_READ_ERRORS: dict[int | str, dict[str, Any]] = {
    **AUTH_ERRORS,
    **error_example(
        status.HTTP_403_FORBIDDEN,
        "A driver passed driver_id",
        "forbidden",
        "drivers cannot choose a driver_id",
    ),
    **error_example(
        status.HTTP_404_NOT_FOUND,
        "Admin: driver_id is not a driver",
        "not_found",
        "driver … not found",
    ),
    **_VALIDATION,
}
_DECIDE_ERRORS: dict[int | str, dict[str, Any]] = {
    **AUTH_ERRORS,
    **error_example(status.HTTP_403_FORBIDDEN, "Not an admin", "forbidden", "admin only"),
    **error_example(
        status.HTTP_404_NOT_FOUND, "No such withdrawal", "not_found", "withdrawal … not found"
    ),
    **error_example(
        status.HTTP_409_CONFLICT,
        "Already decided the other way (paid vs rejected)",
        "withdrawal_already_decided",
        "withdrawal … is already paid",
    ),
    **_VALIDATION,
}

DriverIdQuery = Annotated[
    UUID | None,
    Query(description="Admin only: one driver. Absent: all drivers. Drivers: 403."),
]


@router.get("/balance", tags=["withdrawals"], responses=_READ_ERRORS)
async def balance(
    session: SessionDep, actor: CurrentUserDep, driver_id: DriverIdQuery = None
) -> BalanceOut:
    """What the park owes the driver: Σ card - Σ commission (all trips) -
    Σ withdrawals pending or paid. Can be zero or negative. An admin gets one
    driver (`driver_id`) or the sum over all drivers."""
    scope = await access.trip_scope(SqlUserRepository(session), actor, driver_id)
    result = await withdrawals.get_balance(SqlWithdrawalStore(session), scope)
    return BalanceOut.from_domain(result)


@router.get("/withdrawals", tags=["withdrawals"], responses=_READ_ERRORS)
async def list_withdrawals(
    session: SessionDep,
    actor: CurrentUserDep,
    driver_id: DriverIdQuery = None,
    status_filter: Annotated[
        WithdrawalStatus | None, Query(alias="status", description="Only this status")
    ] = None,
) -> list[WithdrawalOut]:
    """Withdrawals, newest first: the driver's own, or (admin) all / one driver's."""
    scope = await access.trip_scope(SqlUserRepository(session), actor, driver_id)
    found = await withdrawals.list_withdrawals(SqlWithdrawalStore(session), scope, status_filter)
    return [WithdrawalOut.from_domain(w) for w in found]


@router.post(
    "/withdrawals",
    tags=["withdrawals"],
    status_code=status.HTTP_201_CREATED,
    responses={
        status.HTTP_201_CREATED: {"description": "Created (pending)"},
        status.HTTP_200_OK: {
            "model": WithdrawalOut,
            "description": "Already exists with the same amount (safe retry); nothing created",
        },
        **error_example(
            status.HTTP_409_CONFLICT,
            "This id already exists with another amount, or belongs to another driver",
            "withdrawal_conflict",
            "withdrawal 5b7f3a2e-… already exists with a different amount",
        ),
        **error_example(
            status.HTTP_422_UNPROCESSABLE_CONTENT,
            "Amount above the available balance (also: amount <= 0, wrong types)",
            "insufficient_funds",
            "amount is more than the available balance (1815)",
        ),
        **AUTH_ERRORS,
        **error_example(
            status.HTTP_403_FORBIDDEN, "Not a driver", "forbidden", "only drivers can do this"
        ),
    },
)
async def create_withdrawal(
    body: WithdrawalIn, response: Response, session: SessionDep, actor: CurrentUserDep, now: NowDep
) -> WithdrawalOut:
    """Ask for a payout. Idempotent by `id`: the same id and amount return the
    stored withdrawal (200) — a retry after a lost response never pays twice.
    The driver's row is locked while the balance is checked, so two requests
    together cannot spend more than the balance."""
    driver_id = access.require_driver(actor)
    result = await withdrawals.create_withdrawal(
        SqlWithdrawalStore(session), driver_id, body.id, body.amount, now
    )
    response.status_code = status.HTTP_201_CREATED if result.created else status.HTTP_200_OK
    return WithdrawalOut.from_domain(result.withdrawal)


@router.post("/admin/withdrawals/{withdrawal_id}/approve", tags=["admin"], responses=_DECIDE_ERRORS)
async def approve(
    withdrawal_id: UUID, session: SessionDep, actor: CurrentUserDep, now: NowDep
) -> WithdrawalOut:
    """Mark as paid. Repeating returns the paid withdrawal."""
    decided = await withdrawals.approve_withdrawal(
        SqlWithdrawalStore(session), actor, withdrawal_id, now
    )
    return WithdrawalOut.from_domain(decided)


@router.post("/admin/withdrawals/{withdrawal_id}/reject", tags=["admin"], responses=_DECIDE_ERRORS)
async def reject(
    withdrawal_id: UUID, body: RejectIn, session: SessionDep, actor: CurrentUserDep, now: NowDep
) -> WithdrawalOut:
    """Reject with a reason (required); the money is available again. Repeating
    returns the rejected withdrawal."""
    decided = await withdrawals.reject_withdrawal(
        SqlWithdrawalStore(session), actor, withdrawal_id, body.reason, now
    )
    return WithdrawalOut.from_domain(decided)
