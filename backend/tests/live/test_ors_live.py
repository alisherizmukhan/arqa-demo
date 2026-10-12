"""One real round trip to OpenRouteService (tagged `live`, never in CI).

    RUN_LIVE=1 uv run pytest -m live

Reads ORS_API_KEY from backend/.env (tests/conftest.py blanks the variable so
nothing else can reach the network). Uses 3 requests of the daily quota.
"""

import os
import re
from pathlib import Path

import httpx
import pytest

from app.domain import polyline
from app.domain.route import RouteStatus
from app.infrastructure.ors import OrsClient
from tests.factories import ALMATY, BAZAAR, ESENTAI

ENV_FILE = Path(__file__).resolve().parents[2] / ".env"

pytestmark = [
    pytest.mark.live,
    pytest.mark.skipif(not os.environ.get("RUN_LIVE"), reason="set RUN_LIVE=1 to call ORS"),
]


def _key() -> str:
    if ENV_FILE.is_file():
        for line in ENV_FILE.read_text(encoding="utf-8").splitlines():
            if match := re.fullmatch(r"\s*ORS_API_KEY\s*=\s*(.*?)\s*", line):
                return match[1].strip("\"'")
    pytest.skip("ORS_API_KEY is not in backend/.env")


async def test_ors_builds_a_route_and_finds_addresses_in_almaty() -> None:
    async with httpx.AsyncClient(base_url="https://api.openrouteservice.org", timeout=10) as http:
        ors = OrsClient(http, _key())

        route = await ors.route(BAZAAR.point, ESENTAI.point)
        label = await ors.reverse(BAZAAR.point)
        found = await ors.search("зелёный базар", ALMATY, 5)

    assert route.status is RouteStatus.READY
    assert route.polyline is not None
    assert 5_000 < (route.distance_m or 0) < 12_000
    points = polyline.decode(route.polyline)
    assert all(ALMATY.contains(p) for p in points)
    assert label
    assert "Казахстан" not in label
    assert any("базар" in r.label.lower() for r in found)
