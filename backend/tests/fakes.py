from dataclasses import replace
from datetime import UTC, datetime
from uuid import UUID, uuid4

from app.application.ports import ActiveSession, OwnedTrip
from app.domain.trip import Trip
from app.domain.user import Role, User

DRIVER_1 = UUID("00000000-0000-4000-8000-000000000001")
DRIVER_2 = UUID("00000000-0000-4000-8000-000000000002")


class InMemoryTripRepository:
    """TripRepository for unit tests: one driver's view of a store that
    `for_driver` shares with other drivers. Not concurrency-safe; the real
    guarantee comes from the database and is covered by integration tests."""

    def __init__(
        self,
        trips: list[Trip] | None = None,
        driver_id: UUID = DRIVER_1,
        store: dict[str, OwnedTrip] | None = None,
    ) -> None:
        self._store: dict[str, OwnedTrip] = store if store is not None else {}
        self.driver_id = driver_id
        for trip in trips or []:
            self._store[trip.id] = OwnedTrip(trip=trip, driver_id=driver_id)

    def for_driver(self, driver_id: UUID) -> "InMemoryTripRepository":
        return InMemoryTripRepository(driver_id=driver_id, store=self._store)

    @property
    def trips(self) -> dict[str, Trip]:
        """All stored trips by id (any driver)."""
        return {trip_id: owned.trip for trip_id, owned in self._store.items()}

    async def list_started_between(self, start: datetime, end: datetime) -> list[Trip]:
        found = [
            owned.trip
            for owned in self._store.values()
            if owned.driver_id == self.driver_id and start <= owned.trip.start < end
        ]
        return sorted(found, key=lambda t: (t.start, t.id))

    async def get(self, trip_id: str) -> OwnedTrip | None:
        return self._store.get(trip_id)

    async def insert_if_absent(self, trip: Trip) -> bool:
        if trip.id in self._store:
            return False
        self._store[trip.id] = OwnedTrip(trip=trip, driver_id=self.driver_id)
        return True

    async def count(self) -> int:
        """Test helper (not part of the port): this driver's trips."""
        return sum(1 for owned in self._store.values() if owned.driver_id == self.driver_id)


class InMemoryUserRepository:
    def __init__(self) -> None:
        self.users: dict[str, User] = {}
        self.hashes: dict[str, str] = {}

    async def get(self, user_id: UUID) -> User | None:
        return next((u for u in self.users.values() if u.id == user_id), None)

    async def get_by_login(self, login: str) -> User | None:
        return self.users.get(login)

    async def list_all(self) -> list[User]:
        return sorted(self.users.values(), key=lambda u: (u.role is not Role.DRIVER, u.login))

    async def password_hash(self, login: str) -> str | None:
        return self.hashes.get(login)

    async def insert_if_absent(
        self, *, login: str, password_hash: str, role: Role, display_name: str
    ) -> bool:
        if login in self.users:
            return False
        self.users[login] = User(id=uuid4(), login=login, role=role, display_name=display_name)
        self.hashes[login] = password_hash
        return True

    async def set_password_hash(self, login: str, password_hash: str) -> None:
        self.hashes[login] = password_hash

    async def set_active(self, user_id: UUID, is_active: bool) -> User | None:
        user = await self.get(user_id)
        if user is None:
            return None
        self.users[user.login] = replace(user, is_active=is_active)
        return self.users[user.login]


class InMemorySessionRepository:
    def __init__(self, users: InMemoryUserRepository) -> None:
        self._users = users
        # token_hash -> (session id, user id, last used, revoked at)
        self.rows: dict[str, tuple[UUID, UUID, datetime, datetime | None]] = {}
        self.user_agents: dict[str, str | None] = {}
        self.now = datetime(2026, 10, 9, 12, 0, tzinfo=UTC)

    async def create(self, *, user_id: UUID, token_hash: str, user_agent: str | None) -> None:
        self.rows[token_hash] = (uuid4(), user_id, self.now, None)
        self.user_agents[token_hash] = user_agent

    async def find_active(self, token_hash: str) -> ActiveSession | None:
        row = self.rows.get(token_hash)
        if row is None or row[3] is not None:
            return None
        user = await self._users.get(row[1])
        assert user is not None
        return ActiveSession(session_id=row[0], user=user, last_used_at=row[2])

    async def touch(self, session_id: UUID, now: datetime) -> None:
        for token_hash, row in self.rows.items():
            if row[0] == session_id:
                self.rows[token_hash] = (row[0], row[1], now, row[3])

    async def revoke(self, token_hash: str, now: datetime) -> None:
        row = self.rows.get(token_hash)
        if row is not None and row[3] is None:
            self.rows[token_hash] = (row[0], row[1], row[2], now)

    async def revoke_all(self, user_id: UUID, now: datetime) -> int:
        count = 0
        for token_hash, row in list(self.rows.items()):
            if row[1] == user_id and row[3] is None:
                self.rows[token_hash] = (row[0], row[1], row[2], now)
                count += 1
        return count


class InMemoryLoginAttempts:
    def __init__(self) -> None:
        self.failures: dict[str, list[datetime]] = {}

    async def failures_since(self, login: str, since: datetime) -> list[datetime]:
        return sorted(t for t in self.failures.get(login, []) if t > since)

    async def record_failure(self, login: str, now: datetime) -> None:
        self.failures.setdefault(login, []).append(now)


class PlainTextHasher:
    """Readable, instant 'hash' for unit tests (argon2 is covered elsewhere)."""

    def __init__(self) -> None:
        self.dummy_checks = 0

    def hash(self, password: str) -> str:
        return f"plain:{password}"

    def verify(self, password_hash: str, password: str) -> bool:
        if password_hash == self.dummy_hash():
            self.dummy_checks += 1
        return password_hash == f"plain:{password}"

    def dummy_hash(self) -> str:
        return "plain-dummy"
