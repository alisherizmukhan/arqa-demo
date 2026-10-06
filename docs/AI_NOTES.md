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
