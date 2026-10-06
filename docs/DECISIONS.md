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
- **Railway: `railway.json` (config as code) kept, although the CLI (5.52) now warns it is deprecated in favor of `.railway/railway.ts` and supported until 2026-12-01.** → The assignment asks for `railway.json`. **However, Railway refuses to attach a config file to a new service** ("Config as Code is deprecated"), so the live `api` service has the same values set as service settings (builder Dockerfile at `backend/Dockerfile`, healthcheck `/health` with a 120 s timeout, restart ON_FAILURE ×5). `railway.json` stays as the documented source of those values. Moving to `.railway/railway.ts` IaC is the long-term fix.
- **Railway services: `api` (Dockerfile) + `Postgres`; `DATABASE_URL=${{Postgres.DATABASE_URL}}` reference variable (private network); `.railwayignore` excludes the Flutter code from uploads.**

## Design kit (stage 4)

- **Design direction from ui-ux-pro-max, filtered** (full trace in `packages/design_kit/DESIGN.md`): OLED dark style + green-for-earnings and slate neutrals kept; "light mode not recommended", the landing-page pattern and the serif body font rejected. → Drivers work in sunlight *and* at night, so both themes are needed; the skill's output was a recommendation, not a spec.
- **IBM Plex Sans, bundled unmodified (variable font, 537 KB).** → Cyrillic + `₸` + tabular digits by default, checked with fontTools. Bundled rather than `google_fonts` (no runtime download on a flaky mobile connection). Unmodified because the OFL reserves the name "Plex" for modified versions, so subsetting would have forced a rename. Weights are set via the `wght` axis (`FontVariation`) as well as `fontWeight`.
- **Light green is darkened to `#15803D`; every color pair is unit-tested against WCAG AA in both themes.**
- **Money formatting lives in the kit (`DkMoney.format`, pure Dart, no `intl`); components take `int` tenge.** → One implementation of `3 315 ₸` (no-break spaces, real minus sign) for the app and the showcase; components cannot be given an unformatted or float amount.
- **The kit has Russian default strings, all overridable.** → The product is Russian-only; parameters keep the kit reusable.
- **Components are dumb: `DkDaySwitcher` takes a formatted label and callbacks; date pickers and date formatting stay in the app.** → Locale/intl setup belongs to the app.
- **`DkSegmentedControl` added (not in the required list), built from custom 56dp segments rather than Flutter's `SegmentedButton`.** → The add-trip form needs a payment choice from the kit, and `SegmentedButton` draws a fixed ~40dp box regardless of `minimumSize` (read in the SDK source).
- **`DkPaymentKind` is a kit enum, mapped from the app's domain `PaymentMethod`.** → The kit must not depend on the app.
- **Material outlined icons, no extra icon package.** → One consistent family; the skill's Phosphor default targets web/React.
- **Accessibility enforced by tests**: Flutter's tap-target, labeled-target and text-contrast guidelines on a gallery of all interactive components in both themes, plus a 360dp no-overflow test of the showcase.
- **No golden tests.** → Font rasterization differs between Windows and the Linux CI runner, so goldens would be flaky; screenshots come from the web build in headless Edge.

## Backend hardening & demo data (before stage 5)

- **Supported dates 2000-01-01 .. 2099-12-31** (trip timestamps → `datetime_out_of_range`; `date` query → `invalid_date`). → `date=0001-01-01` and year-1 trips crashed with a 500 (overflow converting to UTC). A bounded range removes the whole class of overflow bugs.
- **A trip may last at most 24 hours (`trip_too_long`).** → A sanity cap like the amount cap: a 3-year trip was accepted before; longer than a day is a typo in the date.
- **CORS enabled (`CORS_ORIGINS`, default `*`, GET/POST, `Content-Type` only, no credentials).** → Native apps don't need it, but the Flutter web build (demo, screenshots) can't call the API without it. The API is public and unauthenticated, so `*` exposes nothing extra.
- **Coverage measured and enforced in CI (`--cov-fail-under=95`; currently 99%).** `concurrency = ["greenlet", "thread"]` is required, otherwise code run through SQLAlchemy's async greenlets shows up as uncovered.
- **Demo data is generated, deterministic and loaded through the public API.** `backend/scripts/generate_demo_trips.py` keeps the hand-written edge-case trips (`t1`..`t10`, which own 2026-09-30 .. 10-03) and adds 121 realistic trips over 2026-09-21 .. 10-06 (day off 09-27; today's shift in progress; one trip crossing midnight). `scripts/load_trips.py` POSTs a file to any deployed API: it exercises the real validation and idempotency, and re-running is safe. → The startup seed only runs on an empty table (as specified), so an existing deployment gets new data via the API instead of a DB-level script.

## Mobile app (stage 5)

- **The client computes the summary from the trips it displays** (`calculateDailySummary` in the domain; `daySummaryProvider` derives from `dayTripsProvider`). → One request per day, and the card and the list can never disagree. `GET /summary` stays part of the API contract (tested on the backend). Both implementations are checked against the same reference case (3900 / 585 / 3315, cash 1500 / card 2400).
- **Driver time zone is explicit (`DriverZone`, fixed offset from `--dart-define=DRIVER_TZ`, default `+05:00`), not the phone's zone.** Instants are kept in UTC; `CalendarDay` is a date-only value. → Dart's `DateTime` is UTC-or-device-local only; using the device zone would put trips on the wrong day for a phone set to another zone. A test pins "now" at 20:00Z, which is already the next day in +05:00.
- **Idempotency key lifecycle:** the form makes a UUID v4 per save; `AddTripController` reuses the previous attempt's id when the payload is unchanged *and* the previous outcome was unknown (network error / 5xx). After a 409, a 422 or a changed payload, the new id is used. → A retry can never create a duplicate, and an edited trip is never silently swallowed as "already saved".
- **Retries happen in exactly one place: a dio `RetryInterceptor`** (2 retries at 0.5 s / 2 s for connection errors, timeouts and 502/503/504, POST included — safe because the body, and so the trip id, is identical). Riverpod 3's automatic provider retry is turned off (`ProviderScope(retry: … => null)`); the UI offers "Повторить".
- **Use cases return a sealed `Result<T>` (`Ok`/`Err`) with a sealed `Failure`** (Network / Validation / Conflict / Server / Unexpected). No FP package: Dart 3 sealed classes and pattern matching give exhaustive handling. `Failure implements Exception`, so providers throw it into `AsyncError`.
- **Validation mirrors the server and shares its codes** (`trip_rules.dart`). Client-side errors and server 422s use one Russian message table; a 422 is shown under the field it names, 409/network/server errors in a banner above "Сохранить". Money rules and time rules run independently, so each error shows as soon as its fields are filled in.
- **A trip crossing midnight is entered naturally:** an end time earlier than the start time means the next day (helper text "На следующий день"); equal times are an error.
- **Day switch shows a skeleton (`isReloading`); pull-to-refresh keeps the current data (`isRefreshing`).** → Never show the previous day's totals under the new date label.
- **DTOs use classic freezed factories, not Dart 3.13 primary constructors.** → freezed 4 generates no JSON code for primary constructors, and json_serializable 6.14 doesn't support them.
- **Russian dates are hand-formatted** (`core/format/date_format.dart`), no `intl`: no async locale initialisation, and trivially testable. Money formatting is the kit's `DkMoney.format` (one implementation for app and showcase).
- **"Add trip" is a full-width kit `DkButton` pinned at the bottom, not a FAB.** → Kit component only, a large target within thumb reach, labelled.
- **Navigation is a plain `Navigator.push` for one sub-screen.** → A router package would be unjustified for two screens.
- **Contract tests (`test/live`, tag `live`) run the real client stack against a running backend** and are skipped unless `LIVE_API_URL` is set. → They catch client/server format drift that mocks cannot.
- **Known limit:** "today" is computed when the screen builds; an app left open across midnight shows yesterday as today until the next rebuild or restart.

## Redesign to DESIGN.md variant A (stage R1 — audit)

Mockup PNG vs `DESIGN.md`: where they disagree, **DESIGN.md wins** (details and open points in `docs/DESIGN_AUDIT.md`):

- `11_add_trip_midnight` clips the end time behind the «+1 день» badge → no clipping (also required at text scale 1.3).
- `12_add_trip_conflict_409` shows time fields without the clock prefix → the time variant always has the prefix.
- `09_add_trip_saving` drops the amount helper while saving → helpers stay (DESIGN.md does not hide them; avoids a layout jump).
- `13_kit_tokens` draws `e1` as two shadows, names spacing `space4…`, omits xs/segment/segmentTrack radii → DESIGN.md values and names.
- `14_kit_components` shows other constructor APIs (`DkButton.fab`, `DkSplitBar(parts:)`, `DkTripTile(start, end, duration…)`, `DkSummaryTile(emphasis:)`) and a shorter empty-state message → DESIGN.md §4 APIs and §6 copy.
- `09` disabled segmented thumb uses a tone with no token → closest tokens (`segmentThumb`, labels `textSecondary`), per DESIGN.md's "closest existing token" rule.
