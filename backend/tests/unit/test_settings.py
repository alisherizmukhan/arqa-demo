import pytest

from app.infrastructure.settings import LOCAL_DATABASE_URL, Settings, to_async_database_url


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


def test_production_refuses_to_start_without_database_url(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.delenv("DATABASE_URL", raising=False)
    monkeypatch.setenv("APP_ENV", "production")

    with pytest.raises(ValueError, match="DATABASE_URL must be set"):
        Settings(_env_file=None)


@pytest.mark.parametrize("env", ["local", "test"])
def test_local_and_test_fall_back_to_the_compose_database(
    monkeypatch: pytest.MonkeyPatch, env: str
) -> None:
    monkeypatch.delenv("DATABASE_URL", raising=False)
    monkeypatch.setenv("APP_ENV", env)

    settings = Settings(_env_file=None)

    assert settings.database_url == LOCAL_DATABASE_URL


def test_demo_passwords_come_from_env(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("SEED_ADMIN_PASSWORD", "a")
    monkeypatch.setenv("SEED_USER1_PASSWORD", "b")
    monkeypatch.setenv("SEED_USER2_PASSWORD", "c")

    accounts = {a.login: a.password for a in Settings().demo_accounts}

    assert accounts == {"admin": "a", "user_1": "b", "user_2": "c"}
