import json
from datetime import datetime
from pathlib import Path
from typing import Any

from app.domain.trip import PaymentMethod, Trip


def load_trips_from_json(path: Path) -> list[Trip]:
    """Parse a trips file in the assignment's format. Domain rules apply
    (a naive timestamp or a negative amount makes the whole file invalid)."""
    raw: list[dict[str, Any]] = json.loads(path.read_text(encoding="utf-8"))
    return [
        Trip(
            id=item["id"],
            start=datetime.fromisoformat(item["start"]),
            end=datetime.fromisoformat(item["end"]),
            amount=item["amount"],
            payment=PaymentMethod.parse(item["payment"]),
            commission=item["commission"],
        )
        for item in raw
    ]
