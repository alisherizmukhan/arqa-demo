import os

# Tests run outside the Docker image: the local database URL default applies,
# and nothing may require production settings.
os.environ.setdefault("APP_ENV", "test")
