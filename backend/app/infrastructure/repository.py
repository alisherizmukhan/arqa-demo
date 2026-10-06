from datetime import UTC, datetime

from sqlalchemy import func, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.trip import PaymentMethod, Trip
from app.infrastructure.models import TripRow


class SqlTripRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def list_started_between(self, start: datetime, end: datetime) -> list[Trip]:
        stmt = (
            select(TripRow)
            .where(TripRow.start_at >= start, TripRow.start_at < end)
            .order_by(TripRow.start_at, TripRow.id)
        )
        return [_to_domain(row) for row in await self._session.scalars(stmt)]

    async def get(self, trip_id: str) -> Trip | None:
        row = await self._session.scalar(select(TripRow).where(TripRow.id == trip_id))
        return None if row is None else _to_domain(row)

    async def insert_if_absent(self, trip: Trip) -> bool:
        # INSERT ... ON CONFLICT DO NOTHING: the primary key decides, atomically.
        # A concurrent insert of the same id waits for the first transaction and
        # then inserts nothing, so the caller can read and compare the winner.
        stmt = (
            insert(TripRow)
            .values(
                id=trip.id,
                start_at=trip.start.astimezone(UTC),
                end_at=trip.end.astimezone(UTC),
                amount=trip.amount,
                payment=trip.payment.value,
                commission=trip.commission,
            )
            .on_conflict_do_nothing(index_elements=[TripRow.id])
            .returning(TripRow.id)
        )
        inserted_id = await self._session.scalar(stmt)
        await self._session.commit()
        return inserted_id is not None

    async def count(self) -> int:
        return await self._session.scalar(select(func.count()).select_from(TripRow)) or 0


def _to_domain(row: TripRow) -> Trip:
    return Trip(
        id=row.id,
        start=row.start_at,
        end=row.end_at,
        amount=row.amount,
        payment=PaymentMethod(row.payment),
        commission=row.commission,
    )
