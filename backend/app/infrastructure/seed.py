import json
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any

from app.domain.geo import GeoPoint, Place
from app.domain.trip import PaymentMethod, Trip

# Trips in the file without a "driver" belong to this login (the demo history).
DEFAULT_SEED_DRIVER = "user_1"


@dataclass(frozen=True, slots=True)
class SeedTrip:
    driver: str
    trip: Trip


def load_seed_trips(path: Path) -> list[SeedTrip]:
    """Parse a trips file in the assignment's format, plus an optional "driver"
    (login) and optional "pickup" / "dropoff" ({"lat", "lng", "label"}).
    Domain rules apply: one invalid trip makes the whole file invalid."""
    raw: list[dict[str, Any]] = json.loads(path.read_text(encoding="utf-8"))
    return [
        SeedTrip(
            driver=item.get("driver", DEFAULT_SEED_DRIVER),
            trip=Trip(
                id=item["id"],
                start=datetime.fromisoformat(item["start"]),
                end=datetime.fromisoformat(item["end"]),
                amount=item["amount"],
                payment=PaymentMethod.parse(item["payment"]),
                commission=item["commission"],
                pickup=_place(item.get("pickup")),
                dropoff=_place(item.get("dropoff")),
            ),
        )
        for item in raw
    ]


def _place(raw: dict[str, Any] | None) -> Place | None:
    if raw is None:
        return None
    return Place(point=GeoPoint(float(raw["lat"]), float(raw["lng"])), label=raw.get("label"))
