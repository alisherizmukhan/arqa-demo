import asyncio
from collections import Counter

from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.domain.user import User
from app.infrastructure.repository import SqlTripRepository
from tests.factories import make_trip
from tests.integration.conftest import count_trips, trip_payload


async def test_new_trip_is_created(
    client: AsyncClient, sessionmaker: async_sessionmaker[AsyncSession]
) -> None:
    payload = trip_payload()

    response = await client.post("/trips", json=payload)

    assert response.status_code == 201
    assert response.json() == {**payload, "net": 1870}
    assert await count_trips(sessionmaker, payload["id"]) == 1


async def test_repeated_post_returns_200_and_no_duplicate(
    client: AsyncClient, sessionmaker: async_sessionmaker[AsyncSession]
) -> None:
    payload = trip_payload()
    first = await client.post("/trips", json=payload)

    second = await client.post("/trips", json=payload)
    third = await client.post("/trips", json=payload)

    assert (first.status_code, second.status_code, third.status_code) == (201, 200, 200)
    assert second.json() == first.json() == third.json()
    assert await count_trips(sessionmaker) == 1


async def test_same_trip_in_utc_notation_is_a_safe_retry(
    client: AsyncClient, sessionmaker: async_sessionmaker[AsyncSession]
) -> None:
    payload = trip_payload(start="2026-10-01T10:00:00+05:00", end="2026-10-01T10:25:00+05:00")
    await client.post("/trips", json=payload)

    retry = await client.post(
        "/trips", json={**payload, "start": "2026-10-01T05:00:00Z", "end": "2026-10-01T05:25:00Z"}
    )

    assert retry.status_code == 200
    assert retry.json()["start"] == "2026-10-01T05:00:00Z"
    assert await count_trips(sessionmaker) == 1


async def test_same_id_different_payload_is_409(
    client: AsyncClient, sessionmaker: async_sessionmaker[AsyncSession]
) -> None:
    payload = trip_payload(amount=2200)
    await client.post("/trips", json=payload)

    response = await client.post("/trips", json={**payload, "amount": 9999})

    assert response.status_code == 409
    assert response.json() == {
        "error": {
            "code": "trip_conflict",
            "message": f"trip '{payload['id']}' already exists with a different payload",
            "field": "id",
        }
    }
    stored = (await client.get("/trips", params={"date": "2026-10-01"})).json()["trips"]
    assert [t["amount"] for t in stored] == [2200]
    assert await count_trips(sessionmaker) == 1


async def test_concurrent_identical_posts_create_exactly_one_row(
    client: AsyncClient, sessionmaker: async_sessionmaker[AsyncSession]
) -> None:
    payload = trip_payload()

    responses = await asyncio.gather(*(client.post("/trips", json=payload) for _ in range(20)))

    assert Counter(r.status_code for r in responses) == {201: 1, 200: 19}
    assert all(r.json() == responses[0].json() for r in responses)
    assert await count_trips(sessionmaker) == 1


async def test_concurrent_posts_with_conflicting_payloads(
    client: AsyncClient, sessionmaker: async_sessionmaker[AsyncSession]
) -> None:
    a = trip_payload(amount=2200)
    b = {**a, "amount": 3300}
    payloads = [a, b] * 10

    responses = await asyncio.gather(*(client.post("/trips", json=p) for p in payloads))

    winner = next(p for p, r in zip(payloads, responses, strict=True) if r.status_code == 201)
    statuses = Counter(r.status_code for r in responses)
    assert statuses == {201: 1, 200: 9, 409: 10}
    for sent, response in zip(payloads, responses, strict=True):
        assert response.status_code in ({200, 201} if sent is winner else {409})
    assert await count_trips(sessionmaker) == 1


async def test_repository_insert_is_atomic_across_sessions(
    sessionmaker: async_sessionmaker[AsyncSession], users: dict[str, User]
) -> None:
    """The guarantee itself: separate sessions/transactions racing on one id."""
    trip = make_trip(id="race")

    async def attempt() -> bool:
        async with sessionmaker() as session:
            return await SqlTripRepository(session, users["user_1"].id).insert_if_absent(trip)

    results = await asyncio.gather(*(attempt() for _ in range(10)))

    assert results.count(True) == 1
    assert await count_trips(sessionmaker) == 1
