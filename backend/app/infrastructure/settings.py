import re
from pathlib import Path
from typing import Literal, Self

from pydantic import Field, SecretStr, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

from app.domain.geo import ServiceArea
from app.domain.user import DemoAccount, Role

_REPO_SEED_FILE = Path(__file__).resolve().parents[3] / "data" / "trips.json"

# Local development and tests only: the docker-compose database.
LOCAL_DATABASE_URL = "postgresql://postgres:postgres@localhost:5433/driver_diary"

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

    # The Docker image sets APP_ENV=production: there DATABASE_URL is required
    # and nothing falls back to localhost.
    app_env: Literal["local", "test", "production"] = "local"
    database_url: str = ""
    port: int = 8000
    # Every endpoint except /health and /auth/login needs a bearer token. Off
    # (production until the app supports login): requests without a token act
    # as user_1, like before accounts existed; a token that is sent is checked.
    auth_required: bool = True
    # Where the client IP comes from (login rate limit), see app/api/client_ip.py:
    # a header our proxy sets and overwrites (Railway: "x-real-ip"), or else the
    # last TRUSTED_PROXY_HOPS entries of X-Forwarded-For; neither: the peer.
    client_ip_header: str | None = None
    trusted_proxy_hops: int = Field(default=0, ge=0)
    # One switch for all demo data: the demo accounts and the trips file.
    seed_on_startup: bool = True
    seed_file: Path = _REPO_SEED_FILE
    # Demo credentials from the assignment (README warns about them); production
    # overrides them with SEED_*_PASSWORD, without code changes.
    seed_admin_password: str = "admin"  # noqa: S105
    seed_user1_password: str = "password_1"  # noqa: S105
    seed_user2_password: str = "password_2"  # noqa: S105
    log_level: str = "INFO"
    # Browser origins allowed to call the API (Flutter web). JSON list in env,
    # e.g. CORS_ORIGINS='["https://example.com"]'. Public, read-mostly API: "*".
    cors_origins: list[str] = ["*"]
    # Maps (docs/MAPS.md). Without a key routes fall back to straight lines
    # and address lookups answer 503. The key never leaves the backend.
    ors_api_key: SecretStr | None = None
    ors_base_url: str = "https://api.openrouteservice.org"
    ors_timeout_seconds: float = Field(default=5.0, gt=0)
    # The service area: places outside it are rejected (Almaty).
    area_south: float = 43.05
    area_north: float = 43.45
    area_west: float = 76.70
    area_east: float = 77.20
    # Per user, all /geo endpoints and route rebuilds together.
    geo_requests_per_minute: int = Field(default=30, gt=0)
    geo_cache_hours: int = Field(default=24, gt=0)

    @model_validator(mode="after")
    def _require_database_url_in_production(self) -> Self:
        if not self.database_url:
            if self.app_env == "production":
                raise ValueError("DATABASE_URL must be set when APP_ENV=production")
            self.database_url = LOCAL_DATABASE_URL
        return self

    @property
    def demo_accounts(self) -> list[DemoAccount]:
        return [
            DemoAccount(
                login="user_1",
                password=self.seed_user1_password,
                role=Role.DRIVER,
                display_name="Водитель 1",
            ),
            DemoAccount(
                login="user_2",
                password=self.seed_user2_password,
                role=Role.DRIVER,
                display_name="Водитель 2",
            ),
            DemoAccount(
                login="admin",
                password=self.seed_admin_password,
                role=Role.ADMIN,
                display_name="Администратор",
            ),
        ]

    @property
    def service_area(self) -> ServiceArea:
        return ServiceArea(
            south=self.area_south, north=self.area_north, west=self.area_west, east=self.area_east
        )

    @property
    def ors_key(self) -> str | None:
        """The key, or None when unset or blank."""
        value = self.ors_api_key.get_secret_value().strip() if self.ors_api_key else ""
        return value or None

    @property
    def async_database_url(self) -> str:
        return to_async_database_url(self.database_url)
