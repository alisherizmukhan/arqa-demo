import os

# Tests run outside the Docker image: the local database URL default applies,
# and nothing may require production settings.
os.environ.setdefault("APP_ENV", "test")

# No real network in tests: Settings would read ORS_API_KEY from backend/.env;
# an environment variable wins over the file, so blank it here. The `live`
# tests (tests/live) read the key from the file themselves.
os.environ["ORS_API_KEY"] = ""

# The background route retries call the map service on their own schedule;
# the tests that cover them turn them on explicitly.
os.environ["ROUTE_RETRIES_ENABLED"] = "false"

# App startup in tests (migrated schema, seeding, argon2) can be slow on a busy
# CI runner; asgi-lifespan's default of 5 s made tests flaky.
STARTUP_TIMEOUT = 60
