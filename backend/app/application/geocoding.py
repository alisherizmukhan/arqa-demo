"""Address lookups for the place picker: a per-user rate limit in front of a
24-hour cache in front of the geocoder, so one user cannot spend the shared
daily quota and repeated lookups cost nothing.

Both live in process memory: the API runs as one replica (a second replica
would only mean a colder cache and a looser limit, never wrong answers)."""

from collections import OrderedDict, deque
from collections.abc import Callable
from dataclasses import dataclass
from datetime import datetime, timedelta
from uuid import UUID

from app.application.errors import GeoRateLimitedError
from app.application.ports import Geocoder, GeoResult
from app.domain.geo import GeoPoint, ServiceArea, ensure_in_area

# ~11 m: lookups for points this close share one cached address.
REVERSE_PRECISION = 4
SEARCH_MIN_LENGTH = 3
SEARCH_MAX_LENGTH = 100
SEARCH_LIMIT = 5


class TtlCache[K, V]:
    """Entries expire after `ttl`; past `max_entries` the oldest are dropped."""

    def __init__(self, ttl: timedelta, max_entries: int, clock: Callable[[], datetime]) -> None:
        self._ttl = ttl
        self._max = max_entries
        self._clock = clock
        self._entries: OrderedDict[K, tuple[datetime, V]] = OrderedDict()

    def get(self, key: K) -> tuple[bool, V | None]:
        found = self._entries.get(key)
        if found is None:
            return False, None
        stored_at, value = found
        if self._clock() - stored_at >= self._ttl:
            del self._entries[key]
            return False, None
        return True, value

    def put(self, key: K, value: V) -> None:
        self._entries[key] = (self._clock(), value)
        self._entries.move_to_end(key)
        while len(self._entries) > self._max:
            self._entries.popitem(last=False)


class RateLimiter:
    """At most `limit` calls per `window` per user (sliding window)."""

    def __init__(self, limit: int, window: timedelta, clock: Callable[[], datetime]) -> None:
        self._limit = limit
        self._window = window
        self._clock = clock
        self._calls: dict[UUID, deque[datetime]] = {}

    def check(self, user_id: UUID) -> None:
        now = self._clock()
        calls = self._calls.setdefault(user_id, deque())
        while calls and now - calls[0] >= self._window:
            calls.popleft()
        if len(calls) >= self._limit:
            raise GeoRateLimitedError(retry_after=calls[0] + self._window - now)
        calls.append(now)


@dataclass(frozen=True, slots=True)
class GeoService:
    geocoder: Geocoder
    area: ServiceArea
    limiter: RateLimiter
    reverse_cache: TtlCache[tuple[float, float], str | None]
    search_cache: TtlCache[str, list[GeoResult]]

    async def reverse(self, user_id: UUID, point: GeoPoint) -> str | None:
        ensure_in_area(self.area, point=point)
        self.limiter.check(user_id)
        key = (round(point.lat, REVERSE_PRECISION), round(point.lng, REVERSE_PRECISION))
        hit, label = self.reverse_cache.get(key)
        if hit:
            return label
        label = await self.geocoder.reverse(GeoPoint(*key))
        self.reverse_cache.put(key, label)
        return label

    async def search(self, user_id: UUID, text: str) -> list[GeoResult]:
        self.limiter.check(user_id)
        key = " ".join(text.lower().split())
        if len(key) < SEARCH_MIN_LENGTH:
            return []
        hit, results = self.search_cache.get(key)
        if hit and results is not None:
            return results
        found = await self.geocoder.search(key, self.area, SEARCH_LIMIT)
        results = [r for r in found if self.area.contains(r.point)][:SEARCH_LIMIT]
        self.search_cache.put(key, results)
        return results
