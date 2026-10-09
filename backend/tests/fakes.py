from datetime import datetime
from uuid import uuid4

from app.domain.trip import Trip
from app.domain.user import Role, User


class InMemoryTripRepository:
    """TripRepository for unit tests. Not concurrency-safe; the real guarantee
    comes from the database and is covered by integration tests."""

    def __init__(self, trips: list[Trip] | None = None) -> None:
        self.trips: dict[str, Trip] = {t.id: t for t in trips or []}

    async def list_started_between(self, start: datetime, end: datetime) -> list[Trip]:
        found = [t for t in self.trips.values() if start <= t.start < end]
        return sorted(found, key=lambda t: (t.start, t.id))

    async def get(self, trip_id: str) -> Trip | None:
        return self.trips.get(trip_id)

    async def insert_if_absent(self, trip: Trip) -> bool:
        if trip.id in self.trips:
            return False
        self.trips[trip.id] = trip
        return True

    async def count(self) -> int:
        return len(self.trips)


class InMemoryUserRepository:
    def __init__(self) -> None:
        self.users: dict[str, User] = {}
        self.hashes: dict[str, str] = {}

    async def get_by_login(self, login: str) -> User | None:
        return self.users.get(login)

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


class PlainTextHasher:
    """Readable, instant 'hash' for unit tests (argon2 is covered elsewhere)."""

    def hash(self, password: str) -> str:
        return f"plain:{password}"

    def verify(self, password_hash: str, password: str) -> bool:
        return password_hash == f"plain:{password}"
