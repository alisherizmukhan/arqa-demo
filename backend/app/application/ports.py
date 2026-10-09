from dataclasses import dataclass
from datetime import datetime
from typing import Protocol
from uuid import UUID

from app.domain.trip import Trip
from app.domain.user import Role, User


@dataclass(frozen=True, slots=True)
class OwnedTrip:
    trip: Trip
    driver_id: UUID


class TripRepository(Protocol):
    """Trips of one driver, or of all drivers (admin scope)."""

    async def list_started_between(self, start: datetime, end: datetime) -> list[Trip]:
        """Trips with start in [start, end), ordered by start then id."""
        ...

    async def get(self, trip_id: str) -> OwnedTrip | None:
        """Any driver's trip with this id (ids are globally unique)."""
        ...

    async def insert_if_absent(self, trip: Trip) -> bool:
        """Atomically insert unless a trip with this id exists. True if inserted.

        Must be enforced by the storage itself (unique key), never by a
        separate existence check, so concurrent callers are safe.
        """
        ...


class UserRepository(Protocol):
    async def get(self, user_id: UUID) -> User | None: ...

    async def get_by_login(self, login: str) -> User | None: ...

    async def list_all(self) -> list[User]:
        """Ordered by role (drivers first), then login."""
        ...

    async def password_hash(self, login: str) -> str | None:
        """The stored hash, for verification only."""
        ...

    async def insert_if_absent(
        self, *, login: str, password_hash: str, role: Role, display_name: str
    ) -> bool:
        """Insert unless the login exists (atomically, by the unique key)."""
        ...

    async def set_password_hash(self, login: str, password_hash: str) -> None: ...

    async def set_active(self, user_id: UUID, is_active: bool) -> User | None: ...


@dataclass(frozen=True, slots=True)
class ActiveSession:
    session_id: UUID
    user: User
    last_used_at: datetime


class SessionRepository(Protocol):
    async def create(self, *, user_id: UUID, token_hash: str, user_agent: str | None) -> None: ...

    async def find_active(self, token_hash: str) -> ActiveSession | None:
        """The session with this token hash unless revoked, with its user."""
        ...

    async def touch(self, session_id: UUID, now: datetime) -> None: ...

    async def revoke(self, token_hash: str, now: datetime) -> None: ...

    async def revoke_all(self, user_id: UUID, now: datetime) -> int:
        """Revoke every active session of the user; returns how many."""
        ...


class LoginAttemptRepository(Protocol):
    """Failed logins, counted per (login, client IP)."""

    async def failures_since(self, login: str, client_ip: str, since: datetime) -> list[datetime]:
        """Times of failed logins for this login from this IP after `since`, oldest first."""
        ...

    async def record_failure(self, login: str, client_ip: str, now: datetime) -> None: ...


class PasswordHasher(Protocol):
    def hash(self, password: str) -> str: ...

    def verify(self, password_hash: str, password: str) -> bool:
        """False for a wrong password and for a hash it cannot read."""
        ...

    def dummy_hash(self) -> str:
        """A real hash of a random password: verifying against it costs the same
        as a real check, so an unknown login takes as long as a wrong password."""
        ...


@dataclass(frozen=True, slots=True)
class Accounts:
    """The stores account use cases work with together."""

    users: UserRepository
    sessions: SessionRepository
