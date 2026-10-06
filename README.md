# Driver Shift Diary

Daily trips and payout summary for ride-hailing drivers: a Flutter app (`apps/mobile`), a design kit (`packages/design_kit`), and a FastAPI backend (`backend`).

> Work in progress — full README (screenshots, mobile app) comes in stage 6.

**Deployed API:** https://api-production-6e8b.up.railway.app — Swagger UI at [`/docs`](https://api-production-6e8b.up.railway.app/docs), e.g. [`/summary?date=2026-10-01`](https://api-production-6e8b.up.railway.app/summary?date=2026-10-01).

## Layout

```
apps/mobile/            Flutter app (Riverpod, clean architecture)
packages/design_kit/    Design tokens, themes, components + example/ showcase
backend/                FastAPI service + Dockerfile for Railway
data/trips.json         Seed data
docs/                   DECISIONS.md, AI_NOTES.md
docker-compose.yml      Local Postgres
```

## Quick checks

```bash
# Dart / Flutter (from repo root — pub workspace)
flutter pub get
flutter analyze
(cd packages/design_kit && flutter test)
(cd apps/mobile && flutter test)

# Backend
cd backend
uv sync
uv run ruff format --check . && uv run ruff check . && uv run mypy
uv run pytest

# Local Postgres
docker compose up -d db
```

## Backend locally

```bash
docker compose up -d db                       # Postgres 16 on localhost:5433 (+ driver_diary_test DB)
cd backend
uv sync
uv run alembic upgrade head                   # create schema
uv run python -m app                          # http://127.0.0.1:8000/docs  (seeds data/trips.json if empty)
uv run pytest                                 # unit + integration (Windows: uv run python -m pytest)
```

Demo data: `data/trips.json` (131 trips, 2026-09-21 .. 10-06) is seeded into an empty database on startup. To regenerate it or load it into an already running API (idempotent, through `POST /trips`):

```bash
uv run python scripts/generate_demo_trips.py
uv run python scripts/load_trips.py https://api-production-6e8b.up.railway.app
```

Or the whole stack in Docker: `docker compose --profile full up --build` → http://localhost:8000/docs.

Config (env): `DATABASE_URL` (`postgresql://…` is converted to `postgresql+asyncpg://`), `PORT`, `SEED_ON_STARTUP` (default `true`), `SEED_FILE`, `CORS_ORIGINS` (JSON list, default `["*"]`).

## Deploy to Railway

The image is built from the repo root with `backend/Dockerfile`; healthcheck `/health`. The container runs `alembic upgrade head` and then uvicorn on `$PORT`.

> `railway.json` documents the build/deploy config, but Railway (CLI 5.52, Oct 2026) has deprecated config-as-code and no longer applies it to **new** services. Set the same values once on the service (step marked ⚙ below — dashboard → Settings works too).

```bash
railway login
railway init --name driver-shift-diary          # new project
railway add --database postgres                 # managed Postgres
railway add --service api                       # empty service for the API
# Link the database: a reference variable, resolved by Railway to the private URL
railway variable set 'DATABASE_URL=${{Postgres.DATABASE_URL}}' --service api
# ⚙ Builder = Dockerfile at backend/Dockerfile, healthcheck /health (dashboard → api → Settings,
#   or Railway MCP `update-service` with dockerfilePath/healthcheckPath)
railway up --service api                        # build & deploy from the repo root
railway domain --service api                    # public https URL
```

`.railwayignore` keeps the Flutter code out of the upload.
