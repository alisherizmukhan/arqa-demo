from datetime import datetime, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.domain.user import User
from app.infrastructure.repository import SqlTripRepository
from tests.factories import make_trip
from tests.integration.conftest import seed_trips_file, trip_payload

REFERENCE_SUMMARY = {
    "date": "2026-10-01",
    "tz": "+05:00",
    "trips_count": 2,
    "revenue": 3900,
    "commission": 585,
    "net": 3315,
    "cash": 1500,
    "card": 2400,
}


@pytest.fixture
async def seeded(sessionmaker: async_sessionmaker[AsyncSession], users: dict[str, User]) -> None:
    await seed_trips_file(sessionmaker, users)


async def test_health(client: AsyncClient) -> None:
    response = await client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "database": "ok"}


@pytest.mark.usefixtures("seeded")
async def test_reference_case_summary(client: AsyncClient) -> None:
    response = await client.get("/summary", params={"date": "2026-10-01", "tz": "+05:00"})

    assert response.status_code == 200
    assert response.json() == REFERENCE_SUMMARY


@pytest.mark.usefixtures("seeded")
async def test_reference_case_trips(client: AsyncClient) -> None:
    response = await client.get("/trips", params={"date": "2026-10-01"})

    assert response.status_code == 200
    body = response.json()
    assert (body["date"], body["tz"]) == ("2026-10-01", "+05:00")
    assert [(t["id"], t["start"], t["end"], t["net"]) for t in body["trips"]] == [
        ("t1", "2026-10-01T08:10:00+05:00", "2026-10-01T08:32:00+05:00", 2040),
        ("t2", "2026-10-01T09:05:00+05:00", "2026-10-01T09:20:00+05:00", 1275),
    ]


@pytest.mark.usefixtures("seeded")
@pytest.mark.parametrize(
    "query",
    [
        "date=2026-10-01",  # default tz
        "date=2026-10-01&tz=%2B05:00",  # properly encoded
        "date=2026-10-01&tz=+05:00",  # raw '+', decoded by the server as a space
    ],
)
async def test_tz_query_variants(client: AsyncClient, query: str) -> None:
    response = await client.get(f"/summary?{query}")

    assert response.status_code == 200
    assert response.json() == REFERENCE_SUMMARY


@pytest.mark.usefixtures("seeded")
async def test_trip_crossing_midnight_is_listed_on_start_day_only(client: AsyncClient) -> None:
    sep_30 = (await client.get("/trips", params={"date": "2026-09-30"})).json()
    oct_1 = (await client.get("/trips", params={"date": "2026-10-01"})).json()

    assert [t["id"] for t in sep_30["trips"]] == ["t3", "t4"]
    assert "t4" not in [t["id"] for t in oct_1["trips"]]


@pytest.mark.usefixtures("seeded")
async def test_trip_written_in_utc_lands_on_local_day(client: AsyncClient) -> None:
    oct_2 = (await client.get("/trips", params={"date": "2026-10-02"})).json()

    assert [t["id"] for t in oct_2["trips"]] == ["t5", "t6", "t7", "t8"]
    assert oct_2["trips"][0]["start"] == "2026-10-02T00:30:00+05:00"


@pytest.mark.usefixtures("seeded")
async def test_same_date_in_another_timezone(client: AsyncClient) -> None:
    trips = (await client.get("/trips", params={"date": "2026-10-01", "tz": "Z"})).json()
    summary = (await client.get("/summary", params={"date": "2026-10-01", "tz": "Z"})).json()

    assert [t["id"] for t in trips["trips"]] == ["t1", "t2", "t5"]
    assert trips["trips"][0]["start"] == "2026-10-01T03:10:00Z"
    assert (summary["tz"], summary["trips_count"], summary["revenue"]) == ("+00:00", 3, 6700)


async def test_day_boundaries_in_database_query(client: AsyncClient) -> None:
    starts = {
        "prev-235959": "2026-09-30T23:59:59+05:00",
        "first-000000": "2026-10-01T00:00:00+05:00",
        "last-235959": "2026-10-01T23:59:59+05:00",
        "last-utc": "2026-10-01T18:59:59.999999Z",
        "next-000000": "2026-10-02T00:00:00+05:00",
    }
    for trip_id, start in starts.items():
        end = datetime.fromisoformat(start) + timedelta(minutes=30)
        payload = trip_payload(id=trip_id, start=start, end=end.isoformat())
        assert (await client.post("/trips", json=payload)).status_code == 201

    body = (await client.get("/trips", params={"date": "2026-10-01"})).json()

    assert [t["id"] for t in body["trips"]] == ["first-000000", "last-235959", "last-utc"]


async def test_trips_are_sorted_by_start(client: AsyncClient) -> None:
    for trip_id, hour in [("c", 15), ("a", 9), ("b", 12)]:
        payload = trip_payload(
            id=trip_id,
            start=f"2026-10-01T{hour:02d}:00:00+05:00",
            end=f"2026-10-01T{hour:02d}:30:00+05:00",
        )
        assert (await client.post("/trips", json=payload)).status_code == 201

    body = (await client.get("/trips", params={"date": "2026-10-01"})).json()

    assert [t["id"] for t in body["trips"]] == ["a", "b", "c"]


async def test_empty_day(client: AsyncClient) -> None:
    trips = (await client.get("/trips", params={"date": "2026-12-31"})).json()
    summary = (await client.get("/summary", params={"date": "2026-12-31"})).json()

    assert trips["trips"] == []
    assert summary == {
        "date": "2026-12-31",
        "tz": "+05:00",
        "trips_count": 0,
        "revenue": 0,
        "commission": 0,
        "net": 0,
        "cash": 0,
        "card": 0,
    }


async def test_created_trip_shows_up_in_summary(client: AsyncClient) -> None:
    await client.post("/trips", json=trip_payload(amount=5000, commission=750, payment="cash"))

    summary = (await client.get("/summary", params={"date": "2026-10-01"})).json()

    assert (summary["trips_count"], summary["revenue"], summary["net"]) == (1, 5000, 4250)
    assert (summary["cash"], summary["card"]) == (5000, 0)


async def test_a_trip_needs_a_driver(sessionmaker: async_sessionmaker[AsyncSession]) -> None:
    async with sessionmaker() as session:
        with pytest.raises(ValueError, match="for a driver"):
            await SqlTripRepository(session).insert_if_absent(make_trip(id="orphan"))
