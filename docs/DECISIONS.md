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

## Backend domain (stage 2)

- **Entities are frozen dataclasses that validate in `__post_init__`.** → An invalid `Trip` cannot exist anywhere in the backend; the API and DB layers reuse the same rules instead of duplicating them.
- **Only the first rule violation is reported.** → Matches the single-error response shape `{error: {code, message, field}}`; the client validates the same rules locally anyway.
- **Stable error `code`s; `message` is English, for developers.** → The Russian-language client maps `code` to its own text, so the server stays language-agnostic.
- **Money rules: `type(x) is int` (rejects `bool` and `float`), `0 < amount ≤ 10 000 000`, `0 ≤ commission ≤ amount`.** → The cap is a sanity limit, far above any real fare. It keeps sums well inside `BIGINT` and catches typos like an extra `000`.
- **`payment` parsing is strict and case-sensitive (`cash` / `card`).** → One canonical form on the wire and in the DB.
- **Timezone = fixed UTC offset (`±HH:MM` or `Z`, range ±14:00), not an IANA zone name.** → The API contract uses `tz=+05:00`. Kazakhstan has used a single +05:00 offset with no DST since 2024, so a local day is always exactly 24h.
- **A day is the half-open interval `[00:00, next 00:00)` in the driver's offset; a trip belongs to the day of its `start`.** → `23:59:59.999999` is inside the day and `00:00:00` of the next day is not. A trip crossing midnight is counted on its start day only.
- **`DayWindow` exposes the day as a UTC interval (`start_utc`, `end_utc`).** → The repository filters by `start >= start_utc AND start < end_utc` on the UTC `TIMESTAMPTZ` column, which can use an index and never depends on the DB session timezone. A hypothesis test proves the UTC interval and the local-calendar definition always agree.
- **Payload equality for idempotency compares instants, not offset notation.** → `08:10+05:00` and `03:10Z` are the same trip, so re-sending it in a different notation is not a 409.
- **`calculate_daily_summary` raises if given a trip from another day, instead of filtering it out.** → A trip from the wrong day there means a repository bug; failing loudly beats silently wrong money totals.
- **Cash/card split uses an exhaustive `match` + `assert_never`.** → Adding a payment method becomes a type error instead of being silently counted as card.
- **`hypothesis` for property tests (summary invariants, UTC window vs. local day).** → Example-based tests cover the named edge cases; properties cover the input space around them.

## Backend persistence & API (stage 3)

- **Idempotency = `INSERT … ON CONFLICT (id) DO NOTHING RETURNING id`, then read and compare the stored trip.** → The primary key decides atomically. A concurrent insert of the same id waits for the first transaction, inserts nothing, and then reads the winner. No check-then-insert anywhere.
- **The repository commits right after the insert (one transaction per insert).** → The row is visible to concurrent requests as early as possible, and the use case stays free of transaction plumbing.
- **Responses: 201 new / 200 same payload (returns the *stored* record) / 409 different payload.** → As specified. The 200 body is the stored trip, so a retry sees exactly what the first call created.
- **Columns `start_at` / `end_at` (`TIMESTAMPTZ`), money `BIGINT`, `payment` as `VARCHAR` + `CHECK`; all domain rules repeated as DB `CHECK` constraints; index on `start_at`.** → `END` is a reserved SQL word. `CHECK` on a varchar is easier to evolve than a native PG enum. The constraints are defense-in-depth if someone writes to the DB directly.
- **Day queries use the UTC half-open interval from `DayWindow` (`start_at >= :a AND start_at < :b`).** → Uses the index and never depends on the DB session timezone.
- **The summary is computed in Python by the domain function, not with SQL `SUM`.** → One source of truth for the money rules (the same function is unit-tested). A day has tens of trips, so there's no performance concern.
- **Pydantic checks types only (`StrictInt`, aware ISO-8601 strings, enum); the domain checks business rules.** → One place for the rules, and every error gets a stable domain `code`. Pydantic errors are mapped to the same `{error: {code, message, field}}` shape (only the first error is returned).
- **Timestamps must be ISO strings; numbers are rejected (custom `BeforeValidator`).** → FastAPI validates decoded JSON in Python mode. `Strict()` would reject ISO strings there, and lax mode would accept unix timestamps.
- **`GET` responses render times in the requested `tz`; the `POST` response uses the offset of the submitted `start`.** → The client receives times in the zone it works in. Instants are identical either way.
- **`GET /trips` returns `{date, tz, trips: [...]}` rather than a bare list.** → It echoes the resolved day/offset and can grow (paging, totals) without a breaking change.
- **Query `tz`: a leading space is treated as `+`.** → `?tz=+05:00` without URL encoding decodes to `" 05:00"`; drivers' clients and curl users would otherwise get a confusing 422. The domain parser itself stays strict.
- **`date` must match `YYYY-MM-DD` exactly and be a real calendar date (custom parsing).** → Pydantic's lax `date` also accepts other formats and numbers.
- **All errors — including 404/405/500 — use the error shape; the default `HTTPValidationError` schema is replaced in OpenAPI.**
- **`/health` runs `SELECT 1` and returns 503 if the DB is down.** → The Railway healthcheck then fails a deploy that can't reach its database.
- **Seed on startup only if the table is empty; each insert is idempotent.** → Safe on restarts and with several replicas starting at once.
- **Settings via pydantic-settings: `DATABASE_URL` (`postgres://`/`postgresql://` → `postgresql+asyncpg://`, `sslmode` → `ssl`), `PORT`, `SEED_ON_STARTUP`, `SEED_FILE`.**
- **Docker: multi-stage, uv pinned (0.12.23), `uv sync --locked --no-dev`, non-root user, build context = repo root (`-f backend/Dockerfile`) so the seed file is included; no BuildKit cache mounts.** → Railway rejects cache mounts without its service-specific ids.
- **Local Postgres on host port 5433 (configurable via `POSTGRES_PORT`).** → 5432 is commonly taken by another local Postgres.
- **Integration tests: real Postgres, schema reset via `alembic downgrade base && upgrade head` once per session (so the downgrade is tested too), `TRUNCATE` per test; skipped locally if the DB is unreachable, but a failure when `CI` is set.**
