# Driver Shift Diary

Daily trips and payout summary for ride-hailing drivers: a Flutter app (`apps/mobile`), a design kit (`packages/design_kit`), and a FastAPI backend (`backend`).

> Work in progress — full README (how to run, deployed API link, screenshots) comes in stage 6.

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
