from datetime import UTC, datetime, timedelta
from uuid import UUID

from sqlalchemy import case, delete, select, update
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.application.ports import ActiveSession, OwnedTrip
from app.domain.geo import GeoPoint, Place
from app.domain.route import RouteStatus, TripRoute
from app.domain.trip import PaymentMethod, Trip
from app.domain.user import Role, User
from app.infrastructure.models import LoginFailureRow, SessionRow, TripRow, UserRow


class SqlTripRepository:
    """Trips of one driver ([driver_id]), or of all drivers when it is None.

    Inserts need a driver: the new trip belongs to it. `get` looks the id up
    across all drivers, because trip ids are globally unique.
    """

    def __init__(self, session: AsyncSession, driver_id: UUID | None = None) -> None:
        self._session = session
        self._driver_id = driver_id

    async def list_started_between(self, start: datetime, end: datetime) -> list[OwnedTrip]:
        stmt = (
            select(TripRow)
            .where(TripRow.start_at >= start, TripRow.start_at < end)
            .order_by(TripRow.start_at, TripRow.id)
        )
        if self._driver_id is not None:
            stmt = stmt.where(TripRow.driver_id == self._driver_id)
        return [_owned(row) for row in await self._session.scalars(stmt)]

    async def get(self, trip_id: str) -> OwnedTrip | None:
        row = await self._session.scalar(select(TripRow).where(TripRow.id == trip_id))
        return None if row is None else _owned(row)

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
                **_place_columns(trip.pickup, trip.dropoff),
                route_status=(RouteStatus.PENDING if trip.has_places else RouteStatus.NONE).value,
            )
            .on_conflict_do_nothing(index_elements=[TripRow.id])
            .returning(TripRow.id)
        )
        inserted_id = await self._session.scalar(stmt)
        await self._session.commit()
        return inserted_id is not None

    async def save_route(self, trip_id: str, route: TripRoute) -> None:
        await self._session.execute(
            update(TripRow)
            .where(TripRow.id == trip_id)
            .values(
                route_status=route.status.value,
                route_polyline=route.polyline,
                route_distance_m=route.distance_m,
                route_duration_s=route.duration_s,
            )
        )
        await self._session.commit()

    async def list_pending_routes(self, limit: int) -> list[OwnedTrip]:
        stmt = (
            select(TripRow)
            .where(TripRow.route_status == RouteStatus.PENDING.value)
            .order_by(TripRow.created_at, TripRow.id)
            .limit(limit)
        )
        return [_owned(row) for row in await self._session.scalars(stmt)]

    async def set_places_if_missing(self, trip_id: str, pickup: Place, dropoff: Place) -> bool:
        if self._driver_id is None:
            raise ValueError("places can only be set on a driver's trip")
        changed = await self._session.scalar(
            update(TripRow)
            .where(
                TripRow.id == trip_id,
                TripRow.driver_id == self._driver_id,
                TripRow.pickup_lat.is_(None),
            )
            .values(**_place_columns(pickup, dropoff), route_status=RouteStatus.PENDING.value)
            .returning(TripRow.id)
        )
        await self._session.commit()
        return changed is not None


class SqlUserRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get(self, user_id: UUID) -> User | None:
        row = await self._session.scalar(select(UserRow).where(UserRow.id == user_id))
        return None if row is None else _user_to_domain(row)

    async def list_all(self) -> list[User]:
        drivers_first = case((UserRow.role == Role.DRIVER.value, 0), else_=1)
        rows = await self._session.scalars(select(UserRow).order_by(drivers_first, UserRow.login))
        return [_user_to_domain(row) for row in rows]

    async def set_active(self, user_id: UUID, is_active: bool) -> User | None:
        row = await self._session.scalar(
            update(UserRow)
            .where(UserRow.id == user_id)
            .values(is_active=is_active)
            .returning(UserRow)
        )
        await self._session.commit()
        return None if row is None else _user_to_domain(row)

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


def _place_columns(pickup: Place | None, dropoff: Place | None) -> dict[str, object]:
    return {
        "pickup_lat": pickup.point.lat if pickup else None,
        "pickup_lng": pickup.point.lng if pickup else None,
        "pickup_label": pickup.label if pickup else None,
        "dropoff_lat": dropoff.point.lat if dropoff else None,
        "dropoff_lng": dropoff.point.lng if dropoff else None,
        "dropoff_label": dropoff.label if dropoff else None,
    }


def _place(lat: float | None, lng: float | None, label: str | None) -> Place | None:
    if lat is None or lng is None:
        return None
    return Place(point=GeoPoint(lat, lng), label=label)


def _to_domain(row: TripRow) -> Trip:
    return Trip(
        id=row.id,
        start=row.start_at,
        end=row.end_at,
        amount=row.amount,
        payment=PaymentMethod(row.payment),
        commission=row.commission,
        pickup=_place(row.pickup_lat, row.pickup_lng, row.pickup_label),
        dropoff=_place(row.dropoff_lat, row.dropoff_lng, row.dropoff_label),
    )


def _owned(row: TripRow) -> OwnedTrip:
    return OwnedTrip(
        trip=_to_domain(row),
        driver_id=row.driver_id,
        route=TripRoute(
            status=RouteStatus(row.route_status),
            polyline=row.route_polyline,
            distance_m=row.route_distance_m,
            duration_s=row.route_duration_s,
        ),
    )


class SqlSessionRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def create(self, *, user_id: UUID, token_hash: str, user_agent: str | None) -> None:
        self._session.add(SessionRow(user_id=user_id, token_hash=token_hash, user_agent=user_agent))
        await self._session.commit()

    async def find_active(self, token_hash: str) -> ActiveSession | None:
        found = (
            await self._session.execute(
                select(SessionRow, UserRow)
                .join(UserRow, UserRow.id == SessionRow.user_id)
                .where(SessionRow.token_hash == token_hash, SessionRow.revoked_at.is_(None))
            )
        ).first()
        if found is None:
            return None
        session_row, user_row = found
        return ActiveSession(
            session_id=session_row.id,
            user=_user_to_domain(user_row),
            last_used_at=session_row.last_used_at,
        )

    async def touch(self, session_id: UUID, now: datetime) -> None:
        await self._session.execute(
            update(SessionRow).where(SessionRow.id == session_id).values(last_used_at=now)
        )
        await self._session.commit()

    async def revoke(self, token_hash: str, now: datetime) -> None:
        await self._session.execute(
            update(SessionRow)
            .where(SessionRow.token_hash == token_hash, SessionRow.revoked_at.is_(None))
            .values(revoked_at=now)
        )
        await self._session.commit()

    async def revoke_all(self, user_id: UUID, now: datetime) -> int:
        revoked = await self._session.scalars(
            update(SessionRow)
            .where(SessionRow.user_id == user_id, SessionRow.revoked_at.is_(None))
            .values(revoked_at=now)
            .returning(SessionRow.id)
        )
        count = len(revoked.all())
        await self._session.commit()
        return count


class SqlLoginAttemptRepository:
    def __init__(self, session: AsyncSession, window: timedelta) -> None:
        self._session = session
        self._window = window

    async def failures_since(self, login: str, client_ip: str, since: datetime) -> list[datetime]:
        rows = await self._session.scalars(
            select(LoginFailureRow.attempted_at)
            .where(
                LoginFailureRow.login == login,
                LoginFailureRow.client_ip == client_ip,
                LoginFailureRow.attempted_at > since,
            )
            .order_by(LoginFailureRow.attempted_at)
        )
        return list(rows)

    async def record_failure(self, login: str, client_ip: str, now: datetime) -> None:
        # Keep the table small: rows outside the window no longer matter.
        await self._session.execute(
            delete(LoginFailureRow).where(LoginFailureRow.attempted_at <= now - self._window)
        )
        self._session.add(LoginFailureRow(login=login, client_ip=client_ip, attempted_at=now))
        await self._session.commit()


def _user_to_domain(row: UserRow) -> User:
    return User(
        id=row.id,
        login=row.login,
        role=Role(row.role),
        display_name=row.display_name,
        is_active=row.is_active,
    )
