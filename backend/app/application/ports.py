from datetime import datetime
from typing import Protocol

from app.domain.trip import Trip


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

    async def count(self) -> int: ...
