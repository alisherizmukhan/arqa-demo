import os

# Tests run outside the Docker image: the local database URL default applies,
# and nothing may require production settings.
os.environ.setdefault("APP_ENV", "test")

# App startup in tests (migrated schema, seeding, argon2) can be slow on a busy
# CI runner; asgi-lifespan's default of 5 s made tests flaky.
STARTUP_TIMEOUT = 60
