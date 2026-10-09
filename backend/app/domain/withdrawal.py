"""Withdrawals (вывод денег) and the driver's available balance.

Card payments go to the park; cash stays with the driver; the park's commission
is owed on all trips. So what the park owes the driver is

    available = Σ card amounts - Σ commissions (all trips)
                - Σ withdrawals that are pending or paid

It can be zero or negative (nothing to withdraw). A rejected withdrawal no
longer counts: its money is available again. Integers only (tenge).
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum
from uuid import UUID

from app.domain.errors import DomainValidationError, ErrorCode
from app.domain.trip import MAX_AMOUNT

MAX_REJECT_REASON = 500


class WithdrawalStatus(StrEnum):
    PENDING = "pending"
    PAID = "paid"
    REJECTED = "rejected"


# Statuses whose amount is no longer available to the driver.
RESERVED_STATUSES = (WithdrawalStatus.PENDING, WithdrawalStatus.PAID)


@dataclass(frozen=True, slots=True, kw_only=True)
class Withdrawal:
    id: UUID
    driver_id: UUID
    amount: int
    status: WithdrawalStatus
    created_at: datetime
    reject_reason: str | None = None
    decided_at: datetime | None = None
    decided_by: UUID | None = None


@dataclass(frozen=True, slots=True, kw_only=True)
class Balance:
    card_total: int
    commission_total: int
    withdrawn_total: int

    @property
    def available(self) -> int:
        return self.card_total - self.commission_total - self.withdrawn_total


def validate_withdrawal_amount(amount: int) -> None:
    if type(amount) is not int or amount <= 0:
        raise DomainValidationError(
            ErrorCode.INVALID_AMOUNT, "amount must be a positive integer", field="amount"
        )
    if amount > MAX_AMOUNT:
        raise DomainValidationError(
            ErrorCode.AMOUNT_TOO_LARGE, f"amount must not exceed {MAX_AMOUNT}", field="amount"
        )


def validate_reject_reason(reason: str) -> str:
    cleaned = reason.strip()
    if not cleaned:
        raise DomainValidationError(
            ErrorCode.INVALID_REASON, "a reason is required to reject", field="reason"
        )
    if len(cleaned) > MAX_REJECT_REASON:
        raise DomainValidationError(
            ErrorCode.INVALID_REASON,
            f"reason must be at most {MAX_REJECT_REASON} characters",
            field="reason",
        )
    return cleaned
