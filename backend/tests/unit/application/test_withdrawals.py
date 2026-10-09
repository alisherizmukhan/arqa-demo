from datetime import UTC, datetime, timedelta
from uuid import UUID, uuid4

import pytest

from app.application import withdrawals
from app.application.errors import (
    ForbiddenError,
    InsufficientFundsError,
    NotFoundError,
    WithdrawalAlreadyDecidedError,
    WithdrawalConflictError,
)
from app.domain.errors import DomainValidationError, ErrorCode
from app.domain.user import Role, User
from app.domain.withdrawal import Balance, WithdrawalStatus
from tests.fakes import DRIVER_1, DRIVER_2, InMemoryWithdrawalStore

NOW = datetime(2026, 10, 9, 12, 0, tzinfo=UTC)
ADMIN = User(id=uuid4(), login="admin", role=Role.ADMIN, display_name="Администратор")
DRIVER = User(id=DRIVER_1, login="user_1", role=Role.DRIVER, display_name="Водитель 1")


@pytest.fixture
def store() -> InMemoryWithdrawalStore:
    # The reference trips: user_1 card 2 400, commission 585 → 1 815;
    # user_2 card 3 000, commission 720 → 2 280.
    return InMemoryWithdrawalStore({DRIVER_1: (2400, 585), DRIVER_2: (3000, 720)})


async def _create(
    store: InMemoryWithdrawalStore, amount: int, wid: UUID | None = None, driver: UUID = DRIVER_1
) -> withdrawals.CreateWithdrawalResult:
    return await withdrawals.create_withdrawal(store, driver, wid or uuid4(), amount, NOW)


def test_balance_formula() -> None:
    balance = Balance(card_total=2400, commission_total=585, withdrawn_total=1000)

    assert balance.available == 815


async def test_reference_balances(store: InMemoryWithdrawalStore) -> None:
    assert (await withdrawals.get_balance(store, DRIVER_1)).available == 1815
    assert (await withdrawals.get_balance(store, DRIVER_2)).available == 2280
    assert (await withdrawals.get_balance(store, None)).available == 1815 + 2280


async def test_new_withdrawal_is_pending_and_reserves_the_money(
    store: InMemoryWithdrawalStore,
) -> None:
    result = await _create(store, 1000)

    assert result.created
    assert result.withdrawal.status is WithdrawalStatus.PENDING
    assert store.locked_drivers == [DRIVER_1]  # the balance is read under the lock
    balance = await withdrawals.get_balance(store, DRIVER_1)
    assert (balance.withdrawn_total, balance.available) == (1000, 815)


async def test_same_id_same_amount_is_a_safe_retry(store: InMemoryWithdrawalStore) -> None:
    wid = uuid4()
    first = await _create(store, 1000, wid)
    again = await _create(store, 1000, wid)

    assert first.created
    assert not again.created
    assert again.withdrawal == first.withdrawal
    # Even when the retry would no longer fit the balance: it is the same request.
    assert (await withdrawals.get_balance(store, DRIVER_1)).available == 815


async def test_same_id_other_amount_conflicts(store: InMemoryWithdrawalStore) -> None:
    wid = uuid4()
    await _create(store, 1000, wid)

    with pytest.raises(WithdrawalConflictError):
        await _create(store, 500, wid)


async def test_same_id_from_another_driver_conflicts(store: InMemoryWithdrawalStore) -> None:
    wid = uuid4()
    await _create(store, 1000, wid)

    with pytest.raises(WithdrawalConflictError):
        await _create(store, 1000, wid, driver=DRIVER_2)
    assert len(await withdrawals.list_withdrawals(store, DRIVER_2, None)) == 0


async def test_more_than_available_is_refused(store: InMemoryWithdrawalStore) -> None:
    with pytest.raises(InsufficientFundsError) as exc:
        await _create(store, 1816)

    assert exc.value.available == 1815
    assert not store.withdrawals
    await _create(store, 1815)  # exactly the balance is fine
    with pytest.raises(InsufficientFundsError):
        await _create(store, 1)


@pytest.mark.parametrize("amount", [0, -5])
async def test_amount_must_be_positive(store: InMemoryWithdrawalStore, amount: int) -> None:
    with pytest.raises(DomainValidationError) as exc:
        await _create(store, amount)

    assert exc.value.code is ErrorCode.INVALID_AMOUNT
    assert exc.value.field == "amount"


async def test_approve_is_idempotent_and_keeps_the_money_spent(
    store: InMemoryWithdrawalStore,
) -> None:
    wid = (await _create(store, 1000)).withdrawal.id

    paid = await withdrawals.approve_withdrawal(store, ADMIN, wid, NOW + timedelta(hours=1))
    again = await withdrawals.approve_withdrawal(store, ADMIN, wid, NOW + timedelta(hours=2))

    assert paid.status is WithdrawalStatus.PAID
    assert paid.decided_by == ADMIN.id
    assert store.locked_reads == 2  # each decision reads the row FOR UPDATE
    assert again == paid  # the first decision stays
    assert (await withdrawals.get_balance(store, DRIVER_1)).available == 815


async def test_reject_returns_the_money(store: InMemoryWithdrawalStore) -> None:
    wid = (await _create(store, 1000)).withdrawal.id

    rejected = await withdrawals.reject_withdrawal(store, ADMIN, wid, "  Неверные реквизиты ", NOW)
    again = await withdrawals.reject_withdrawal(store, ADMIN, wid, "другая причина", NOW)

    assert rejected.status is WithdrawalStatus.REJECTED
    assert rejected.reject_reason == "Неверные реквизиты"
    assert again.reject_reason == "Неверные реквизиты"
    assert (await withdrawals.get_balance(store, DRIVER_1)).available == 1815


async def test_deciding_the_other_way_conflicts(store: InMemoryWithdrawalStore) -> None:
    paid = (await _create(store, 500)).withdrawal.id
    rejected = (await _create(store, 500)).withdrawal.id
    await withdrawals.approve_withdrawal(store, ADMIN, paid, NOW)
    await withdrawals.reject_withdrawal(store, ADMIN, rejected, "нет", NOW)

    with pytest.raises(WithdrawalAlreadyDecidedError):
        await withdrawals.reject_withdrawal(store, ADMIN, paid, "поздно", NOW)
    with pytest.raises(WithdrawalAlreadyDecidedError):
        await withdrawals.approve_withdrawal(store, ADMIN, rejected, NOW)


@pytest.mark.parametrize("reason", ["", "   "])
async def test_reject_needs_a_reason(store: InMemoryWithdrawalStore, reason: str) -> None:
    wid = (await _create(store, 500)).withdrawal.id

    with pytest.raises(DomainValidationError) as exc:
        await withdrawals.reject_withdrawal(store, ADMIN, wid, reason, NOW)

    assert exc.value.field == "reason"
    assert store.withdrawals[wid].status is WithdrawalStatus.PENDING


async def test_only_admins_decide_and_unknown_ids_are_404(store: InMemoryWithdrawalStore) -> None:
    wid = (await _create(store, 500)).withdrawal.id

    with pytest.raises(ForbiddenError):
        await withdrawals.approve_withdrawal(store, DRIVER, wid, NOW)
    with pytest.raises(NotFoundError):
        await withdrawals.approve_withdrawal(store, ADMIN, uuid4(), NOW)


async def test_list_is_newest_first_and_filters(store: InMemoryWithdrawalStore) -> None:
    older = await withdrawals.create_withdrawal(store, DRIVER_1, uuid4(), 100, NOW)
    newer = await withdrawals.create_withdrawal(
        store, DRIVER_1, uuid4(), 200, NOW + timedelta(minutes=1)
    )
    await withdrawals.approve_withdrawal(store, ADMIN, older.withdrawal.id, NOW)

    listed = await withdrawals.list_withdrawals(store, DRIVER_1, None)
    pending = await withdrawals.list_withdrawals(store, DRIVER_1, WithdrawalStatus.PENDING)

    assert [w.amount for w in listed] == [200, 100]
    assert [w.id for w in pending] == [newer.withdrawal.id]
