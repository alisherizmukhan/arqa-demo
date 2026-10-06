from typing import Any

import pytest
from httpx import AsyncClient, Response
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from tests.integration.conftest import count_trips, trip_payload

START = "2026-10-01T10:00:00+05:00"


def assert_error(response: Response, status: int, code: str, field: str | None) -> None:
    assert response.status_code == status
    body = response.json()
    assert body.keys() == {"error"}
    assert body["error"].keys() == {"code", "message", "field"}
    assert (body["error"]["code"], body["error"]["field"]) == (code, field)
    assert body["error"]["message"]


@pytest.mark.parametrize(
    ("changes", "code", "field"),
    [
        ({"amount": 0}, "invalid_amount", "amount"),
        ({"amount": -100}, "invalid_amount", "amount"),
        ({"amount": 10_000_001}, "amount_too_large", "amount"),
        ({"amount": "2200"}, "invalid_type", "amount"),
        ({"amount": 2200.5}, "invalid_type", "amount"),
        ({"amount": 2200.0}, "invalid_type", "amount"),
        ({"amount": True}, "invalid_type", "amount"),
        ({"commission": -1}, "invalid_commission", "commission"),
        ({"commission": 2201}, "commission_exceeds_amount", "commission"),
        ({"end": START}, "invalid_time_range", "end"),
        ({"end": "2026-10-01T09:59:59+05:00"}, "invalid_time_range", "end"),
        ({"payment": "crypto"}, "invalid_payment", "payment"),
        ({"payment": "CASH"}, "invalid_payment", "payment"),
        ({"start": "2026-10-01T10:00:00"}, "naive_datetime", "start"),
        ({"end": "2026-10-01T10:25:00"}, "naive_datetime", "end"),
        ({"start": "yesterday"}, "invalid_datetime", "start"),
        ({"start": 1790000000}, "invalid_datetime", "start"),
        ({"id": ""}, "invalid_id", "id"),
        ({"id": "has space"}, "invalid_id", "id"),
        ({"id": 42}, "invalid_id", "id"),
        ({"tip": 100}, "unknown_field", "tip"),
        (
            {"start": "0001-01-01T01:00:00+05:00", "end": "0001-01-01T02:00:00+05:00"},
            "datetime_out_of_range",
            "start",
        ),
        ({"end": "2026-10-03T10:00:00+05:00"}, "trip_too_long", "end"),
    ],
)
async def test_invalid_trip_is_rejected_with_error_shape(
    client: AsyncClient,
    sessionmaker: async_sessionmaker[AsyncSession],
    changes: dict[str, Any],
    code: str,
    field: str,
) -> None:
    response = await client.post("/trips", json=trip_payload(**{"start": START, **changes}))

    assert_error(response, 422, code, field)
    assert await count_trips(sessionmaker) == 0


@pytest.mark.parametrize("missing", ["id", "start", "end", "amount", "payment", "commission"])
async def test_missing_field(client: AsyncClient, missing: str) -> None:
    payload = trip_payload()
    del payload[missing]

    assert_error(await client.post("/trips", json=payload), 422, "missing_field", missing)


async def test_malformed_json(client: AsyncClient) -> None:
    response = await client.post(
        "/trips", content=b'{"id": "x",', headers={"content-type": "application/json"}
    )

    assert_error(response, 422, "invalid_json", None)


async def test_body_must_be_an_object(client: AsyncClient) -> None:
    assert_error(await client.post("/trips", json=[trip_payload()]), 422, "invalid_request", None)


@pytest.mark.parametrize("path", ["/trips", "/summary"])
@pytest.mark.parametrize(
    ("query", "code", "field"),
    [
        ("", "missing_field", "date"),
        ("date=2026-13-01", "invalid_date", "date"),
        ("date=2026-02-30", "invalid_date", "date"),
        ("date=01.10.2026", "invalid_date", "date"),
        ("date=2026-10-01T00:00:00", "invalid_date", "date"),
        ("date=0001-01-01", "invalid_date", "date"),
        ("date=1999-12-31", "invalid_date", "date"),
        ("date=2100-01-01", "invalid_date", "date"),
        ("date=9999-12-31", "invalid_date", "date"),
        ("date=2026-10-01&tz=Asia/Almaty", "invalid_timezone", "tz"),
        ("date=2026-10-01&tz=%2B15:00", "invalid_timezone", "tz"),
        ("date=2026-10-01&tz=5", "invalid_timezone", "tz"),
    ],
)
async def test_invalid_query(
    client: AsyncClient, path: str, query: str, code: str, field: str
) -> None:
    assert_error(await client.get(f"{path}?{query}"), 422, code, field)


async def test_unknown_route_uses_error_shape(client: AsyncClient) -> None:
    assert_error(await client.get("/nope"), 404, "not_found", None)


async def test_wrong_method_uses_error_shape(client: AsyncClient) -> None:
    assert_error(await client.put("/trips", json={}), 405, "method_not_allowed", None)
