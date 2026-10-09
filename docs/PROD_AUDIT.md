# Production audit (stage 0)

Audit before the accounts / admin / withdrawals iteration. No code was changed in this stage. Findings are fixed in the stages named in the table; stage 6 ticks them.

Date: 2026-10-09. Commit: `cb07ca9`.

## 1. Data flow: is every number on the Day screen real?

Searched the release code (`apps/mobile/lib`, `packages/design_kit/lib`; not `example/`, not `test/`, not generated `*.g.dart` / `*.freezed.dart`):

```bash
grep -rnE "3315|3 315|3 315|3900|\b585\b|2400|\b1500\b|\b360\b|\b225\b|08:10|09:05|2026|октября" apps/mobile/lib packages/design_kit/lib
grep -rniE "fake|mock|demo|stub" apps/mobile/lib packages/design_kit/lib
grep -rnE "DateTime\(|DateTime\.now|DateTime\.utc\(" apps/mobile/lib packages/design_kit/lib
grep -rniE "\btoday\b|сегодня" apps/mobile/lib packages/design_kit/lib
```

| Hit | Where | Verdict |
|---|---|---|
| `3 315 ₸`, `−585 ₸`, `2 400`, `360 ₸`, `08:10`, `1 октября 2026`, `2026-10-01` | doc comments in `dk_money.dart`, `dk_grouped_text.dart`, `dk_trip_tile.dart`, `dk_card.dart`, `dk_inputs.dart`, `dk_day_switcher.dart`, `dk_format.dart`, `strings_ru.dart`, `calendar_day.dart`, `driver_zone.dart`, `dk_typography.dart` | OK: examples in `///` comments, not values |
| `'октября'` | `dk_format.dart:14` | OK: the genitive month-name table |
| «mockup» | comments in `add_trip_screen.dart`, `day_screen.dart`, `dk_inputs.dart`, `dk_grouped_text.dart`, `dk_money.dart`, `dk_icons.dart` | OK: references to design mockups, no fake/mock/stub repository exists in `lib/` |
| `DateTime.now` | `core/providers.dart:22` (`clockProvider`) | OK: the single clock, overridden only in tests |
| `DateTime(2000)` / `DateTime.utc(2000)`, `DateTime.utc(2100)` | `day_screen.dart:245`, `trip_rules.dart:28-29` | OK: date-picker floor and the supported range (same as the backend's 2000–2099) |
| `DateTime(2000, 1, 1, hour, minute)` | `dk_picker.dart:23` | OK: carrier date for the time-only wheel |
| `today` | `todayProvider` (driver zone + clock), `SelectedDay.today()`, day switcher | OK: computed from the clock, never hardcoded |

**Result: no finding.** Every figure on the Day screen comes from `GET /trips` (the summary is computed from the same trips; `GET /summary` returns the same numbers, checked against the deployed API on 2026-10-07).

## 2. Config

| Check | Status | Finding |
|---|---|---|
| `API_URL` via `--dart-define` | ✅ `AppConfig.fromEnvironment`, default = the HTTPS Railway URL (no localhost) | — |
| Timezone +05:00 is one named constant (app) | ⚠️ | **F1.** `DriverZone.kazakhstan` exists but `AppConfig` repeats the literal `'+05:00'` as the `DRIVER_TZ` default. Two sources of truth. |
| Timezone +05:00 is one named constant (backend) | ✅ `_DEFAULT_TZ` in `api/deps.py` | — |
| Backend settings only via env (pydantic-settings) | ✅ `infrastructure/settings.py` (`DATABASE_URL`, `PORT`, `SEED_ON_STARTUP`, `SEED_FILE`, `LOG_LEVEL`, `CORS_ORIGINS`) | — |
| No localhost fallbacks in production paths | ⚠️ | **F2.** `Settings.database_url` defaults to `postgresql://postgres:postgres@localhost:5433/driver_diary`. If `DATABASE_URL` were missing on Railway, the API would start against localhost and only fail at `/health`. Production should fail fast at startup. |
| Dev runner | ✅ `python -m app` binds `127.0.0.1` with reload — dev only; the Docker `CMD` runs `alembic upgrade head` then uvicorn on `0.0.0.0:$PORT` | — |
| Release APK network access | ✅ fixed in `cb07ca9`: `INTERNET` permission in the main manifest; cleartext HTTP only in the debug manifest | — |
| CORS | ⚠️ | **F3.** `CORS_ORIGINS` default `["*"]`. Acceptable for bearer tokens (no cookies), but once accounts exist the deployed value should list real origins or stay `*` by an explicit decision. |

## 3. Railway

Commands: `railway status`, `railway service status`, `railway variables --service <name> --json` piped through a script that prints **names and yes/no checks only** (no values were printed or stored).

| Check | Result |
|---|---|
| CLI logged in | ✅ (CLI 5.52.0) |
| Project linked | ✅ `driver-shift-diary`, environment `production` |
| Backend service | ✅ `api`, ● Online, deployment status SUCCESS, https://api-production-6e8b.up.railway.app |
| Postgres service | ✅ `Postgres`, ● Online, volume `postgres-volume` |
| `DATABASE_URL` on `api` | ✅ set; resolves to exactly `Postgres.DATABASE_URL` (the `${{Postgres.DATABASE_URL}}` reference) over the private network (`*.railway.internal`) |
| `GET /health` | ✅ 200 `{"status":"ok","database":"ok"}` |
| Variable names on `api` | `DATABASE_URL` + Railway-provided `RAILWAY_*` only. `SEED_ON_STARTUP`, `CORS_ORIGINS`, `LOG_LEVEL` are not set (defaults apply). |
| Config as code | ⚠️ **F4.** Railway warns that `railway.json` is deprecated; existing files keep working until **2026-12-01**. The live service has the values set in its settings, so nothing breaks then, but `railway.json` should move to `.railway/railway.ts` (or be documented as reference only). |

Stage 1 therefore needs **no new Postgres** — only verification of the link (as the prompt allows).

## 4. Data and seed (conflicts with the next stages)

| # | Finding | Impact |
|---|---|---|
| **F5** | `data/trips.json` already has ids `t3` (2026-09-30 18:40, card 2 100) and `t4` (09-30 23:50 → 10-01 00:20, cash 3 200 — the midnight edge case). The prompt's new user_2 trips are also `t3` / `t4`. | Seeding them as given is a 409 (same id, different payload), or would overwrite the edge cases the tests rely on. The user_2 trips need other ids. |
| **F6** | The file has 131 trips (demo history 2026-09-21 … 10-06), none with a driver. The deployed DB also has 2 extra trips on 2026-10-07 (card 500 ₸ ×2, commission 0), created from the app during testing. The prompt backfills all existing rows to user_1. | user_1's balance becomes Σcard − Σcommission over all of them: **200 327 ₸** from the file alone (258 450 − 58 123), plus 1 000 ₸ from the 10-07 trips — not the prompt's **1 815 ₸** (2 400 − 585, which assumes user_1 has only t1 and t2). The per-day reference cases (§3, 2026-10-01) are unaffected. |
| **F7** | The prompt names the seed switch `DEMO_SEED`; the code has `SEED_ON_STARTUP` (trips file). | Naming only; decide one switch (or an alias) in stage 1. |
| **F8** | No accounts, sessions or authorization anywhere (expected: stages 2–3). Every endpoint is public and every client sees all trips. | Fixed by stage 2. |

## 5. Checklist for stage 6

- [x] F1 — one named timezone constant in the app (`AppConfig` default from `DriverZone.kazakhstan`). *(stage 1, `test/core/time_test.dart`)*
- [x] F2 — production fails fast without `DATABASE_URL` (no localhost default outside local/test). *(stage 1: `APP_ENV=production` in the image; `tests/unit/test_settings.py`)*
- [x] F3 — CORS decision recorded in DECISIONS.md and the deployed value set accordingly. *(kept `*`: bearer tokens, no cookies)*
- [ ] F4 — Railway config-as-code migration or a documented decision before 2026-12-01.
- [x] F5 — user_2 seed trips use ids that don't collide with `data/trips.json`. *(`u2-t1`, `u2-t2`)*
- [ ] F6 — seed/backfill and the expected balances agree (decision pending).
- [x] F7 — one seed switch, documented in README. *(`SEED_ON_STARTUP`)*
- [ ] F8 — auth + role scoping on every endpoint, tested and checked on the deployed URL.
