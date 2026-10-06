# AI notes (draft)

A running log of where the AI assistant was unsure, got something wrong first, and what was fixed. Raw material for the final write-up.

## Stage 1 — skeleton

- **Dart 3.13 constructor syntax.** The first version of the placeholder widgets used the classic `const App({super.key});`. `very_good_analysis` 11 on Dart 3.13 flags it (`unnecessary_type_name_in_constructor`) and wants the newer `const new({super.key});`. Fixed; all new code uses the new form.
- **Windows app-control policy blocks `pytest.exe`** (the uv-generated console shim), while `ruff.exe`/`mypy.exe` run fine. Locally, tests run via `uv run python -m pytest`; CI on Linux uses `uv run pytest`. Not a code issue, but it's worth knowing when reproducing on Windows.
- **Seed data vs. the reference case.** When adding more demo trips, it's easy to break the reference day by accident: a trip at `2026-10-01T19:30Z` *looks* like 10-01 but is 00:30 on 10-02 in +05:00. Kept it on purpose as a boundary example and checked that 10-01 still has only `t1` and `t2`.
- **Trip id format.** The requirements say the client generates a UUID v4, but the given input uses `t1`/`t2`. Chose an opaque string id so both work (see DECISIONS.md) instead of silently rewriting the seed ids.
