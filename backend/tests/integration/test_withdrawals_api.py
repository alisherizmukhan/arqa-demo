"""Withdrawals against real Postgres, on a clean seed with only the reference
trips (t1, t2 for user_1; u2-t1, u2-t2 for user_2): balances 1 815 / 2 280."""

import asyncio
import uuid
from typing import Any

import pytest
from httpx import AsyncClient, Response
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.application.use_cases import seed_trips
from app.domain.user import User
from app.infrastructure.models import WithdrawalRow
from app.infrastructure.repository import SqlTripRepository
from app.infrastructure.seed import load_seed_trips
from tests.factories import SEED_FILE
from tests.integration.conftest import bearer

REFERENCE_IDS = {"t1", "t2", "u2-t1", "u2-t2"}


@pytest.fixture(autouse=True)
async def reference_trips(
    sessionmaker: async_sessionmaker[AsyncSession], users: dict[str, User]
) -> None:
    seeds = [s for s in load_seed_trips(SEED_FILE) if s.trip.id in REFERENCE_IDS]
    async with sessionmaker() as session:
        for login in ("user_1", "user_2"):
            trips = [s.trip for s in seeds if s.driver == login]
            await seed_trips(SqlTripRepository(session, users[login].id), trips)


async def _balance(client: AsyncClient, login: str, **params: Any) -> dict[str, int]:
    response = await client.get("/balance", params=params, headers=bearer(login))
    assert response.status_code == 200
    body: dict[str, int] = response.json()
    return body


async def _withdraw(
    client: AsyncClient, login: str, amount: int, wid: str | None = None
) -> Response:
    return await client.post(
        "/withdrawals",
        json={"id": wid or str(uuid.uuid4()), "amount": amount},
        headers=bearer(login),
    )


async def _rows(sessionmaker: async_sessionmaker[AsyncSession]) -> int:
    async with sessionmaker() as session:
        return await session.scalar(select(func.count()).select_from(WithdrawalRow)) or 0


async def test_reference_balances(anonymous: AsyncClient, users: dict[str, User]) -> None:
    assert await _balance(anonymous, "user_1") == {
        "available": 1815,
        "card_total": 2400,
        "commission_total": 585,
        "withdrawn_total": 0,
    }
    assert (await _balance(anonymous, "user_2"))["available"] == 2280
    assert (await _balance(anonymous, "admin"))["available"] == 1815 + 2280
    one = await _balance(anonymous, "admin", driver_id=str(users["user_2"].id))
    assert one["available"] == 2280


async def test_create_retry_and_conflict(
    anonymous: AsyncClient, sessionmaker: async_sessionmaker[AsyncSession]
) -> None:
    wid = str(uuid.uuid4())

    created = await _withdraw(anonymous, "user_2", 1000, wid)
    retried = await _withdraw(anonymous, "user_2", 1000, wid)
    changed = await _withdraw(anonymous, "user_2", 900, wid)

    assert created.status_code == 201
    assert created.json()["status"] == "pending"
    assert retried.status_code == 200
    assert retried.json() == created.json()
    assert changed.status_code == 409
    assert changed.json()["error"]["code"] == "withdrawal_conflict"
    assert await _rows(sessionmaker) == 1
    assert (await _balance(anonymous, "user_2"))["available"] == 1280


async def test_amount_rules(anonymous: AsyncClient) -> None:
    too_much = await _withdraw(anonymous, "user_1", 1816)
    zero = await _withdraw(anonymous, "user_1", 0)
    text_amount = await anonymous.post(
        "/withdrawals",
        json={"id": str(uuid.uuid4()), "amount": "100"},
        headers=bearer("user_1"),
    )
    bad_id = await anonymous.post(
        "/withdrawals", json={"id": "not-a-uuid", "amount": 100}, headers=bearer("user_1")
    )

    assert too_much.status_code == 422
    assert too_much.json()["error"]["code"] == "insufficient_funds"
    assert too_much.json()["error"]["field"] == "amount"
    assert zero.status_code == 422
    assert zero.json()["error"] == {
        "code": "invalid_amount",
        "message": "amount must be a positive integer",
        "field": "amount",
    }
    assert text_amount.status_code == 422
    assert bad_id.status_code == 422
    assert (await _withdraw(anonymous, "user_1", 1815)).status_code == 201


async def test_same_id_from_another_driver_reveals_nothing(anonymous: AsyncClient) -> None:
    wid = str(uuid.uuid4())
    await _withdraw(anonymous, "user_1", 500, wid)

    other = await _withdraw(anonymous, "user_2", 500, wid)

    assert other.status_code == 409
    assert set(other.json()) == {"error"}
    listed = await anonymous.get("/withdrawals", headers=bearer("user_2"))
    assert listed.json() == []


async def test_approve_and_reject_change_the_balance(anonymous: AsyncClient) -> None:
    paid = (await _withdraw(anonymous, "user_2", 1000)).json()["id"]
    rejected = (await _withdraw(anonymous, "user_2", 500)).json()["id"]
    assert (await _balance(anonymous, "user_2"))["available"] == 780

    approve = await anonymous.post(f"/admin/withdrawals/{paid}/approve", headers=bearer("admin"))
    approve_again = await anonymous.post(
        f"/admin/withdrawals/{paid}/approve", headers=bearer("admin")
    )
    assert approve.status_code == approve_again.status_code == 200
    assert approve.json()["status"] == "paid"
    assert approve_again.json() == approve.json()
    assert (await _balance(anonymous, "user_2"))["available"] == 780  # paid stays spent

    reject = await anonymous.post(
        f"/admin/withdrawals/{rejected}/reject",
        json={"reason": "Неверные реквизиты"},
        headers=bearer("admin"),
    )
    assert reject.status_code == 200
    assert reject.json()["status"] == "rejected"
    assert reject.json()["reject_reason"] == "Неверные реквизиты"
    assert (await _balance(anonymous, "user_2"))["available"] == 1280  # money is back

    other_way = await anonymous.post(
        f"/admin/withdrawals/{paid}/reject", json={"reason": "поздно"}, headers=bearer("admin")
    )
    assert other_way.status_code == 409
    assert other_way.json()["error"]["code"] == "withdrawal_already_decided"


async def test_reject_needs_a_reason(anonymous: AsyncClient) -> None:
    wid = (await _withdraw(anonymous, "user_1", 100)).json()["id"]

    for body in ({"reason": "   "}, {}):
        response = await anonymous.post(
            f"/admin/withdrawals/{wid}/reject", json=body, headers=bearer("admin")
        )
        assert response.status_code == 422


async def test_unknown_withdrawal_is_404(anonymous: AsyncClient) -> None:
    response = await anonymous.post(
        f"/admin/withdrawals/{uuid.uuid4()}/approve", headers=bearer("admin")
    )

    assert response.status_code == 404


async def test_roles(anonymous: AsyncClient, users: dict[str, User]) -> None:
    wid = (await _withdraw(anonymous, "user_1", 100)).json()["id"]

    admin_creates = await _withdraw(anonymous, "admin", 100)
    driver_approves = await anonymous.post(
        f"/admin/withdrawals/{wid}/approve", headers=bearer("user_1")
    )
    driver_picks = await anonymous.get(
        "/withdrawals", params={"driver_id": str(users["user_2"].id)}, headers=bearer("user_1")
    )
    balance_picks = await anonymous.get(
        "/balance", params={"driver_id": str(users["user_1"].id)}, headers=bearer("user_1")
    )

    assert admin_creates.status_code == 403
    assert driver_approves.status_code == 403
    assert driver_picks.status_code == 403
    assert balance_picks.status_code == 403
    for path in ("/balance", "/withdrawals"):
        assert (await anonymous.get(path)).status_code == 401


async def test_lists_are_scoped_and_filterable(
    anonymous: AsyncClient, users: dict[str, User]
) -> None:
    mine = (await _withdraw(anonymous, "user_1", 100)).json()["id"]
    theirs = (await _withdraw(anonymous, "user_2", 200)).json()["id"]
    await anonymous.post(f"/admin/withdrawals/{theirs}/approve", headers=bearer("admin"))

    own = (await anonymous.get("/withdrawals", headers=bearer("user_1"))).json()
    everyone = (await anonymous.get("/withdrawals", headers=bearer("admin"))).json()
    pending = (
        await anonymous.get("/withdrawals", params={"status": "pending"}, headers=bearer("admin"))
    ).json()
    one = (
        await anonymous.get(
            "/withdrawals",
            params={"driver_id": str(users["user_2"].id)},
            headers=bearer("admin"),
        )
    ).json()

    assert [w["id"] for w in own] == [mine]
    assert {w["id"] for w in everyone} == {mine, theirs}
    assert [w["id"] for w in pending] == [mine]
    assert [w["id"] for w in one] == [theirs]


# --- Concurrency: real Postgres, separate sessions, simultaneous requests -----


async def test_concurrent_identical_requests_create_one_row(
    anonymous: AsyncClient, sessionmaker: async_sessionmaker[AsyncSession]
) -> None:
    wid = str(uuid.uuid4())

    responses = await asyncio.gather(
        *(_withdraw(anonymous, "user_1", 1000, wid) for _ in range(10))
    )

    codes = sorted(r.status_code for r in responses)
    assert codes == [200] * 9 + [201]
    assert len({r.json()["id"] for r in responses}) == 1
    assert await _rows(sessionmaker) == 1
    assert (await _balance(anonymous, "user_1"))["available"] == 815


async def test_two_requests_cannot_spend_more_than_the_balance(
    anonymous: AsyncClient, sessionmaker: async_sessionmaker[AsyncSession]
) -> None:
    # 1 000 + 1 000 > 1 815: exactly one may succeed.
    first, second = await asyncio.gather(
        _withdraw(anonymous, "user_1", 1000), _withdraw(anonymous, "user_1", 1000)
    )

    assert sorted([first.status_code, second.status_code]) == [201, 422]
    loser = first if first.status_code == 422 else second
    assert loser.json()["error"]["code"] == "insufficient_funds"
    assert await _rows(sessionmaker) == 1
    assert (await _balance(anonymous, "user_1"))["available"] == 815


async def test_many_concurrent_requests_never_overdraw(
    anonymous: AsyncClient, sessionmaker: async_sessionmaker[AsyncSession]
) -> None:
    # 12 x 500 at once against 1 815: exactly 3 fit.
    responses = await asyncio.gather(*(_withdraw(anonymous, "user_1", 500) for _ in range(12)))

    codes = [r.status_code for r in responses]
    assert codes.count(201) == 3
    assert codes.count(422) == 9
    assert await _rows(sessionmaker) == 3
    balance = await _balance(anonymous, "user_1")
    assert (balance["withdrawn_total"], balance["available"]) == (1500, 315)


async def test_drivers_do_not_block_each_other(anonymous: AsyncClient) -> None:
    results = await asyncio.gather(
        _withdraw(anonymous, "user_1", 1815), _withdraw(anonymous, "user_2", 2280)
    )

    assert [r.status_code for r in results] == [201, 201]
