"""HTTP behaviour that needs no database: CORS and the /health failure path."""

from collections.abc import AsyncIterator
from pathlib import Path

import pytest
from asgi_lifespan import LifespanManager
from httpx import ASGITransport, AsyncClient

from app.infrastructure.settings import Settings
from app.main import create_app

# Nothing listens on port 1, so every connection attempt fails fast.
UNREACHABLE_DB = "postgresql://postgres:postgres@127.0.0.1:1/none"


@pytest.fixture
async def client() -> AsyncIterator[AsyncClient]:
    app = create_app(Settings(database_url=UNREACHABLE_DB, seed_on_startup=False))
    async with (
        LifespanManager(app),
        AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c,
    ):
        yield c


async def test_health_reports_unavailable_database(client: AsyncClient) -> None:
    response = await client.get("/health")

    assert response.status_code == 503
    assert response.json() == {
        "error": {
            "code": "database_unavailable",
            "message": "database is unavailable",
            "field": None,
        }
    }


async def test_cors_preflight_allows_browser_clients(client: AsyncClient) -> None:
    response = await client.options(
        "/trips",
        headers={
            "Origin": "http://localhost:5000",
            "Access-Control-Request-Method": "POST",
            "Access-Control-Request-Headers": "content-type",
        },
    )

    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == "*"
    assert "POST" in response.headers["access-control-allow-methods"]


async def test_cors_origins_are_configurable() -> None:
    app = create_app(
        Settings(
            database_url=UNREACHABLE_DB,
            seed_on_startup=False,
            cors_origins=["https://app.example"],
        )
    )
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        response = await c.options(
            "/summary",
            headers={"Origin": "https://evil.example", "Access-Control-Request-Method": "GET"},
        )

    assert "access-control-allow-origin" not in response.headers


async def test_unreachable_database_does_not_block_startup(
    tmp_path: Path, caplog: pytest.LogCaptureFixture
) -> None:
    app = create_app(
        Settings(
            database_url=UNREACHABLE_DB,
            seed_on_startup=True,
            seed_file=tmp_path / "missing.json",
        )
    )

    async with LifespanManager(app):
        pass

    assert "seed skipped: database unavailable" in caplog.text
