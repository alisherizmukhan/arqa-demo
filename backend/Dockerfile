# Build context is the REPOSITORY ROOT (so data/trips.json can be copied):
#   docker build -f backend/Dockerfile .
# No BuildKit cache mounts: Railway requires service-specific cache ids for them.

# ---- build: resolve the locked dependencies into a virtualenv ----
FROM python:3.12-slim-bookworm AS builder
COPY --from=ghcr.io/astral-sh/uv:0.12.23 /uv /bin/uv

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never \
    UV_PROJECT_ENVIRONMENT=/app/.venv

WORKDIR /app
COPY backend/pyproject.toml backend/uv.lock backend/.python-version ./
RUN uv sync --locked --no-dev --no-install-project

COPY backend/alembic.ini ./
COPY backend/migrations ./migrations
COPY backend/app ./app

# ---- runtime: no uv, no build tools, non-root ----
FROM python:3.12-slim-bookworm AS runtime

RUN useradd --create-home --uid 10001 app
WORKDIR /app
COPY --from=builder --chown=app:app /app /app
COPY --chown=app:app data/trips.json /app/data/trips.json

ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    SEED_FILE=/app/data/trips.json \
    PORT=8000

USER app
EXPOSE 8000

# Migrate, then serve. `exec` makes uvicorn PID 1 so it receives SIGTERM on redeploys.
CMD ["sh", "-c", "alembic upgrade head && exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT} --proxy-headers --forwarded-allow-ips='*'"]
