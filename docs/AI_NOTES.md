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
