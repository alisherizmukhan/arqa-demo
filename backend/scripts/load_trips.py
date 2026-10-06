"""Load a trips file into a running API through POST /trips.

    uv run python scripts/load_trips.py https://api-production-6e8b.up.railway.app
    uv run python scripts/load_trips.py http://127.0.0.1:8000 --file ../data/trips.json

Uses the public API on purpose: every trip goes through the same validation and
idempotency as the app. Re-running is safe (already loaded trips return 200),
and a network error is retried with the same trip id.
"""

import argparse
import json
import sys
import time
from collections import Counter
from pathlib import Path
from typing import Any

import httpx

DEFAULT_FILE = Path(__file__).resolve().parents[2] / "data" / "trips.json"
RETRIES = 3


def post_with_retry(client: httpx.Client, trip: dict[str, Any]) -> httpx.Response:
    for attempt in range(1, RETRIES + 1):
        try:
            return client.post("/trips", json=trip)
        except httpx.TransportError:
            if attempt == RETRIES:
                raise
            time.sleep(attempt)
    raise AssertionError("unreachable")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("api_url")
    parser.add_argument("--file", type=Path, default=DEFAULT_FILE)
    args = parser.parse_args()

    trips: list[dict[str, Any]] = json.loads(args.file.read_text(encoding="utf-8"))
    outcomes: Counter[int] = Counter()
    problems: list[str] = []
    with httpx.Client(base_url=args.api_url, timeout=15) as client:
        for trip in trips:
            response = post_with_retry(client, trip)
            outcomes[response.status_code] += 1
            if response.status_code not in (200, 201):
                problems.append(f"{trip['id']}: {response.status_code} {response.text}")

    print(
        f"{len(trips)} trips -> created {outcomes[201]}, already there {outcomes[200]}, "
        f"failed {len(problems)}"
    )
    for problem in problems:
        print("  " + problem)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
