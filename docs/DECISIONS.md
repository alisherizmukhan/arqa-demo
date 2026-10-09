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
- *(Superseded for POST in stage R5, see below.)* **Retries happen in exactly one place: a dio `RetryInterceptor`** (2 retries at 0.5 s / 2 s for connection errors, timeouts and 502/503/504, POST included — safe because the body, and so the trip id, is identical). Riverpod 3's automatic provider retry is turned off (`ProviderScope(retry: … => null)`); the UI offers "Повторить".
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

## Redesign — stage R2 (tokens)

- **All §2 tokens implemented as ThemeExtensions** (`DkColors` 28 × light/dark, `DkTypography` 18 styles, `DkSpacing` s2…s64 + screenGutter, `DkRadii`, `DkElevation` light/dark, `DkSizes`) and **verified by `spec_conformance_test.dart`, which parses `packages/design_kit/DESIGN.md`** and compares every color, style (size/line/weight/letter-spacing/tnum/family/fallback), spacing step, radius and shadow. → "Exactly these values" is checked by a machine and cannot drift.
- **Manrope bundled as static 500/600/700/800 instances** cut from the Google Fonts variable font. → DESIGN.md asks for these four `.ttf` weights; Manrope's OFL declares no Reserved Font Name, so modified instances may keep the name. All four keep the `tnum` feature; every style sets `FontFeature.tabularFigures()` (Manrope digits are proportional by default).
- **IBM Plex Sans (unmodified, already bundled) is the `fontFamilyFallback`** — approved; Manrope has no `₸` (U+20B8) and no U+202F. Styles also set `FontVariation('wght', …)` so a fallback `₸` matches the surrounding weight. Golden `test/goldens/*/money_fallback.png` shows it in both themes.
- **Heights in `DkSizes` are minimums** (approved): 56/48/72 at text scale 1.0, growing with the system text scale instead of clipping.
- **Screen-level sizes from §4/§5 are tokens too:** `headerHeight` 48 (wordmark row), `appBarHeight` 56 (add-trip app bar), `wordmarkDot` 12, `spinnerStroke` 2.6. → The values are in DESIGN.md text; making them tokens keeps literals out of `apps/mobile`.
- **Motion values from §4 live in `DkMotion`:** segment 200 ms ease-out, skeleton pulse 1.4 s (1 → 0.55 → 1), highlight ~2 s, success snackbar 3 s.
- **`DkElevation.lerp` returns the target lists at t = 1**, so a light→dark theme animation ends with no shadows at all (BoxShadow lerping alone would leave zero-sized shadows in the list).
- **Field `border` changed to reach WCAG 1.4.11 (3:1) — deviation from the mockups, approved.** Spec `#D5DAE1` / `#343A43` gave 1.41:1 / 1.54:1 on `surface`. New values are the smallest change along the suggested hue that passes: light **`#8F95A0`** (3.01:1; the suggested `#959CA7` is only 2.77:1), dark **`#5F6571`** (3.01:1; the suggested `#646B77` would also pass at 3.28:1, but the same minimal rule is used in both themes). DESIGN.md (root and kit copy) updated; `divider` and `segmentThumb` unchanged. Field outlines therefore look darker than in the PNGs. Every text pair the spec uses passes 4.5:1 (unit-tested).
- **Goldens with alchemist:** CI goldens (`goldens/ci`, text as blocks) are **generated on Linux** (`tool/update_ci_goldens.sh`, Docker + Flutter 3.47.6) and compared only when `CI` is set; real-font platform goldens (`goldens/windows`) are generated and compared locally. → Even blocked-text goldens made on Windows failed on Linux (layout metrics differ), verified in a Linux container before pushing. A test helper also registers the kit fonts under `packages/design_kit/<family>`, because inside the kit's own tests the manifest uses bare family names and the goldens would otherwise render Ahem boxes.
- **Stage-4 components were only re-pointed to the new tokens** (mechanical rename keyed on `spacing.`/`colors.`/`sizes.`/`text.`) so everything compiles and stays green; they are rebuilt to §4 in stage R3.

## Redesign — stage R3 (components)

- **Digit-group gaps (approved option 2): the string keeps U+202F; rendering widens each separator to ~0.25 em** with extra letter-spacing on that character only. One implementation, `dkGroupedSpans`, is used by `DkGroupedText`/`DkMoneyText` (display) and by `DkMoneyEditingController.buildTextSpan` (the money field while typing), so gaps look identical in both. The separator's natural advance is measured once per font/size/weight, because it comes from the fallback font.
- **Money input:** `DkMoneyInputFormatter` keeps digits only (max 8, leading zeros dropped, a lone `0` kept), regroups with U+202F and places the caret by *digit count*, so typing, deleting and pasting never land inside a gap. Deleting only a separator removes the neighbouring digit (Backspace → the one before, Delete → the one after). The controller treats the two positions around a gap as one caret stop, so arrow keys step over it in one press. Widget tests cover "2400" → "2 400", Backspace across the gap, Delete, arrows and paste.
- **Icons: Lucide via `lucide_icons_flutter`, centralised in `DkIcons`.** The package ships stroke weights as separate fonts (w400 = 2.0, w500 = 2.5), so the spec's 2.4 (plus, chevron-down) uses w500 and its 2.2 (inline error) uses w400. **Empty state uses Lucide `road`, not `route`:** the spec writes "`route` (road)" and the mockup shows a road, but Lucide's `route` is a connected path. `road` exists in the fonts but has no Dart constant in this version, so it is referenced by codepoint. The mockup's road glyph itself is not in Lucide; `road` is the closest.
- **Components added beyond the §4 list,** so screens need no literals: `DkIconTile`, `DkPaymentCard`, `DkTripList` (card + inset-68 dividers), `DkListHeader`, `DkFieldMessage` (helper/error line, also used under the time row), `DkTimeField` (the "time variant" as its own widget), `DkWordmark`, `DkModalAppBar`, `DkBottomBar`, plus `DkSnackbarView` / `DkDialogView` (the visuals of `showDkSnackbar` / `showDkDialog`, also used by the showcase and goldens). `DkSegmentedControl` takes an optional `label`. `DkSummaryCard` / `DkPaymentCard` take integer tenge and format internally; the kit enum is `DkPaymentMethod` (the app maps its domain enum).
- **Values the spec gives outside the §2.2 table** are built from tokens where possible: the unselected segment (16/600) is `bodyStrong` at weight 600; the snackbar action (15/700) is `bodyStrong` at `bodyMd`'s size; only the money «₸» suffix (20/700) is a local style in `dk_inputs.dart`.
- **Time-row error shown once under the row (§5.7, mockup 08):** `DkTimeField(invalid: true)` turns the field red without its own message, and the screen places one `DkFieldMessage` under the row.
- **Time + «+1 день» never clip** (mockup 11 clips "00:2"). *Corrected in R4:* the R3 explanation ("~1 px too narrow") was wrong — `DkBadge` stretched to fill its line and so always wrapped below the time; see stage R4.
- **Trip-tile amount column is `Flexible`:** at normal sizes it keeps its natural width; with maximum amounts (10 000 000 ₸) at 360 dp or text scale 1.3, «комиссия …» wraps instead of overflowing the row (tested).
- **Snackbars are Overlay entries, one at a time:** error/info full width at a caller-given `bottom` (the form passes "12 above the bottom bar") and stay until closed or replaced; success is compact bottom-left with a `maxWidth` so it sits beside the FAB, and closes after 3 s. **Flutter has no `busy` semantics flag:** a loading `DkButton` is announced by its label («Сохраняем…») and as disabled.
- **Skeleton composites** use DESIGN.md §4 sizes; the third (count) column of the summary skeleton uses the 04_day_loading measurement (52×12 / 24×20), which lies outside §4's stated range. Lines default to radius `min(sm, height / 2)` (16 → 8, 12 → 6), which reproduces the spec's r8/r6 without a non-token radius.
- **Goldens (alchemist, §7):** DkSummaryCard, DkTripTile (card, cash, +1, highlighted), DkTextField (default/focused/error — one file per theme, because only one field per widget tree can hold focus), DkButton matrix (spinner captured at a fixed 600 ms frame) and DkDaySwitcher (date / «Сегодня»), in light and dark; CI goldens regenerated on Linux.
- **Open for stage R4:** in the narrow showcase the dialog's «Сохранить как новую поездку» wraps to two lines; it will be checked at the real dialog width (390 dp screen) when the 409 flow is built.
- **The app was only adapted to compile against the new APIs** (stage R4 rebuilds the screens): the summary is `DkSummaryCard` + `DkPaymentCard`, trips use the new `DkTripTile`, and the add-trip form uses `DkTimeField` / `DkTextField.money` with no date field (approved: the trip date is the day selected on the Day screen).

## Redesign — stage R4 (screens)

- **«+1 день» never wraps inside the end field (approved):** while the badge is shown, the end field hides its clock prefix (the start field keeps it), so time and badge fit one line at 360 dp and text scale 1.0. At 1.3 the field may grow and the badge may move below the time; the time itself never wraps (tested with the real fonts). Deviation from mockup 11, which keeps the clock and clips the time. The badge is also hidden while the end time has an error (as in mockup 08).
- **Kit bugs found by the stage-4 screenshots, fixed in the kit:** `DkBadge` filled its whole line (`Container.alignment`), the split bar's segments were 0 px high (empty boxes under loose constraints), and trip amounts stopped short of the row's right padding. The amount column now keeps its natural width without a `LayoutBuilder`, so the tile still works inside intrinsic layouts (tables, `IntrinsicHeight`). Each fix has a regression test; the payment card is covered by the new Day golden.
- **Success snackbar vs the FAB (approved):** beside the FAB (12 dp gap) when the message fits, as in mockup 06 at 390 dp; otherwise (360 dp, text scale 1.3) full width, 12 dp above the FAB. Never overlapping (tested at 390/360 and 1.0/1.3). After a save the Day screen waits for the reloaded day before showing it, so the FAB is laid out (it is absent on an empty day) and the 2 s highlight is actually visible.
- **409 dialog at 360 dp:** the label «Сохранить как новую поездку» needs ~240 dp, and a 360 dp dialog leaves 216 dp, so it wraps to two centred lines with no ellipsis, and the button grows. At 390 dp both labels fit on one line. `DkButton` now keeps the spec's insets when its label grows: 56 = 24 line + 2 × 16 (text variant 48 = 24 + 2 × 12), so 1.0 still renders exactly 56. Tested at 360/390 and 1.0/1.3.
- **409 copy (approved, no stored values):** title = §6 `conflictTitle`; message = «Обновите день, чтобы увидеть сохранённую версию.» The approved message starts with the same sentence as the title, so it is not shown twice. «Оставить сохранённую» closes the form and reloads the day; «Сохранить как новую поездку» sends the trip with a **new id**. Because any edit after a failed send also produces a new id, a 409 is rare in practice: it needs the first attempt to have reached the server *and* the payload to have changed under the same id.
- **Validation display (§5.7):** money fields show their error once they lose focus, time fields once their picker closes, and every error shows after Save. Save stays disabled while any error is visible. Empty fields say «Заполните поле». The amount rule runs on its own and no longer waits for the commission. Time problems appear as one line under the time row, and the field at fault turns red (the end, for an end-before-start trip).
- **Midnight rule (§5.10, approved 12 h):** end ≤ start on the clock means the next day, so equal times mean 24 h, which is an error. The form allows at most 12 h (presentation rule; the server still allows 24 h), and anything longer reads «Окончание должно быть позже начала». The row helper shows «Окончание 1 октября · 30 мин. Поездка попадёт в 30 сентября — день начала.».
- **Helpers stay visible** in mockups 09–11 too, which drop «Сколько заплатил пассажир» when the field is not focused. DESIGN.md has no such rule, and hiding it would make the form jump (same reasoning as `09` in R1). «На руки с поездки» appears only when both sums are valid.
- **Day states:** the FAB shows while loading and on a day with trips, not on the empty or error states (it animates out when a load ends empty). A failed pull-to-refresh keeps the shown day and opens an error snackbar «Не удалось загрузить данные» + «Повторить» (§5.4). A day switch shows the skeleton, never the previous day's totals.
- **Offline (§5.9):** the error snackbar sits 12 dp above the bottom bar (and above the keyboard). «Повторить» resends the same id. The automatic 2/4/8/30 s schedule is stage R5.
- **Copy in one file** (`core/l10n/strings_ru.dart`). Dates come from the kit's `DkFormat`, and the app's `core/format/date_format.dart` is gone (one formatting place). Where a kit default already equals the §6 copy («Дневник смен», «Повторить», «Закрыть»), the app relies on the default, because the analyzer rejects redundant arguments.
- **Screens use kit components only;** CI fails on `Color(0x` / `Colors.` / `TextStyle(` in `apps/mobile/lib`. `App` takes an optional `home` so tests can open the form directly.
- **How the screens are checked:**
  - `test/screens/layout_matrix_test.dart`: the 11 mockup states plus 2 maximum-amount states, each at 390×844 and 360×780, text scale 1.0 and 1.3, with the real fonts. Any overflow fails.
  - `stage4_rules_test.dart`: the badge, snackbar and dialog rules above.
  - The Day goldens, light and dark (alchemist, CI goldens from Linux).
  - `screenshots_test.dart`, which renders the PNGs in `docs/design/audit/stage4/` (390×844 @2x, real fonts and shadows) when `SCREENSHOTS_DIR` is set.

## Redesign — stage R5 (UI behaviour)

- **Stage 4 approvals recorded:**
  - 409 dialog: the title plus «Обновите день, чтобы увидеть сохранённую версию.»
  - Helpers stay visible while saving and offline: DESIGN.md wins over mockups 09–11.
  - The empty/error block stays centred within the safe area.
  - The time-field clock stays at 20 dp.
- **The field prefix icon (the clock) turns `error` with the border and label** (mockup 08, approved). DESIGN.md §4 is updated in both copies, and the `text_fields` golden now includes the 08 time row.
- **Sending a trip (§5.9, approved):**
  - dio no longer retries `POST /trips`: the request opts out with `RetryInterceptor.disabled`. GET keeps the interceptor's retries.
  - On a network or server failure, the snackbar «Нет связи. Повторим отправку — поездка не задвоится.» appears right after the first failure. The form then resends the **same trip (same id)** after 2 s, 4 s and 8 s, then every 30 s while it stays open.
  - «Повторить» resends at once and restarts the schedule from 2 s. Success closes the snackbar and the form.
  - Background resends are quiet: the form stays editable and Save keeps its label (as in mockup 10). A manual send shows «Сохраняем…».
  - Only one request runs at a time.
  - Editing any field after a failure stops the resends and closes the snackbar. The next Save is a different payload and so gets a new id. Closing the form also stops the resends.
- **Closing with unsaved input (§5.6) asks first:** this applies to ✕ and to system back, via `PopScope`. A form counts as unsaved once any time or sum is entered, or the payment method has changed. §6 has no copy for this dialog, so it uses **proposed** text, kept in `strings_ru.dart`:
  - title: «Закрыть без сохранения?»
  - message: «Введённые данные поездки не сохранятся.»
  - buttons: «Продолжить ввод» and «Закрыть».
  
  It is a `DkDialog` (the kit's standard dialog). *Pending your approval of the wording.*
- **Save stays right above the keyboard** (§5.6): the bottom bar moved from `Scaffold.bottomNavigationBar`, which stays behind the keyboard, into the body, which shrinks above it. Tested with a 300 dp keyboard inset.
- **Snackbars never cover dialogs or pickers (kit fix):** a snackbar is an `Overlay` entry above every route pushed later, and the offline snackbar covered the discard dialog and caught its taps. It now draws only while its own screen is the current route, and comes back when the dialog closes. On the Day screen the refresh-failure snackbar sits 12 dp above the FAB, never over it.
- **Accessibility checked on the real screens:** every mockup state and every R5 state, in light and dark, meets Flutter's tap-target (48 dp), labelled-tap-target and text-contrast guidelines. The §4 spoken names («Предыдущий день», «Выбрать дату, 1 октября 2026», «Наличные 38%, карта 62%») are tested.

## Accounts iteration — stage 0 (audit) and stage 1 (database, accounts, seed)

The audit is in `docs/PROD_AUDIT.md` (findings F1–F8). Decisions approved after it:

- **user_2's seed trips are `u2-t1` and `u2-t2`, not `t3` / `t4` (F5).** → `data/trips.json` already uses `t3` and `t4` for the 2026-09-30 edge cases (`t4` crosses midnight). The data is as in the prompt. Reference cases for 2026-10-01:
  - user_1: `t1`, `t2` → 2 trips, revenue 3 900, commission 585, net 3 315, cash 1 500 / card 2 400;
  - user_2: `u2-t1`, `u2-t2` → 2 trips, revenue 4 800, commission 720, net 4 080, cash 1 800 / card 3 000;
  - admin, all drivers: 4 trips, revenue 8 700, commission 1 305, net 7 395, cash 3 300 / card 5 400.
- **The demo history stays with user_1 (F6, option a).** → Every existing trip (131 in the file, plus what the deployed DB has) is backfilled to user_1, so its balance is not the prompt's 1 815 ₸. The balance tests (1 815 ₸ for user_1, 2 280 ₸ for user_2) run on a clean test seed with only `t1`, `t2`, `u2-t1`, `u2-t2`. On the deployed API, user_1's balance is checked against Σcard − Σcommission − Σ(pending + paid withdrawals) computed by a SQL query. The per-day reference cases above stay exact everywhere.
- **The two test trips of 2026-10-07 on prod (2 × 500 ₸, commission 0) are deleted,** after a `pg_dump` backup to a local file outside the repo and your confirmation of the exact two ids.
- **CORS stays `*` (F3).** → The API authenticates with a bearer token in the `Authorization` header, never with cookies, so a foreign web page cannot make the browser send credentials on its own; `*` only lets web pages read responses they already have the token for. No credentials mode is enabled (`allow_credentials` stays off).
- **One switch, `SEED_ON_STARTUP`, for all demo data (F7):** the demo accounts and the trips file. The prompt's `DEMO_SEED` name was not added, so there is one switch, not two.
- **The seed now adds missing seed trips to a database that already has data.** → Before, it ran only on an empty table, so the deployed DB would never get user_2's trips. Each insert is `ON CONFLICT (id) DO NOTHING`, so existing trips are never changed and several replicas can start at once. A deleted seed trip would come back on the next start; acceptable for demo data, and `SEED_ON_STARTUP=false` turns it off.
- **Demo passwords come from env and are re-applied on start.** → `SEED_*_PASSWORD` must change the password "without code": if the stored argon2id hash does not verify the configured password, the seed stores a new hash. Plaintext only exists in settings, never in the DB or logs. There is no password-change UI yet, so this cannot undo a user's own change.
- **argon2id via `argon2-cffi` with the library defaults** (RFC 9106 low-memory profile). A hash it cannot read (the migration's placeholder `!`) never verifies.
- **Migration 0002 runs on the existing trips table.** It adds `driver_id` as nullable, creates user_1 with the unusable hash `!` only if trips exist, backfills, then sets NOT NULL, adds the FK and the `(driver_id, start_at)` index. Tested on an empty DB and on a DB with trips, and on a local copy shaped like prod (133 trips at revision 0001) with the production image: all trips went to user_1, the seed then set user_1's password and added the user_2 trips, and a restart changed nothing.
- **All new tables in one migration, including `withdrawals`.** → Stage 1 is the database stage; the withdrawals logic comes in stage 3 and may add constraints in its own migration.
- **Until auth exists (stage 2), the API acts as user_1.** → The deployed app keeps working and keeps showing exactly the reference day (user_2's new trips are not mixed in). `SqlTripRepository` takes an optional `driver_id` (None = all drivers), which stage 2 reuses for role scoping. If user_1 is missing (seed off on an empty DB), trip endpoints answer 503.
- **Production refuses to start without `DATABASE_URL` (F2).** → `APP_ENV` is `local` by default and the Docker image sets `APP_ENV=production`. Only `local` and `test` fall back to the docker-compose database. Checked: the image without `DATABASE_URL` exits with "DATABASE_URL must be set when APP_ENV=production".
- **A database that is down at startup does not crash the API.** → Seeding is skipped with a logged error and `/health` reports 503; a crash loop would hide the reason. A seed file that names an unknown driver still stops startup: that is a deploy bug.
- **One named timezone default in the app (F1):** `AppConfig.zoneFrom` uses `DriverZone.kazakhstan` when `DRIVER_TZ` is not given.
- **Railway config as code moved to `.railway/railway.ts` (F4).** → `railway config migrate` would have dropped the Dockerfile path and builder (it emitted them as comments) and the restart policy, so the file was imported from the live project with `railway config pull` instead; `railway config plan` reports it already matches Railway. Postgres and its volume stay in the file exactly as imported: removing a resource from an IaC file can mean deleting it. `railway.json` is removed. The SDK (`railway` on npm) is a root dev dependency, excluded from Railway uploads. *Note: the original assignment asked for `railway.json`; the settings it held now live in `.railway/railway.ts`.*

### Branches and deploys

- **Tag `v1.0` on `9adc869` marks the submission-ready redesign and is never moved.** → Everything after it can be compared with, or rolled back to, the version that was submitted.
- **All work goes to `main`; there are no long-lived branches.** (A `feature/accounts` branch was created and then deleted on request.) Every commit on `main` keeps CI green.
- **`AUTH_REQUIRED` keeps `main` deployable while login is not in the app yet.** Default `true` in code and tests. Production runs with `AUTH_REQUIRED=false` until the mobile app supports login (end of stage 5): a request without a token then acts as user_1 exactly like in stage 1, so the released app and the README curl examples keep working; a token that is sent is still checked. Both modes are tested.
- **Deploying during stages 2–4 only with `AUTH_REQUIRED=false`, and only when the DEPLOY_CHECK.md checks pass** (`/health`, the 2026-10-01 reference case).
- **After stage 5, prod switches to `AUTH_REQUIRED=true` together with the app release,** then the full deployed verification of stage 6 runs.
- **Deploys are always an explicit `railway up` from `main`.** The Railway service is not linked to GitHub, so a push never deploys.

## Accounts iteration — stage 2 (login, roles, scoping)

- **Opaque random tokens, not JWT.** → The prompt wants sessions without expiry that end on logout or when an admin revokes them. A JWT without expiry cannot be revoked (the server would have to keep a deny-list, i.e. sessions anyway), so logout would be fake. A token is 32 random bytes (`secrets.token_urlsafe`), only `sha256(token)` is stored (a DB leak gives no usable tokens), and each request looks the hash up in `sessions` (indexed, unique).
- **`last_used_at` is written at most once per hour.** → It is informational; writing it on every request would turn every read into a write.
- **One 401 for unknown login and wrong password (`invalid_credentials`), in the same time:** an unknown login is still checked against a real argon2 hash of a random password (`dummy_hash`), so response time does not reveal which logins exist.
- **Rate limit: 10 failed attempts per (login, client IP) in a sliding 15-minute window → 429 `rate_limited` with `Retry-After`.** *(Changed after stage 2 from "per login": see below.)* Failures are rows in `login_failures` (migration 0003), so the limit holds across restarts and replicas; old rows are deleted as new ones are written. Unknown logins are counted too. While locked, even the right password gets 429. Success does not reset the counter (the window does): otherwise one success would allow 10 more guesses.
- **A blocked account is reported (403 `account_disabled`) only to someone who gives its right password;** with a wrong password the answer stays `invalid_credentials`. → The app can say "blocked" instead of "wrong password" without telling strangers which accounts exist.
- **Every endpoint except `/health` and `/auth/login` needs `Authorization: Bearer <token>`;** missing, unknown, revoked or blocked-user tokens → 401 `unauthorized` with `WWW-Authenticate: Bearer` (RFC 6750). A malformed header (`Basic …`, `Bearer` without a token) is a 401 even with `AUTH_REQUIRED=false`; only a request with no Authorization header at all falls back to user_1.
- **Scoping lives in the application layer (`app/application/access.py`), not in routes:**
  - a driver sees and creates only their own trips; **any** `driver_id` parameter from a driver is 403 (even their own id) — one simple rule instead of "ignored sometimes";
  - an admin sees all drivers (no `driver_id`) or one driver; a `driver_id` that is not a driver is 404 rather than an empty result, so a typo is not mistaken for "no trips";
  - only drivers create trips: an admin's `POST /trips` is 403.
- **Trip idempotency is per owner.** Same id from the same driver: 201 / 200 / 409 as before. Same id from another driver: 409 `trip_conflict` with exactly the same body as a payload conflict — no stored values, nothing about the other driver's trip (the 409 never had an `existing` field; see stage 4 of the redesign).
- **Admin endpoints:** `GET /admin/users` (drivers first; never password hashes), `PATCH /admin/users/{id}` `{is_active}`, `POST /admin/users/{id}/revoke-sessions` → `{revoked: n}`. Blocking also ends all the user's sessions, so unblocking does not revive old tokens. An admin cannot block their own account (403): with one admin that would lock everyone out.
- **CORS:** allows `PATCH` and the `Authorization` header for the web build; still no credentials mode (F3).
- **The login lock is per (login, client IP), not per login.** → Per login, a stranger could lock user_1 out of the public demo with 10 wrong passwords. Now only that stranger's IP is locked for that login; the driver signs in from theirs. Migration 0004 adds `login_failures.client_ip`.
- **On Railway the client IP comes from `X-Real-IP` (`CLIENT_IP_HEADER=x-real-ip`), not from `X-Forwarded-For`.** → First implemented as "the last `TRUSTED_PROXY_HOPS` entries of `X-Forwarded-For`", as asked. A cross-check against `X-Real-IP` then showed on prod that Railway's `X-Forwarded-For` holds whatever the client sent plus Railway's own internal hop, but **never the client**: one hop gives Railway's proxy address (everyone would share one lock), two hops give the client's forged value. `X-Real-IP` carries the real client, and a forged `X-Real-IP: 9.9.9.9` arrived as the real address, so Railway overwrites it. Verified on prod: 10 failures from one IP (with forged `X-Forwarded-For` and `X-Real-IP`) → 429 for that IP; the same login from another IP → still 401. `TRUSTED_PROXY_HOPS` stays for proxies that do append the client to `X-Forwarded-For`; neither set (local) → the peer address. If the configured header is missing, the peer address is used and a warning is logged — never a client-controlled header.
- **Uvicorn no longer runs with `--forwarded-allow-ips='*'`.** → With `*` it takes the **leftmost** `X-Forwarded-For` entry, which the client controls, as the client address.
- **Demo accounts cannot be broken by visitors (demo mode = `SEED_ON_STARTUP` on).** → The demo credentials are public, so anyone can sign in as admin. Every start unblocks `admin`, `user_1`, `user_2` and restores their demo passwords, and `PATCH /admin/users/{id}` (block) and `POST /admin/users/{id}/revoke-sessions` refuse them with 409 `demo_account_protected`. Unblocking stays allowed (harmless). Other accounts are not protected; outside demo mode nothing is.
- **Use-case signatures group what belongs together** (`Accounts` = users + sessions; `LoginRequest` = login, password, user agent) instead of raising the linter's argument limit.

## Accounts iteration — stage 3 (withdrawals)

- **Balance rule** (vacancy question 4): card payments go to the park, cash stays with the driver, and the park's commission is owed on **all** trips. So `available = Σ card − Σ commission (all trips) − Σ withdrawals pending or paid`. It can be zero or negative. A rejected withdrawal stops counting, so its money is available again; a paid one stays spent. Integers only. The rule lives in `app/domain/withdrawal.py`; the SQL computes the three sums in one query per driver (or over all drivers for the admin).
- **The withdrawal id is the idempotency key**, generated by the client (UUID v4) when the user taps «Вывести» and reused on every retry. Same id + same amount → 200 with the stored withdrawal; same id + another amount → 409 `withdrawal_conflict`; an id used by another driver → the same 409, revealing nothing.
- **Double-spend protection = one transaction holding the driver's row lock:**
  1. `SELECT … FROM users WHERE id = :driver FOR UPDATE`;
  2. look the id up (a retry finds the first request's row → 200/409);
  3. recompute the balance;
  4. `INSERT … ON CONFLICT (id) DO NOTHING`, then read and compare.

  Two requests for the same driver therefore run one after another. The lock is checked by sabotage: without it, 12 simultaneous requests of 500 ₸ against 1 815 ₸ all succeeded; with it, exactly 3 do. Requests of different drivers do not block each other.
- **The id check comes before the balance check.** → A retry of a withdrawal that already used the money must be 200, not 422 «insufficient funds».
- **Errors:** amount above the balance → 422 `insufficient_funds` (field `amount`); amount ≤ 0 → 422 `invalid_amount`; amount over the 10 000 000 sanity cap → 422 `amount_too_large`.
- **Approve / reject are idempotent** and lock the withdrawal row (`FOR UPDATE`). Repeating the same decision returns the current state (a repeated reject keeps the first reason). Deciding the other way → 409 `withdrawal_already_decided`. A reject needs a non-empty reason (≤ 500 characters after trimming) → otherwise 422 `invalid_reason`. Only admins decide (403 otherwise); unknown id → 404.
- **Scoping as for trips:** a driver gets their own balance and withdrawals, and any `driver_id` from a driver is 403. An admin gets all drivers (balances summed) or one driver; `GET /withdrawals?status=` filters, newest first. Only drivers create withdrawals.
- **Balance tests run on a clean seed** with only `t1`, `t2`, `u2-t1`, `u2-t2` (user_1 = 1 815 ₸, user_2 = 2 280 ₸). On prod, user_1 owns the demo history, and `GET /balance` must equal the SQL formula (200 327 ₸ before any withdrawal).
- **A body that is not valid JSON is always 422 `invalid_json`** — broken JSON, and also bytes that are not UTF-8 (FastAPI raises a 400 for those; the error handler maps exactly that case). → One error shape and one status for "the client sent something unreadable", on every endpoint.
- **No new migration:** the `withdrawals` table (with `CHECK amount > 0` and the status check) was created in stage 1.

## Accounts iteration — stage 4 (design addendum, kit components)

- **DESIGN.md §8 added** (root and kit copy) from the prompt's addendum, plus §8.8 «Kit implementation» mapping each §8.0 item to its API.
- **New components have no texts of their own** — every label is a parameter — so stage 5 can translate them; the older components still have Russian defaults, removed in stage 5 with the l10n check.
- **Screen previews live in the kit's example app** (`example/lib/accounts_preview.dart`, «Аккаунты» tab), built only from kit components with static data, not in the mobile app. → Stage 4 must not wire anything; the previews are the reviewable mockups of every state, and `example/test/accounts_screens_test.dart` renders them (light + dark, 390×844 @2x; no overflow at 360 dp × text 1.3). Screenshots: `docs/design/audit/accounts/`.
- **`DkIconButton` icon is 24 (§8.0)**, was 22. The sort button in the Day header grows by 2 px; the Day goldens (Windows + Linux CI) are regenerated.
- **Deviation, pending approval: the language switch is 56 high on the login screen too**, not 48 («compact», §8.1). A 48-high track with the 4 px padding gives 40-high segments, below the 48 dp tap target of §1. Width 200 on the login screen stays.
- **A `DkTextField` trailing widget is now its own semantics node.** → The field merges its label and input for screen readers; the password eye button merged into it and could not be reached. Found by a kit test.
- **Copy not in §8.7 is marked «proposed» in the previews:** the reject dialog title «Отклонить заявку на 1 000 ₸?» and message «Водитель 2 увидит причину в истории выводов.», the revoke dialog title «Сбросить все сессии?» with the primary «Сбросить», the 409 withdrawal dialog message «История обновлена: там видна сохранённая заявка.», the admin empty state «Заявок нет» / «Новые заявки на вывод появятся здесь.», the admin error state «Не удалось загрузить», and the footer «Версия 0.2.0».
- **Admin rows use the date without the year** («9 октября, 22:34») so «1 000 ₸ · date» fits one line at 390 dp; the driver's own history keeps the full date as §8.4 shows.

## Post-redesign UI fixes (user feedback)

- **iOS-style pickers on every platform** → the Material date and time dialogs are replaced by `DkPickerSheet` (`showDkDatePicker` / `showDkTimePicker`): a bottom sheet with a Cupertino wheel and «Готово». *Why:* the user found the Material Android pickers awkward; one wheel works the same on Android and iOS and is thumb-friendly. The date sheet has a «Сегодня» shortcut.
- **Day data is cached per day** → `dayTripsProvider(day)` / `daySummaryProvider(day)` are families; a loaded day stays in memory for 5 min (`dayCacheTtl`) after the screen leaves it, and the Day screen loads the previous and next day in the background. *Why:* going back to a day just seen showed a skeleton again. A failed load is never cached; pull-to-refresh and a new trip reload from the server. One provider per day also means another day's totals can never show for the selected day.
- **«Сегодня» in the header** (`DkTodayButton`, right side of the wordmark row, only while another day is shown) → one tap back to today instead of tapping › several times. Placed on the right so the wordmark keeps its spot; the future Menu button (§8.2) goes after it.
- **One-line labels**: the payment tile label («Наличные · 17%») and the trip meta («30 мин · Наличные») scale down to fit instead of wrapping onto a second line at 360 dp. *Why:* the wrapped share read as a separate value.
- **Dialogs are centred** (icon, title, message), max width 400. *Why:* the left-aligned discard dialog looked unbalanced.
- **The form's offline snackbar is part of the form's layout**, not an overlay entry. *Why:* the overlay version was placed once, at "keyboard height + bar + 12". Save closes the keyboard, the offline error arrives while it is still going down, and the snackbar stayed ~300 dp above Save in the middle of the screen. In a `Stack` above the bottom bar it always sits 12 above Save, with or without the keyboard (regression test: show with a 300 dp inset, then remove it).
- **A saved trip is scrolled into view** (centred, 300 ms; instant with reduced motion), then highlighted as before. *Why:* in a long day the 2 s highlight happened off screen. The success snackbar is not delayed by the scroll.
- **Trip sorting: time ↑ (default), time ↓, amount ↓, amount ↑**, from a sort button in the «Поездки» header and an options sheet. The order is kept in memory for all days until restart (not saved to disk: the default is what most drivers want, and a remembered odd order could look like a bug the next morning). Ties keep start order, so rows never jump. Sorting is a presentation concern (`TripOrder` in `presentation/models`); the summary is unaffected.
- **Bottom sheets are not capped at 9/16 of the screen** (`isScrollControlled`) and scroll if needed. *Why:* a kit test on a 600 dp-high screen showed the time picker sheet overflowing by 11 dp.
- **Light theme by default** (`App.themeMode = ThemeMode.light`) → the app no longer follows a dark phone setting. The dark theme stays in the kit and in the tests (they pass `ThemeMode.system`). A theme switch can go into the Menu screen planned in the next iteration.

