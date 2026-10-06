# AI notes (draft)

A running log of where the AI assistant was unsure, got something wrong first, and what was fixed. Raw material for the final write-up.

## Stage 1 — skeleton

- **Dart 3.13 constructor syntax.** The first version of the placeholder widgets used the classic `const App({super.key});`. `very_good_analysis` 11 on Dart 3.13 flags it (`unnecessary_type_name_in_constructor`) and wants the newer `const new({super.key});`. Fixed; all new code uses the new form.
- **Windows app-control policy blocks `pytest.exe`** (the uv-generated console shim), while `ruff.exe`/`mypy.exe` run fine. Locally, tests run via `uv run python -m pytest`; CI on Linux uses `uv run pytest`. Not a code issue, but it's worth knowing when reproducing on Windows.
- **Seed data vs. the reference case.** When adding more demo trips, it's easy to break the reference day by accident: a trip at `2026-10-01T19:30Z` *looks* like 10-01 but is 00:30 on 10-02 in +05:00. Kept it on purpose as a boundary example and checked that 10-01 still has only `t1` and `t2`.
- **Trip id format.** The requirements say the client generates a UUID v4, but the given input uses `t1`/`t2`. Chose an opaque string id so both work (see DECISIONS.md) instead of silently rewriting the seed ids.

## Stage 2 — backend domain

- **Cash vs. card split.** The first draft used `if payment is CASH: … else: card += …`, so any future payment method would silently be counted as card. Switched to an exhaustive `match` with `assert_never`, which mypy checks.
- **`bool` is an `int` in Python.** `isinstance(True, int)` is `True`, so a naive `isinstance` check would accept `amount: true` as 1 tenge. The domain uses `type(x) is int`, with a test for it. (On the API side, Pydantic strict ints must also reject it — to verify in stage 3.)
- **Day boundaries — the classic wrong approaches**, called out explicitly so they don't creep in later:
  - `WHERE date(start) = :day` in SQL uses the DB session timezone (UTC). Trips between 00:00 and 05:00 Almaty time would land on the previous day.
  - Building the boundary with `datetime.combine(day, time.min)` *without* `tzinfo` and then treating it as UTC shifts the window by 5 hours.
  - An inclusive end (`<= 23:59:59`) drops trips at `23:59:59.5`.
  The domain uses an aware, half-open window, converted to UTC for querying. A property test checks that the UTC window always agrees with the local-calendar day for any offset between −14:00 and +14:00.
- **Unsure: should the summary filter out-of-day trips or fail?** Chose to fail (`ValueError`). Silently filtering would hide a wrong repository query behind plausible-looking but wrong totals.
- **Unsure: is the same trip with a different offset notation a "different payload"?** Decided no — instants are compared — otherwise a client that normalizes to UTC on retry would get a spurious 409.
- **Known pitfall for stage 3:** in a URL query string `+` decodes to a space, so `?tz=+05:00` reaches the server as `" 05:00"`. The domain parser is strict on purpose (a test rejects `" 05:00"`); the API layer must handle this explicitly.

## Stage 3 — persistence, API, idempotency

- **Proved the concurrency test can actually fail.** I temporarily replaced `INSERT … ON CONFLICT DO NOTHING` with a check-then-insert (`get` then `add`). All three race tests failed with `UniqueViolationError` → 500 (20 concurrent POSTs of one trip; mixed payloads; 10 sessions racing in the repository). After restoring, they pass. Without this check, a concurrency test that passes proves nothing.
- **First version of datetime validation was wrong.** I used `Annotated[AwareDatetime, Strict()]` to reject unix timestamps. Every valid POST then failed with "Input should be a valid datetime": FastAPI decodes the JSON first and validates in *Python* mode, where strict datetime refuses strings. Replaced with a `BeforeValidator` that only lets strings through. Caught by a manual smoke test before writing tests.
- **Alembic naming convention applied twice.** The migration had explicit names like `ck_trips_amount_positive` *and* the metadata had a `ck_%(table_name)s_%(constraint_name)s` convention, producing `ck_trips_ck_trips_amount_positive`. Fixed by using short names in the migration; verified with `\d trips`.
- **`+` in query strings** (flagged in stage 2): confirmed that `?tz=+05:00` arrives as `" 05:00"`. Handled in the API layer; an integration test covers raw `+`, `%2B` and the default.
- **Two of my own test bugs** — a `start` passed twice, and `f"T{hour}:00"` producing `T9:00` — showed up as failures. The second one was hidden because the test didn't assert the POST status; added that assertion. Worth noting: the server rejected `T9:00` correctly.
- **Port clash:** another project's Postgres container already used 5432 on this machine. Moved ours to 5433 instead of stopping someone else's container.
- **Railway specifics I wasn't sure about** and handled defensively: Railway's `DATABASE_URL` uses `postgresql://` (sometimes `postgres://`); asyncpg rejects libpq's `sslmode` (rewritten to `ssl`); BuildKit cache mounts need Railway-specific ids (not used); `$PORT` is injected (the container honors it — tested with `PORT=9000`).
- **First Railway deploy failed: Railway used Railpack instead of the Dockerfile.** The root `.dockerignore` (`*` + allow-list for `backend/` and the seed file) is also applied by Railway to the *uploaded snapshot*, so `railway.json` (which points at `backend/Dockerfile`) was filtered out and Railway fell back to auto-detection. Fixed with `!railway.json` in `.dockerignore`. The local `docker build` couldn't catch this, because locally the build config is passed on the command line.
- **…and the second deploy still used Railpack.** With `railway.json` in the snapshot, Railway still ignored it: the service had no config-file path, and setting one is now refused ("Config as Code is deprecated"; CLI 5.52). My assumption that `railway.json` drives the build was outdated for new services. Fixed by setting the builder, Dockerfile path and healthcheck directly on the service, and documented the extra step in the README. Lesson: verify the platform's *effective* service config (`get-service-config`) instead of assuming the config file applies.

## Stage 4 — design kit

- **The skill's recommendation needed filtering.** `--design-system` returned a landing-page pattern ("Enterprise Gateway"), Playfair Display as the *body* font, and "light mode not recommended". I kept the parts that fit (OLED dark, green for earnings, slate neutrals), re-queried color/typography separately as the skill instructs, and rejected the rest with reasons in DESIGN.md.
- **Font assumptions verified, not trusted.** I checked both candidate fonts with fontTools instead of assuming Cyrillic / `₸` support: both have them. Inter needs the `tnum` feature, while IBM Plex has tabular digits by default.
- **License catch.** My first plan was to subset Plex into four static weights. The OFL's Reserved Font Name clause makes that a "Modified Version" that may not be called "Plex". Switched to the unmodified variable font, which was about the same size anyway.
- **Repeated a lint mistake from stage 1** (`const ClassName(` instead of Dart 3.13's `const new(`) across all new files. `dart fix --apply` corrected it mechanically.
- **Loading-button semantics bug, found by a test:** the `Semantics(value: 'Загрузка')` wrapper became a separate node, so a screen reader would not announce "loading" together with the button. Fixed with `MergeSemantics`.
- **`textContrastGuideline` failure that wasn't a contrast problem.** The dark theme failed at 1.13:1 for the "Оплата" label. Two wrong guesses first: semantics merging, and off-screen widgets. Reading the flutter_test source showed it samples the `Text` widget's paint box plus 4px: the stretched label was 768px wide with a few glyphs, and the margin reached the neighbor's fill. I printed the real color (#F8FAFC, 19:1). The fix was layout, not color: size the label to its text.
- **`SegmentedButton` ignores `minimumSize`.** My 56dp token was silently rendered as a 40dp box with 48dp tap padding. Found via a semantics dump, confirmed in the SDK source, and replaced with custom segments.
- **Screenshot artifact:** at 412px, headless Edge cropped the right side. That looked like an overflow, but a 600px screenshot and a 360dp widget test showed the layout was correct; the cause is headless Edge's minimum window width.

## Backend review (requested before stage 5)

- **Found two 500s by probing edge cases by hand**, not via the test suite: `GET /summary?date=0001-01-01` and a POST with a year-1 timestamp both overflowed when converting to UTC. `date=9999-12-31` happened to work, which shows how easy this is to miss. Fixed with a supported 2000–2099 range; the four extreme dates are now regression tests.
- **Missing CORS** would have broken the Flutter web demo in stage 5. Easy to forget when the target is "a mobile app".
- **My own new rule broke an old test:** the day-boundary test used one shared end time, which made the first trip longer than 24h. The test data was wrong, not the rule.
- **Coverage first reported 87% for `routes.py` with lines that obviously run.** The cause was coverage not tracing greenlets (SQLAlchemy async). With `concurrency = ["greenlet", "thread"]` the real number is 99%.
- **Generated demo data must not break the reference case.** The generator never writes to 2026-09-30 .. 10-03 (days the tests pin down), and a check recomputes every day's summary from the file.

## Stage 5 — mobile app

- **Dart 3.13 constructor syntax, again, but harder.** `dart fix --apply` hung for minutes (killed). The analyzer rejects `factory new(...)` but flags `factory ClassName(...)`. Instead of guessing, I wrote a probe file with three variants and let the analyzer pick: unnamed factory `factory (...)`, private named `const new _(...)`.
- **freezed 4 + primary constructors produce no JSON.** The first DTOs (primary-constructor style, as freezed's README now recommends) generated `*.freezed.dart` but no `*.g.dart`. A one-class probe confirmed the classic factory form works with the new syntax.
- **`build_runner` removed `--delete-conflicting-outputs`.** The CI step from stage 1 used it, so CI would have failed on the mobile job. The CI stale-code check also used `git diff`, which misses *new* generated files; it now uses `git status --porcelain`.
- **New enum value caught by the compiler:** dio 5.11 added `DioExceptionType.transformTimeout`; the exhaustive `switch` in the failure mapper refused to compile until it was handled.
- **A UX bug found by a widget test:** the form validator returned early when times were missing, so "commission larger than amount" stayed hidden until both times were picked. Split the rules into `validateMoney` / `validateTimes`.
- **A test name that claimed too much:** "client-side errors, then a server conflict" never reached the conflict (that needs time pickers). Renamed it to what it checks; the conflict/id-reuse logic is covered by provider tests.
- **Time zone trap avoided on purpose:** "today" and day boundaries use the driver's offset, not `DateTime.now()`'s device zone. A provider test fixes "now" at 20:00Z, which is already the next day in +05:00.
- **Verified against reality, not just mocks:** the web build ran against the deployed API (today's total matched the API's `/summary` exactly), and the live contract tests ran the real dio/DTO/repository stack against a local backend (create → 200 on retry → 409 → listing by local day, and a server 422 mapped to a field error).

## Redesign — stage R1/R2 (audit, tokens)

- **Font coverage checked before trusting the spec.** fontTools showed that Manrope — the font DESIGN.md mandates — has no `₸` and no U+202F, the two characters the spec's money format relies on. Raised in the audit; fallback approved.
- **The fallback golden caught a mockup-vs-spec difference, and I measured instead of eyeballing.** In the first golden, "3 315" looked like "3315". A probe golden was too small to judge, so I measured `TextPainter` widths: U+202F is present but narrow by definition (≈0.1 em: 1.7 px at 17 px, ~4 px in the hero). The mockups draw group gaps at roughly a normal space (~0.25 em). Kept U+202F (DESIGN.md wins) and raised it as an open question rather than silently "fixing" the string.
- **Spec conformance as a test, not a promise.** Instead of re-typing hex values into assertions (which would only test that I copied my own code), the test parses DESIGN.md's tables and compares.
- **Small slips caught by the tools:** `expect()` called while declaring groups (not allowed outside a test); comparing freshly lerped extensions with `==` (no value equality); the wider real font overflowing a showcase row at 360 dp. Two long shell heredocs with Cyrillic text failed to parse in Git Bash; scripts now go through files.
- **"CI goldens are cross-platform" was an assumption, and it was wrong.** Before relying on it, I ran the kit tests with `CI=true` in a Linux container (Flutter 3.47.6 cloned inside Ubuntu; the public Flutter images stop at 3.44). The Windows-generated CI goldens failed there. CI goldens are now generated on Linux by a script and compared only in CI; Windows compares the real-font goldens. Without this check the first push would have turned the design-kit CI job red.

## Redesign — stage R3 (components)

- **A kit bug that kit tests could not see:** `DkButton` centred its content with `Center(widthFactor: 1)`. Without `heightFactor`, a `Center` fills all the height it is offered. Every kit test rendered buttons inside scroll views (unbounded height), where that is harmless. In the app the button sits in `Scaffold.bottomNavigationBar`, grew to the whole screen and squeezed the Day list to zero height. The app's own widget tests caught it; diagnosing took four steps (texts on screen → exception → provider state → widget counts) before the layout was the obvious suspect. Fixed, with a kit regression test that puts the button in a bottom bar.
- **Overflow found by a 360 dp test with maximum amounts:** the trip tile's amount column was rigid and overflowed by 8.5 px; now flexible, and tested at text scale 1.0 and 1.3.
- **Two of my own tests asserted impossible states:** a Backspace "right after the gap" that the controller never allows (its caret is moved in front of the gap), and an arrow-key expectation that contradicted the one-stop design. Replaced with real key sequences plus a direct unit test of the formatter for the separator-only deletion.
- **Goldens caught visual details that tests missed:** the field helper «На руки с поездки: 2040₸» rendered without the wide gap (helpers were plain `Text`), the dark "focused" field was not focused at all (alchemist renders both themes in one tree, so only one field can hold focus), and the loading spinner's first frame is an invisible dot.
- **Checked the spec's icon name against its intent:** DESIGN.md maps the empty state to Lucide `route` "(road)", and the mockup shows a road. Rendering showed Lucide `route` is a connected path, so the closer Lucide `road` glyph is used (found in the font metadata, not in the Dart API).
- **Linux check before claiming CI is green:** the full Dart suite (kit 158, showcase 6, app 61) and analyze ran in the Linux container against the regenerated CI goldens.
