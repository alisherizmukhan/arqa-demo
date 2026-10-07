# Driver Shift Diary

Daily trips and payout summary for ride-hailing drivers: a Flutter app (`apps/mobile`), a design kit (`packages/design_kit`), and a FastAPI backend (`backend`).

| Day (light) | Day (dark) | Add trip | No connection | 409 conflict | Date | Time |
|---|---|---|---|---|---|---|
| <img src="docs/screenshots/day_light.png" width="180"> | <img src="docs/screenshots/day_dark.png" width="180"> | <img src="docs/screenshots/add_trip.png" width="180"> | <img src="docs/screenshots/add_trip_offline.png" width="180"> | <img src="docs/screenshots/add_trip_409.png" width="180"> | <img src="docs/screenshots/date_picker.png" width="180"> | <img src="docs/screenshots/time_picker.png" width="180"> |

The UI follows `DESIGN.md` (variant A) and the mockups in `docs/design/`. Side-by-side comparisons are in `docs/design/audit/stage4/` and `stage5/`, and every deviation is listed in `docs/DESIGN_AUDIT.md` and `docs/DECISIONS.md`. The screenshots above are rendered by the app's own tests (see *Screenshots and goldens*).

**Deployed API:** https://api-production-6e8b.up.railway.app — Swagger UI at [`/docs`](https://api-production-6e8b.up.railway.app/docs), e.g. [`/summary?date=2026-10-01`](https://api-production-6e8b.up.railway.app/summary?date=2026-10-01).

## Layout

```
apps/mobile/            Flutter app (Riverpod, clean architecture)
packages/design_kit/    Design tokens, themes, components + example/ showcase
backend/                FastAPI service + Dockerfile for Railway
data/trips.json         Seed data
docs/                   DECISIONS.md, AI_NOTES.md, DESIGN_AUDIT.md, design/ (mockups), screenshots/
DESIGN.md               Visual spec: tokens, components, screens, copy, acceptance checklist
docker-compose.yml      Local Postgres
```

## Quick checks

```bash
# Dart / Flutter (from repo root — pub workspace)
flutter pub get
flutter analyze
(cd packages/design_kit && flutter test)
(cd packages/design_kit/example && flutter test)
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

## Mobile app

```bash
cd apps/mobile
flutter run -d chrome                                    # uses the deployed API
flutter run --dart-define=API_URL=http://10.0.2.2:8000   # Android emulator -> local backend
flutter test                                             # unit, provider and widget tests
LIVE_API_URL=http://127.0.0.1:8000 flutter test test/live   # contract tests against a running backend
dart run build_runner build                              # after changing DTOs or providers
```

Config: `--dart-define=API_URL=...` (default: the Railway URL), `--dart-define=DRIVER_TZ=+05:00`.

**Selecting the trip date.** The form has no date field. A new trip starts on **the day selected on the Day screen**, and the form shows that day under its title. To add a trip for another day, switch the day first: use the arrows, or tap the date to open the calendar (up to today). An end time at or before the start time means the trip ended the next day, shown with «+1 день». The trip still belongs to its start day, and the form allows at most 12 h.

**Sending.** Saving uses an idempotency key (the trip id). If the connection drops, or the server answers 5xx or times out, the form shows «Нет связи…». It then resends the same trip with the same id after 2, 4 and 8 s, then every 30 s, and «Повторить» resends at once. A 4xx answer is never resent: 422 shows under the field, and 409 opens the conflict dialog.

## Design kit

`packages/design_kit` is the only place with colours, type, spacing, radii, shadows, icons and formatting. The app reads tokens through `context.dkColors`, `context.dkText`, `context.dkSpacing` and similar accessors, and builds its screens only from `Dk*` components. CI fails on `Color(0x`, `Colors.` or `TextStyle(` in `apps/mobile/lib`.

- **Tokens:** `DkColors`, `DkTypography`, `DkSpacing`, `DkRadii`, `DkElevation`, `DkSizes` and `DkMotion`, with light and dark themes in `DkTheme`. `spec_conformance_test.dart` parses `DESIGN.md` and checks every value.
- **Fonts:** Manrope 500–800, with IBM Plex Sans as the fallback for `₸` and the narrow no-break space (U+202F), which Manrope lacks. Figures are tabular.
- **Components:** buttons and the FAB, cards, the summary and payment cards, trip tiles and list, the day switcher, text, money and time fields, the badge, the segmented control, snackbars, the dialog, empty, error and skeleton states, and the modal app bar and bottom bar.
- **Formatting:** `DkMoney` (`3 315 ₸` with U+202F, `−585 ₸` with U+2212) and `DkFormat` (Russian dates, relative day, durations, plurals, split percentages).

**Example app** — every component in every state, light and dark, plus a token sheet:

```bash
cd packages/design_kit/example
flutter run -d chrome          # web: append ?theme=dark and/or ?tab=tokens to the URL
flutter test                   # every component renders; no overflow at 360 dp in both themes
```

## Screenshots and goldens

Golden tests use [alchemist](https://pub.dev/packages/alchemist) and come in two kinds:

| | Where | Text | Compared |
|---|---|---|---|
| Platform goldens | `test/goldens/<os>/` (e.g. `windows/`) | real Manrope / IBM Plex Sans, for review | locally only (when `CI` is not set) |
| CI goldens | `test/goldens/ci/` (app: `test/screens/goldens/ci/`) | drawn as blocks | only when `CI` is set (GitHub Actions) |

```bash
# Locally: regenerate this OS's real-font goldens after an intended visual change
(cd packages/design_kit && flutter test --update-goldens)
(cd apps/mobile && flutter test --update-goldens test/screens/day_golden_test.dart)

# CI goldens: generated on Linux in Docker (font metrics differ between OSes, so never on Windows/macOS)
tool/update_ci_goldens.sh                       # packages/design_kit
tool/update_ci_goldens.sh apps/mobile           # the app's Day goldens

# App screenshots at 390×844 @2x with real fonts (the README images and docs/design/audit/*)
cd apps/mobile && SCREENSHOTS_DIR=build/screens flutter test test/screens/screenshots_test.dart
```

The app's layout matrix (`test/screens/layout_matrix_test.dart`) renders every state at 390×844 and 360×780, with text scale 1.0 and 1.3 and the real fonts, and fails on any overflow or truncated text. `accessibility_test.dart` checks tap targets, labels and contrast in both themes.

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
