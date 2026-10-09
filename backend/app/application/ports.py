from datetime import datetime
from typing import Protocol

from app.domain.trip import Trip
from app.domain.user import Role, User


class TripRepository(Protocol):
    async def list_started_between(self, start: datetime, end: datetime) -> list[Trip]:
        """Trips with start in [start, end), ordered by start then id."""
        ...

    async def get(self, trip_id: str) -> Trip | None: ...

    async def insert_if_absent(self, trip: Trip) -> bool:
        """Atomically insert unless a trip with this id exists. True if inserted.

        Must be enforced by the storage itself (unique key), never by a
        separate existence check, so concurrent callers are safe.
        """
        ...


class UserRepository(Protocol):
    async def get_by_login(self, login: str) -> User | None: ...

    async def password_hash(self, login: str) -> str | None:
        """The stored hash, for verification only."""
        ...

    async def insert_if_absent(
        self, *, login: str, password_hash: str, role: Role, display_name: str
    ) -> bool:
        """Insert unless the login exists (atomically, by the unique key)."""
        ...

    async def set_password_hash(self, login: str, password_hash: str) -> None: ...


class PasswordHasher(Protocol):
    def hash(self, password: str) -> str: ...

    def verify(self, password_hash: str, password: str) -> bool:
        """False for a wrong password and for a hash it cannot read."""
        ...
