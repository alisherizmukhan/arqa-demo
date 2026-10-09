from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import select, update
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.trip import PaymentMethod, Trip
from app.domain.user import Role, User
from app.infrastructure.models import TripRow, UserRow


class SqlTripRepository:
    """Trips of one driver ([driver_id]), or of all drivers when it is None.

    Inserts need a driver: the new trip belongs to it. `get` looks the id up
    across all drivers, because trip ids are globally unique.
    """

    def __init__(self, session: AsyncSession, driver_id: UUID | None = None) -> None:
        self._session = session
        self._driver_id = driver_id

    async def list_started_between(self, start: datetime, end: datetime) -> list[Trip]:
        stmt = (
            select(TripRow)
            .where(TripRow.start_at >= start, TripRow.start_at < end)
            .order_by(TripRow.start_at, TripRow.id)
        )
        if self._driver_id is not None:
            stmt = stmt.where(TripRow.driver_id == self._driver_id)
        return [_to_domain(row) for row in await self._session.scalars(stmt)]

    async def get(self, trip_id: str) -> Trip | None:
        row = await self._session.scalar(select(TripRow).where(TripRow.id == trip_id))
        return None if row is None else _to_domain(row)

    async def insert_if_absent(self, trip: Trip) -> bool:
        # INSERT ... ON CONFLICT DO NOTHING: the primary key decides, atomically.
        # A concurrent insert of the same id waits for the first transaction and
        # then inserts nothing, so the caller can read and compare the winner.
        if self._driver_id is None:
            raise ValueError("a trip can only be inserted for a driver")
        stmt = (
            insert(TripRow)
            .values(
                id=trip.id,
                driver_id=self._driver_id,
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


class SqlUserRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_by_login(self, login: str) -> User | None:
        row = await self._session.scalar(select(UserRow).where(UserRow.login == login))
        return None if row is None else _user_to_domain(row)

    async def password_hash(self, login: str) -> str | None:
        return await self._session.scalar(
            select(UserRow.password_hash).where(UserRow.login == login)
        )

    async def insert_if_absent(
        self, *, login: str, password_hash: str, role: Role, display_name: str
    ) -> bool:
        stmt = (
            insert(UserRow)
            .values(
                login=login,
                password_hash=password_hash,
                role=role.value,
                display_name=display_name,
            )
            .on_conflict_do_nothing(index_elements=[UserRow.login])
            .returning(UserRow.id)
        )
        inserted_id = await self._session.scalar(stmt)
        await self._session.commit()
        return inserted_id is not None

    async def set_password_hash(self, login: str, password_hash: str) -> None:
        await self._session.execute(
            update(UserRow).where(UserRow.login == login).values(password_hash=password_hash)
        )
        await self._session.commit()


def _to_domain(row: TripRow) -> Trip:
    return Trip(
        id=row.id,
        start=row.start_at,
        end=row.end_at,
        amount=row.amount,
        payment=PaymentMethod(row.payment),
        commission=row.commission,
    )


def _user_to_domain(row: UserRow) -> User:
    return User(
        id=row.id,
        login=row.login,
        role=Role(row.role),
        display_name=row.display_name,
        is_active=row.is_active,
    )
