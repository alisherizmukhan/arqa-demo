from datetime import datetime

from app.domain.trip import Trip


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
