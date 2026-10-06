# Decisions

Short format: **decision** → why.

## Repository & tooling (stage 1)

- **Pub workspace with three members: `apps/mobile`, `packages/design_kit`, `packages/design_kit/example`; one root `pubspec.lock`.** → One dependency resolution for all Dart code, so the kit and the app can't drift onto different versions of Flutter libraries. The example is a member so it resolves `design_kit` from source.
- **Flutter 3.47.6 / Dart 3.13 (current stable), pinned in CI.** → CI analyzes with the same SDK as local development, so lint results match.
- **`very_good_analysis` 11 + `strict-casts`, `strict-inference`, `strict-raw-types`.** → Strictest common lint set. `public_member_api_docs` is off for the app and the example (application code, not a public API) and on for `design_kit` (a reusable package).
- **Generated Dart code (`*.g.dart`, `*.freezed.dart`) is committed; CI re-runs `build_runner` and fails on diff.** → A reviewer can `flutter run` without code generation, and CI still guarantees the generated files are fresh.
- **Flutter platforms: android, ios, web.** → Web lets anyone run the app and the kit showcase in Chrome without an emulator (also used for README screenshots).
- **Backend managed by `uv` (`package = false`, app run from `backend/`); dev tools in a `dev` dependency group; lockfile committed and CI uses `uv sync --locked`.** → Reproducible installs, and the Docker image can use the same lock.
- **Ruff with a broad rule set (incl. `DTZ` for naive datetimes, `S`, `ASYNC`) + `mypy --strict` with the pydantic plugin.** → `DTZ` in particular catches naive `datetime.now()`-style bugs, which matter for day boundaries.
- **Postgres 16 in docker-compose and in the CI service container; a separate `driver_diary_test` database (created by an init script).** → Integration tests run against real Postgres (needed for `ON CONFLICT` and concurrency), without touching dev data.
- **CI: three jobs (`backend`, `design_kit`, `mobile`), `--fatal-infos` on analyze, format check on both stacks.** → Matches the "zero warnings" requirement and keeps the jobs independent and parallel.

## Data

- **Trip `id` is an opaque string (1–64 chars of `[A-Za-z0-9_-]`), not a strict UUID column; the mobile client always generates UUID v4.** → The assignment's own input file uses ids like `t1`, and the seed must load as-is. Idempotency only requires a unique client-generated key, not the UUID format specifically.
- **Seed data (`data/trips.json`) extends the assignment's two trips with edge cases:** `t4` crosses midnight (23:50–00:20, belongs to 2026-09-30); `t5` is written in UTC (`19:30Z` on 10-01 = 00:30 on 10-02 in +05:00, so it belongs to 10-02). The reference day 2026-10-01 still contains exactly `t1` and `t2` (3900 / 585 / 3315, cash 1500 / card 2400). → The demo data exercises the tricky day-boundary cases while keeping the reference case intact.
