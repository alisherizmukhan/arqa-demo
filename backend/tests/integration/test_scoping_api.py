"""Who sees which trips — the reference cases of 2026-10-01 per role (prompt §3)."""

from typing import Any

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.domain.user import User
from tests.integration.conftest import bearer, seed_trips_file, trip_payload

DAY = {"date": "2026-10-01", "tz": "+05:00"}

USER_1 = {
    "trips_count": 2,
    "revenue": 3900,
    "commission": 585,
    "net": 3315,
    "cash": 1500,
    "card": 2400,
}
USER_2 = {
    "trips_count": 2,
    "revenue": 4800,
    "commission": 720,
    "net": 4080,
    "cash": 1800,
    "card": 3000,
}
ALL = {
    "trips_count": 4,
    "revenue": 8700,
    "commission": 1305,
    "net": 7395,
    "cash": 3300,
    "card": 5400,
}


@pytest.fixture(autouse=True)
async def seeded(sessionmaker: async_sessionmaker[AsyncSession], users: dict[str, User]) -> None:
    await seed_trips_file(sessionmaker, users)


async def _summary(client: AsyncClient, login: str, **params: Any) -> dict[str, Any]:
    response = await client.get("/summary", params={**DAY, **params}, headers=bearer(login))
    assert response.status_code == 200
    body: dict[str, Any] = response.json()
    return {key: body[key] for key in USER_1}


async def _trip_ids(client: AsyncClient, login: str, **params: Any) -> list[str]:
    response = await client.get("/trips", params={**DAY, **params}, headers=bearer(login))
    assert response.status_code == 200
    return [t["id"] for t in response.json()["trips"]]


async def test_user_1_reference_case(anonymous: AsyncClient) -> None:
    assert await _summary(anonymous, "user_1") == USER_1
    assert await _trip_ids(anonymous, "user_1") == ["t1", "t2"]


async def test_user_2_reference_case(anonymous: AsyncClient) -> None:
    assert await _summary(anonymous, "user_2") == USER_2
    assert await _trip_ids(anonymous, "user_2") == ["u2-t1", "u2-t2"]


async def test_admin_sees_all_drivers(anonymous: AsyncClient) -> None:
    assert await _summary(anonymous, "admin") == ALL
    assert await _trip_ids(anonymous, "admin") == ["t1", "t2", "u2-t1", "u2-t2"]


async def test_admin_can_pick_one_driver(anonymous: AsyncClient, users: dict[str, User]) -> None:
    assert await _summary(anonymous, "admin", driver_id=str(users["user_2"].id)) == USER_2
    assert await _trip_ids(anonymous, "admin", driver_id=str(users["user_1"].id)) == ["t1", "t2"]


async def test_admin_unknown_or_non_driver_id_is_404(
    anonymous: AsyncClient, users: dict[str, User]
) -> None:
    for driver_id in ("00000000-0000-4000-8000-000000000999", str(users["admin"].id)):
        response = await anonymous.get(
            "/summary", params={**DAY, "driver_id": driver_id}, headers=bearer("admin")
        )
        assert response.status_code == 404
        assert response.json()["error"]["code"] == "not_found"


@pytest.mark.parametrize("path", ["/trips", "/summary"])
async def test_a_driver_cannot_ask_for_another_driver(
    anonymous: AsyncClient, users: dict[str, User], path: str
) -> None:
    for driver_id in (users["user_2"].id, users["user_1"].id):
        response = await anonymous.get(
            path, params={**DAY, "driver_id": str(driver_id)}, headers=bearer("user_1")
        )
        assert response.status_code == 403
        assert response.json()["error"]["code"] == "forbidden"


async def test_drivers_never_see_each_others_trips(anonymous: AsyncClient) -> None:
    # user_1 has no trip of user_2's in its list or summary, and vice versa.
    assert not {"u2-t1", "u2-t2"} & set(await _trip_ids(anonymous, "user_1"))
    assert not {"t1", "t2"} & set(await _trip_ids(anonymous, "user_2"))
    assert (await _summary(anonymous, "user_1"))["revenue"] == 3900
    assert (await _summary(anonymous, "user_2"))["revenue"] == 4800


async def test_a_created_trip_belongs_to_its_driver(anonymous: AsyncClient) -> None:
    payload = trip_payload(id="new-for-u2", amount=1000, commission=100)

    created = await anonymous.post("/trips", json=payload, headers=bearer("user_2"))

    assert created.status_code == 201
    assert "new-for-u2" in await _trip_ids(anonymous, "user_2")
    assert "new-for-u2" not in await _trip_ids(anonymous, "user_1")


async def test_admin_cannot_create_trips(anonymous: AsyncClient) -> None:
    response = await anonymous.post("/trips", json=trip_payload(), headers=bearer("admin"))

    assert response.status_code == 403
    assert response.json()["error"]["code"] == "forbidden"


async def test_idempotency_is_per_owner(anonymous: AsyncClient) -> None:
    payload = trip_payload(id="mine")
    first = await anonymous.post("/trips", json=payload, headers=bearer("user_1"))
    again = await anonymous.post("/trips", json=payload, headers=bearer("user_1"))
    changed = await anonymous.post(
        "/trips", json={**payload, "amount": 9999}, headers=bearer("user_1")
    )
    other = await anonymous.post("/trips", json=payload, headers=bearer("user_2"))

    assert (first.status_code, again.status_code, changed.status_code) == (201, 200, 409)
    assert again.json() == first.json()
    # Same id from another driver: 409, and nothing about user_1's trip.
    assert other.status_code == 409
    assert other.json() == changed.json()
    assert set(other.json()) == {"error"}
    assert "mine" not in await _trip_ids(anonymous, "user_2")
