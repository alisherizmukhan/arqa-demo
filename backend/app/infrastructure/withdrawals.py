from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from uuid import UUID

from sqlalchemy import func, select, update
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.trip import PaymentMethod
from app.domain.withdrawal import RESERVED_STATUSES, Balance, Withdrawal, WithdrawalStatus
from app.infrastructure.models import TripRow, UserRow, WithdrawalRow


async def _balance(session: AsyncSession, driver_id: UUID | None) -> Balance:
    trips = select(
        func.coalesce(
            func.sum(TripRow.amount).filter(TripRow.payment == PaymentMethod.CARD.value), 0
        ),
        func.coalesce(func.sum(TripRow.commission), 0),
    )
    withdrawn = select(func.coalesce(func.sum(WithdrawalRow.amount), 0)).where(
        WithdrawalRow.status.in_([s.value for s in RESERVED_STATUSES])
    )
    if driver_id is not None:
        trips = trips.where(TripRow.driver_id == driver_id)
        withdrawn = withdrawn.where(WithdrawalRow.driver_id == driver_id)
    card_total, commission_total = (await session.execute(trips)).one()
    withdrawn_total = await session.scalar(withdrawn)
    return Balance(
        card_total=int(card_total),
        commission_total=int(commission_total),
        withdrawn_total=int(withdrawn_total or 0),
    )


class SqlWithdrawalTransaction:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def lock_driver(self, driver_id: UUID) -> None:
        await self._session.execute(
            select(UserRow.id).where(UserRow.id == driver_id).with_for_update()
        )

    async def get(self, withdrawal_id: UUID, *, for_update: bool = False) -> Withdrawal | None:
        stmt = select(WithdrawalRow).where(WithdrawalRow.id == withdrawal_id)
        if for_update:
            stmt = stmt.with_for_update()
        # populate_existing: inside a transaction that waited for a lock, read
        # the row as committed now, not as this session may have cached it.
        row = await self._session.scalar(stmt.execution_options(populate_existing=True))
        return None if row is None else _to_domain(row)

    async def balance(self, driver_id: UUID) -> Balance:
        return await _balance(self._session, driver_id)

    async def insert_if_absent(self, withdrawal: Withdrawal) -> bool:
        inserted = await self._session.scalar(
            insert(WithdrawalRow)
            .values(
                id=withdrawal.id,
                driver_id=withdrawal.driver_id,
                amount=withdrawal.amount,
                status=withdrawal.status.value,
                created_at=withdrawal.created_at,
            )
            .on_conflict_do_nothing(index_elements=[WithdrawalRow.id])
            .returning(WithdrawalRow.id)
        )
        return inserted is not None

    async def save_decision(self, withdrawal: Withdrawal) -> None:
        await self._session.execute(
            update(WithdrawalRow)
            .where(WithdrawalRow.id == withdrawal.id)
            .values(
                status=withdrawal.status.value,
                reject_reason=withdrawal.reject_reason,
                decided_at=withdrawal.decided_at,
                decided_by=withdrawal.decided_by,
            )
        )


class SqlWithdrawalStore:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    @asynccontextmanager
    async def transaction(self) -> AsyncIterator[SqlWithdrawalTransaction]:
        # The request's session may already be in a transaction (it read the
        # signed-in user); end it so the locks below live in a fresh one.
        await self._session.commit()
        try:
            yield SqlWithdrawalTransaction(self._session)
        except BaseException:
            await self._session.rollback()
            raise
        await self._session.commit()

    async def balance(self, driver_id: UUID | None) -> Balance:
        return await _balance(self._session, driver_id)

    async def list(
        self, driver_id: UUID | None, status: WithdrawalStatus | None
    ) -> list[Withdrawal]:
        stmt = select(WithdrawalRow).order_by(WithdrawalRow.created_at.desc(), WithdrawalRow.id)
        if driver_id is not None:
            stmt = stmt.where(WithdrawalRow.driver_id == driver_id)
        if status is not None:
            stmt = stmt.where(WithdrawalRow.status == status.value)
        return [_to_domain(row) for row in await self._session.scalars(stmt)]


def _to_domain(row: WithdrawalRow) -> Withdrawal:
    return Withdrawal(
        id=row.id,
        driver_id=row.driver_id,
        amount=row.amount,
        status=WithdrawalStatus(row.status),
        created_at=row.created_at,
        reject_reason=row.reject_reason,
        decided_at=row.decided_at,
        decided_by=row.decided_by,
    )
