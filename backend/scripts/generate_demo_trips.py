"""Regenerate data/trips.json: hand-written edge cases + realistic demo shifts.

    uv run python scripts/generate_demo_trips.py

Deterministic (seeded per day), so re-running produces the same file. The
hand-written trips (ids t1..tN) are kept verbatim: they hold the reference day
2026-10-01 (exactly t1 and t2) and the day-boundary edge cases that tests use,
so generated shifts never touch 2026-09-30 .. 2026-10-03.
"""

import json
import random
import re
from datetime import date, datetime, time, timedelta, timezone
from pathlib import Path
from typing import Any

SEED_FILE = Path(__file__).resolve().parents[2] / "data" / "trips.json"
KZ = timezone(timedelta(hours=5))
# t1..tN, plus the reference trips of other drivers (u2-t1, ...).
HANDWRITTEN_ID = re.compile(r"^(u\d+-)?t\d+$")
RESERVED_DAYS = {date(2026, 9, 30), date(2026, 10, 1), date(2026, 10, 2), date(2026, 10, 3)}
DAYS_OFF = {date(2026, 9, 27)}
FIRST_DAY, LAST_DAY = date(2026, 9, 21), date(2026, 10, 6)
# The last day is "today": the shift is still in progress.
LAST_DAY_SHIFT_END = time(17, 30)


def generate_day(day: date) -> list[dict[str, Any]]:
    rng = random.Random(day.isoformat())
    now = datetime.combine(day, time(7, 0), tzinfo=KZ) + timedelta(minutes=rng.randint(0, 90))
    shift_end = datetime.combine(
        day, LAST_DAY_SHIFT_END if day == LAST_DAY else time(22, 30), tzinfo=KZ
    )
    lunch_taken = False
    trips: list[dict[str, Any]] = []
    while now < shift_end and len(trips) < rng.randint(9, 15):
        airport = rng.random() < 0.1
        minutes = rng.randint(35, 55) if airport else rng.randint(8, 40)
        per_minute = rng.uniform(110, 140) if airport else rng.uniform(70, 110)
        amount = max(700, round((500 + minutes * per_minute) / 50) * 50)
        rate = 15 if rng.random() < 0.85 else 12
        end = now + timedelta(minutes=minutes)
        trips.append(
            {
                "id": f"d{day:%m%d}-{len(trips) + 1:02d}",
                "start": now.isoformat(),
                "end": end.isoformat(),
                "amount": amount,
                "payment": "cash" if rng.random() < 0.35 else "card",
                "commission": amount * rate // 100,
            }
        )
        now = end + timedelta(minutes=rng.randint(4, 30))
        if not lunch_taken and now.hour >= 13:
            now += timedelta(minutes=rng.randint(30, 50))
            lunch_taken = True
    return trips


def late_trip_crossing_midnight(day: date) -> dict[str, Any]:
    start = datetime.combine(day, time(23, 40), tzinfo=KZ)
    return {
        "id": f"d{day:%m%d}-late",
        "start": start.isoformat(),
        "end": (start + timedelta(minutes=27)).isoformat(),
        "amount": 3400,
        "payment": "card",
        "commission": 510,
    }


def main() -> None:
    existing: list[dict[str, Any]] = json.loads(SEED_FILE.read_text(encoding="utf-8"))
    handwritten = [t for t in existing if HANDWRITTEN_ID.match(t["id"])]

    generated: list[dict[str, Any]] = []
    day = FIRST_DAY
    while day <= LAST_DAY:
        if day not in RESERVED_DAYS | DAYS_OFF:
            generated += generate_day(day)
        day += timedelta(days=1)
    generated.append(late_trip_crossing_midnight(date(2026, 10, 5)))

    trips = handwritten + sorted(generated, key=lambda t: t["start"])
    lines = ",\n".join("  " + json.dumps(t, ensure_ascii=False) for t in trips)
    SEED_FILE.write_text(f"[\n{lines}\n]\n", encoding="utf-8", newline="\n")
    print(f"{SEED_FILE}: {len(handwritten)} hand-written + {len(generated)} generated trips")


if __name__ == "__main__":
    main()
