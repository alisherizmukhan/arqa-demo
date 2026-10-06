import re
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

_REPO_SEED_FILE = Path(__file__).resolve().parents[3] / "data" / "trips.json"

_SYNC_SCHEMES = {"postgres", "postgresql", "postgresql+psycopg", "postgresql+psycopg2"}
_ASYNC_SCHEME = "postgresql+asyncpg"


def to_async_database_url(url: str) -> str:
    """Turn a libpq-style URL (as Railway provides) into an asyncpg SQLAlchemy URL.

    - postgres:// / postgresql:// -> postgresql+asyncpg://
    - ?sslmode=... -> ?ssl=... (asyncpg does not understand libpq's sslmode)
    """
    scheme, sep, rest = url.partition("://")
    if not sep:
        raise ValueError("DATABASE_URL must look like postgresql://user:pass@host:port/db")
    if scheme in _SYNC_SCHEMES:
        scheme = _ASYNC_SCHEME
    elif scheme != _ASYNC_SCHEME:
        raise ValueError(f"unsupported DATABASE_URL scheme {scheme!r}")
    rest = re.sub(r"([?&])sslmode=", r"\1ssl=", rest)
    return f"{scheme}://{rest}"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    database_url: str = "postgresql://postgres:postgres@localhost:5433/driver_diary"
    port: int = 8000
    seed_on_startup: bool = True
    seed_file: Path = _REPO_SEED_FILE
    log_level: str = "INFO"

    @property
    def async_database_url(self) -> str:
        return to_async_database_url(self.database_url)
