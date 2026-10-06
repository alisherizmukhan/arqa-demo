import pytest

from app.infrastructure.settings import Settings, to_async_database_url


@pytest.mark.parametrize(
    ("raw", "expected"),
    [
        ("postgresql://u:p@host:5432/db", "postgresql+asyncpg://u:p@host:5432/db"),
        ("postgres://u:p@host:5432/db", "postgresql+asyncpg://u:p@host:5432/db"),
        ("postgresql+psycopg2://u:p@host/db", "postgresql+asyncpg://u:p@host/db"),
        ("postgresql+asyncpg://u:p@host/db", "postgresql+asyncpg://u:p@host/db"),
        (
            "postgresql://u:p@host/db?sslmode=require",
            "postgresql+asyncpg://u:p@host/db?ssl=require",
        ),
        (
            "postgresql://u:p@host/db?application_name=x&sslmode=disable",
            "postgresql+asyncpg://u:p@host/db?application_name=x&ssl=disable",
        ),
    ],
)
def test_database_url_is_converted_for_asyncpg(raw: str, expected: str) -> None:
    assert to_async_database_url(raw) == expected


@pytest.mark.parametrize("raw", ["mysql://u:p@host/db", "not a url", ""])
def test_unsupported_database_url_is_rejected(raw: str) -> None:
    with pytest.raises(ValueError, match="DATABASE_URL"):
        to_async_database_url(raw)


def test_settings_read_railway_env(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv(
        "DATABASE_URL", "postgresql://railway:secret@postgres.railway.internal:5432/railway"
    )
    monkeypatch.setenv("PORT", "8080")

    settings = Settings()

    assert settings.port == 8080
    assert settings.async_database_url == (
        "postgresql+asyncpg://railway:secret@postgres.railway.internal:5432/railway"
    )
