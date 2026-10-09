import json
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

from app.domain.trip import PaymentMethod, Trip

KZ = timezone(timedelta(hours=5))
SEED_FILE = Path(__file__).resolve().parents[2] / "data" / "trips.json"


def make_trip(**overrides: Any) -> Trip:
    """A valid trip on 2026-10-01 (+05:00); override any field."""
    start = overrides.get("start", datetime(2026, 10, 1, 8, 10, tzinfo=KZ))
    fields: dict[str, Any] = {
        "id": "t1",
        "start": start,
        "end": start + timedelta(minutes=22),
        "amount": 2400,
        "payment": PaymentMethod.CARD,
        "commission": 360,
    }
    fields.update(overrides)
    return Trip(**fields)


def trip_from_json(raw: dict[str, Any]) -> Trip:
    return Trip(
        id=raw["id"],
        start=datetime.fromisoformat(raw["start"]),
        end=datetime.fromisoformat(raw["end"]),
        amount=raw["amount"],
        payment=PaymentMethod.parse(raw["payment"]),
        commission=raw["commission"],
    )


def load_seed_trips(driver: str | None = "user_1") -> list[Trip]:
    """Seed trips of one driver (a trip without "driver" is user_1's), or all."""
    raw: list[dict[str, Any]] = json.loads(SEED_FILE.read_text(encoding="utf-8"))
    return [
        trip_from_json(item)
        for item in raw
        if driver is None or item.get("driver", "user_1") == driver
    ]
