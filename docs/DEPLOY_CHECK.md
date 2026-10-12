# Deploy check

Checks against the deployed API and database. Stage 6 completes this file; entries are added as each stage touches production.

## Stage 1 — production data cleanup before the accounts migration (2026-10-09)

### Backup

- Taken before any change to production, with `pg_dump` run inside the Railway Postgres container (`railway ssh --service Postgres`), plain SQL, `--no-owner --no-privileges`.
- File: `C:\Users\alish\Documents\arqa-backups\prod-2026-10-09-before-stage1.sql` (16 415 bytes). It is **outside the repository** and never committed.
- Verified by restoring it into a throwaway PostgreSQL 18 container (production runs 18.6): 139 trips, Σamount 405 500 ₸, `alembic_version` = `0001`.

### Test trips removed

Trips created while testing the app and the earlier deploy check; none of them is in `data/trips.json`. Each shortened id was resolved on production first: every prefix matched exactly one row with the expected start and amount.

| id | start (+05:00) | amount | payment | commission |
|---|---|---|---|---|
| `deploy-check-1791296000` | 2026-10-05 10:00 | 1 000 ₸ | cash | 150 |
| `27383a33-165a-4dd7-a85a-c45c3b294b41` | 2026-10-06 01:02 | 5 000 ₸ | cash | 600 |
| `d965ef01-c970-4444-936b-7fbea3bf139b` | 2026-10-06 08:13 | 500 ₸ | card | 0 |
| `9537da05-76a1-4e92-abea-faba4da78a75` | 2026-10-06 08:31 | 500 ₸ | card | 0 |
| `705c0276-6c85-4989-b003-1455c19785aa` | 2026-10-06 09:50 | 500 ₸ | card | 0 |
| `d8398d6e-dc64-4b31-8c94-de3d4c0e9918` | 2026-10-06 23:25 | 500 ₸ | cash | 0 |
| `47aafda5-34b5-42cf-bfbe-eb0969d1f248` | 2026-10-07 08:24 | 500 ₸ | card | 0 |
| `65415a42-67a5-49a5-96e9-4d2409f720aa` | 2026-10-07 08:24 | 500 ₸ | card | 0 |

How: one transaction (`psql --single-transaction`, `ON_ERROR_STOP`), `DELETE FROM trips WHERE id IN (<8 full ids>) RETURNING id` in a `DO` block that raises (and so rolls back) unless exactly 8 rows were deleted.

Result:

- deleted: 8 rows, the ids above;
- trips: **139 → 131**, checked again from a new connection; none of the 8 ids remains;
- the remaining 131 trips are exactly the trips of `data/trips.json` that belong to user_1 (the file's other 2 are user_2's new `u2-t1` / `u2-t2`, added by the stage 1 seed).

## Stage 1 — deploy (2026-10-09)

- Tag `v1.0` (annotated, «Redesign complete, submission-ready») points at `9adc869` — the submission before the accounts iteration.
- Deployed from `main` at `6c11ab4` with `railway up --service api --ci`. Deployment `7f07e6a7-cb44-4aa4-856a-2702e4585c3f`: **SUCCESS** (healthcheck passed; the previous deployment was removed).
- Deploy log:
  ```
  Running upgrade 0001 -> 0002, accounts: users, sessions, withdrawals; trips get an owner (driver_id)
  seed: 2 demo accounts created, 1 passwords reset
  seed: inserted 2 of 133 trips from /app/data/trips.json
  ```
  (user_1 was created by the migration with the placeholder hash, then given its password by the seed.)

### API

| Check | Result |
|---|---|
| `GET /health` | 200 `{"status":"ok","database":"ok"}` |
| `GET /summary?date=2026-10-01&tz=%2B05:00` | 200: 2 trips, revenue 3 900, commission 585, net 3 315, cash 1 500, card 2 400 — **exact** |
| `GET /trips?date=2026-10-01` | `t1`, `t2` only (the API acts as user_1 until stage 2; user_2's trips are not mixed in) |

### Database (`railway ssh --service Postgres`, psql)

| Check | Result |
|---|---|
| Alembic revision | `0002` |
| Trips | 133 total, 0 without a driver |
| Accounts | `admin` (admin, «Администратор»), `user_1` (driver, «Водитель 1»), `user_2` (driver, «Водитель 2»); all active; every `password_hash` starts with `$argon2id$` (only the 10-character prefix was printed) |
| Trips per driver | user_1: 131, user_2: 2, admin: 0 |
| user_2's trips | `u2-t1` 2026-10-01 10:00, 3 000 ₸ card, commission 450; `u2-t2` 2026-10-01 12:15, 1 800 ₸ cash, commission 270 |
| 2026-10-01 per driver | user_1: 2 trips, 3 900 / 585; user_2: 2 trips, 4 800 / 720 |
| Sessions, withdrawals | 0, 0 |

**user_1's balance by the formula** (Σcard − Σcommission over all of user_1's trips − Σ withdrawals in `pending` or `paid`), computed in SQL:

```sql
WITH d AS (SELECT id FROM users WHERE login = 'user_1'),
     tr AS (SELECT coalesce(sum(amount) FILTER (WHERE payment = 'card'), 0) AS card_sum,
                   coalesce(sum(commission), 0) AS commission_sum
            FROM trips WHERE driver_id = (SELECT id FROM d)),
     w AS (SELECT coalesce(sum(amount), 0) AS withdrawn_sum FROM withdrawals
           WHERE driver_id = (SELECT id FROM d) AND status IN ('pending', 'paid'))
SELECT card_sum, commission_sum, withdrawn_sum,
       card_sum - commission_sum - withdrawn_sum AS user_1_available_balance
FROM tr, w;
```

Result: 258 450 − 58 123 − 0 = **200 327 ₸** — the same as computed from `data/trips.json` in the stage 0 audit (F6), so the deployed data is exactly the seed. The balance endpoint (stage 3) must return this value for user_1.

## Stage 2 — deploy with AUTH_REQUIRED=false (2026-10-09)

Allowed during stages 2–4 only with `AUTH_REQUIRED=false` (DECISIONS.md, «Branches and deploys»).

- Before the deploy: `railway variable set AUTH_REQUIRED=false --service api --skip-deploys`; the variable is also declared in `.railway/railway.ts` (`railway config plan`: already up to date — without it, the plan wanted to delete the variable).
- Rehearsed first with the production image on a fresh local database (`AUTH_REQUIRED=false`): migrations 0001 → 0003, seed, the README curl examples for login / me / summary / logout.
- Deployed from `main` at `29ff68a` (CI green) with `railway up --service api --ci`. Deployment `052aa7ab-74fd-4e50-bad3-d5c5f659f936`: **SUCCESS**, healthcheck passed.
- Deploy log: `Running upgrade 0002 -> 0003, login_failures …`; `seed: 0 demo accounts created, 0 passwords reset`; `seed: inserted 0 of 133 trips`.

| Check (deployed API) | Result |
|---|---|
| `GET /health` | 200 `{"status":"ok","database":"ok"}` |
| `GET /summary?date=2026-10-01` **without a token** (acts as user_1, like the released app) | 200: 2 trips, 3 900 / 585 / 3 315, cash 1 500 / card 2 400 — **exact** |
| `POST /auth/login` user_2, then `/summary` with its token | 2 trips, 4 800 / 720 / 4 080, cash 1 800 / card 3 000 |
| `POST /auth/login` admin, then `/summary` | all drivers: 4 trips, 8 700 / 1 305 / 7 395, cash 3 300 / card 5 400 |
| Unknown token | 401 `unauthorized` (checked even with AUTH_REQUIRED=false) |
| user_2's token with `driver_id` | 403 |
| `POST /auth/logout` (user_2, admin), then `/auth/me` | 204, then 401 |

Database after the checks: revision `0003`, 133 trips, 2 sessions (both from these checks, both revoked), 0 login failures.

## Fixes after stage 2: login lock per IP, protected demo accounts (2026-10-09)

Deployed from `main` with `AUTH_REQUIRED=false` (CI green each time). Final deployment `dd688105-b192-421d-8353-c3271bba4c54`: **SUCCESS**; migration `0003 -> 0004` (login_failures.client_ip); seed `0 created, 0 passwords reset, 0 unblocked`.

Variables on `api` (names): `AUTH_REQUIRED` (false), `CLIENT_IP_HEADER` (x-real-ip), `DATABASE_URL`; all declared in `.railway/railway.ts` (`railway config plan`: up to date).

**How the client IP was verified** (probes with a made-up login, so no demo account was affected):

| Probe | X-Forwarded-For seen by the API | X-Real-IP seen by the API |
|---|---|---|
| my machine, sent `X-Forwarded-For: 1.2.3.4` | `1.2.3.4, 152.233.12.245` (Railway's internal hop) | `147.30.27.152` = my public IP |
| inside the API container (its egress IP `152.55.186.0`) | `1.2.3.4, 152.233.12.241` | `152.55.186.0` |
| my machine, sent `X-Real-IP: 9.9.9.9` | — | `147.30.27.152` (forged value overwritten) |

So Railway's `X-Forwarded-For` never contains the client and `X-Real-IP` does → `CLIENT_IP_HEADER=x-real-ip` (TRUSTED_PROXY_HOPS removed).

| Check | Result |
|---|---|
| 11 failed logins for `lock-probe` from my machine (with forged `X-Forwarded-For` and `X-Real-IP`) | 401 ×10, then **429**; logged as `147.30.27.152` |
| the same login from the API container | **401** (not locked) |
| admin blocks user_2 / revokes user_2's sessions | **409 `demo_account_protected`** both |
| `GET /health` | 200 |
| `GET /summary?date=2026-10-01` without a token | 3 900 / 585 / 3 315, cash 1 500 / card 2 400 — exact |

The `lock-probe` and `xff-probe*` failure rows expire on their own within 15 minutes (old rows are deleted as new failures are recorded).

## Stage 3 — withdrawals (2026-10-09)

- Rehearsed with the production image on a fresh local database (`AUTH_REQUIRED=false`): user_2 2 280 → 1 280 after one withdrawal (its retry: 200); user_1 without a token: 200 327.
- Deployed from `main` at `6386aca` (CI green, concurrency tests on CI's Postgres) with `railway up --service api --ci`. Deployment `951e4254-3b1d-4bb9-aeea-27909ae1a9ca`: **SUCCESS**.

| Check (deployed API) | Result |
|---|---|
| `GET /health` | 200 |
| `GET /summary?date=2026-10-01` without a token | 3 900 / 585 / 3 315, cash 1 500 / card 2 400 — exact |
| `GET /balance` without a token (user_1) | `available` **200 327** = card 258 450 − commission 58 123 − withdrawn 0, the SQL formula of stage 1 |

**Withdrawals, user_2 only** (balance after each step):

| Step | Response | available |
|---|---|---|
| start | — | 2 280 |
| W1 = `345e8474-e0bc-4e74-a969-8c051f5bb4c2`, 1 000 | 201 pending | 1 280 |
| W1 again, same amount | 200, the same withdrawal | 1 280 |
| W1 with 900 | 409 `withdrawal_conflict` | 1 280 |
| a new id with 2 000 | 422 `insufficient_funds` (no row) | 1 280 |
| W2 = `b8f3b52f-50d1-43a8-970e-7137684dfeff`, 500 | 201 pending | 780 |
| admin approves W1, twice | paid; 200 both times | 780 (paid stays spent) |
| admin rejects W2 «Проверка деплоя», twice | rejected; 200 both times | **1 280** (money back) |
| admin rejects W1 (already paid) | 409 `withdrawal_already_decided` | 1 280 |

(The first reject attempt from Git Bash sent the Cyrillic reason in a non-UTF-8 encoding and got 400 `http_error`; it was repeated with escaped JSON. This led to the `invalid_json` fix below.)

### Cleanup of the test withdrawals

- Backup first: `C:\Users\alish\Documents\arqa-backups\prod-2026-10-09-before-withdrawal-cleanup.sql` (29 709 bytes, outside the repository). Restored into a throwaway PostgreSQL 18: revision `0004`, 133 trips, 2 withdrawals.
- One transaction (`psql --single-transaction`, `ON_ERROR_STOP`): `DELETE FROM withdrawals WHERE id IN (W1, W2) RETURNING …` in a `DO` block that raises (and so rolls back) unless exactly 2 rows were deleted.
- Deleted: `345e8474-e0bc-4e74-a969-8c051f5bb4c2` (1 000, paid) and `b8f3b52f-50d1-43a8-970e-7137684dfeff` (500, rejected). Withdrawals: **2 → 0**, checked again from a new connection.
- After: user_2 `GET /balance` → available **2 280** (card 3 000, commission 720, withdrawn 0), `GET /withdrawals` → `[]`; user_1 still 200 327.


## Fix: unreadable bodies are 422 invalid_json (2026-10-09)

Deployed from `main` at `547c279` (CI green), `AUTH_REQUIRED=false`. Deployment `f16f9018-4b39-4d07-bb65-727c8af70277`: **SUCCESS**.

| Check | Result |
|---|---|
| `GET /health` | 200 |
| `GET /summary?date=2026-10-01` without a token | 3 900 / 585 / 3 315, cash 1 500 / card 2 400 — exact |
| `POST /trips` with a body that is not UTF-8 | 422 `{"error":{"code":"invalid_json",…}}` (was 400 `http_error`) |

## Stage 6 — accounts go live (2026-10-12)

### Backup

- `C:\Users\alish\Documents\arqa-backups\prod-2026-10-12-before-stage6.sql` (29 552 bytes, outside the repository), taken with `pg_dump` inside the Postgres container as before.
- Restored into a throwaway PostgreSQL 18: revision `0004`, 133 trips (Σ 401 300 ₸), 0 withdrawals, users `admin`, `user_1`, `user_2` (all active), 8 sessions.

### Release build

- `flutter build apk --release` from `main` at `f0731c6` (clean tree, CI green): `app-release.apk`, 56 506 188 bytes, sha256 `2978330bc473c09ee64dd0a7830998a89ff93e7b00c7538071b11db7483fe4dc`. Published as `driver-diary.apk` in GitHub release `v2.0.0`.
- The on-device check of the APK against prod before the switch was skipped at the user's request. The same app code is covered by the widget, golden and layout tests (531) and its API contract by the checks below.

### Deploy and switch

| Time (UTC) | Step | Result |
|---|---|---|
| 06:48 | `railway up --service api --ci` from `main` (`f0731c6`, `driver_id` in `GET /trips`), `AUTH_REQUIRED=false` | deployment `117d8bad-fa36-4e2b-8e97-440bcc990728` SUCCESS, healthcheck passed |
| 06:48 | before the switch: `/health`, `GET /trips` without a token (old mode), login of `user_1`, `user_2`, `admin` | 200; trips carry `driver_id`; all three logins 200 with the right roles |
| 06:49:24 | `railway variables --service api --set AUTH_REQUIRED=true` (the variable change redeploys) | deployment `695eb82d-41fe-44d6-aee5-28c8f4bf8c52` SUCCESS |
| 06:49:43 | `GET /summary` without a token | **401** `unauthorized` — the switch took 20 s |

Rollback plan (not needed): `railway variables --service api --set AUTH_REQUIRED=false` restores anonymous access as `user_1` within ~20 s.

### Verification against https://api-production-6e8b.up.railway.app

Run by a script (`curl` with the DNS name pinned); tokens were kept in shell variables and never printed. Writes only as `user_2`. Every session opened by the run was logged out at the end.

| Check | Result | |
|---|---|---|
| GET /health | 200 {"status":"ok","database":"ok"} | ✅ |
| GET /trips?date=2026-10-01&tz=%2B05:00 without token | 401 {"error":{"code":"unauthorized","message":"a valid beare | ✅ |
| GET /summary?date=2026-10-01&tz=%2B05:00 without token | 401 {"error":{"code":"unauthorized","message":"a valid beare | ✅ |
| GET /balance without token | 401 {"error":{"code":"unauthorized","message":"a valid beare | ✅ |
| GET /withdrawals without token | 401 {"error":{"code":"unauthorized","message":"a valid beare | ✅ |
| GET /auth/me without token | 401 {"error":{"code":"unauthorized","message":"a valid beare | ✅ |
| GET /admin/users without token | 401 {"error":{"code":"unauthorized","message":"a valid beare | ✅ |
| GET /trips with an unknown token | 401 {"error":{"code":"unauthorized","message":"the session i | ✅ |
| login user_1 → /auth/me | 200 user_1 driver Водитель 1 | ✅ |
| login user_2 → /auth/me | 200 user_2 driver Водитель 2 | ✅ |
| login admin → /auth/me | 200 admin admin Администратор | ✅ |
| wrong password | 401 {"error":{"code":"invalid_credentials","message":"invalid login or | ✅ |
| user_1 summary | 2 trips, 3900/585/3315, cash 1500 card 2400 | ✅ |
| user_2 summary | 2 trips, 4800/720/4080, cash 1800 card 3000 | ✅ |
| admin summary, all drivers | 4 trips, 8700/1305/7395, cash 3300 card 5400 | ✅ |
| admin summary, driver_id=user_2 | 2 trips, 4800/720/4080, cash 1800 card 3000 | ✅ |
| admin trips carry driver_id | t1:u1 t2:u1 u2-t1:u2 u2-t2:u2 | ✅ |
| user_1 sees only own trips | t1 t2 | ✅ |
| user_2 sees only own trips | u2-t1 u2-t2 | ✅ |
| driver → GET /admin/users | 403 {"error":{"code":"forbidden","message":"admin | ✅ |
| driver → another driver's trips | 403 {"error":{"code":"forbidden","message":"driver | ✅ |
| admin → POST /trips | 403 {"error":{"code":"forbidden","message":"only d | ✅ |
| new trip | 201 | ✅ |
| same id, same payload | 200 | ✅ |
| same id, other amount | 409 {"error":{"code":"trip_conflict","message":"trip 'stage6 | ✅ |
| same id from user_1 | 409 existing_leaked=0 | ✅ |
| user_2 balance before | 2280 | ✅ |
| W1 1000 new | 201 pending | ✅ |
| W1 again, same amount | 200 | ✅ |
| W1 again, other amount | 409 {"error":{"code":"withdrawal_conflict","message":"withdrawal 0e520 | ✅ |
| 5000 > available | 422 {"error":{"code":"insufficient_funds","message":"amount is more th | ✅ |
| amount 0 | 422 | ✅ |
| W2 500 new | 201 | ✅ |
| balance after W1+W2 pending | 780 | ✅ |
| admin → POST /withdrawals | 403 | ✅ |
| driver → approve | 403 | ✅ |
| approve W1 | 200 paid | ✅ |
| approve W1 again | 200 paid | ✅ |
| balance after approve (paid stays spent) | 780 | ✅ |
| reject W2 with a Cyrillic reason | 200 rejected Проверка деплоя | ✅ |
| reject W2 again | 200 | ✅ |
| reject W1 (already paid) | 409 {"error":{"code":"withdrawal_already_decided","message":"withdrawal 0e520a64 | ✅ |
| balance after reject (money back) | 1280 | ✅ |
| user_1 sees none of user_2's withdrawals | 0 | ✅ |
| admin sees user_2 balance | 1280 | ✅ |
| block user_2 | 409 {"error":{"code":"demo_account_protected","message":"'user_2' is a | ✅ |
| revoke user_2 sessions | 409 {"error":{"code":"demo_account_protected","message":"'user_2' is a | ✅ |
| user_2 token still works | 200 | ✅ |
| fresh session works | 200 | ✅ |
| logout | 204 | ✅ |
| same token after logout | 401 {"error":{"code":"unauthorized","message":"the session i | ✅ |
| user_1's other session unaffected | 200 | ✅ |

The first run's three `login … → /auth/me` lines failed in the **script**, not on the server: the pattern expected raw JSON but was compared with the parsed «200 user_1 driver». They were re-run with the right pattern (the rows above); every value was already correct.

Also checked: `user_1` `GET /balance` = **200 327 ₸** (card 258 450 − commission 58 123, no withdrawals), as computed in stage 3 (PROD_AUDIT F6).

### Test data the run left on prod (removed, see below)

| Kind | id | Owner | Details |
|---|---|---|---|
| trip | `stage6-check-1791787840` | user_2 | 2026-10-11 10:00–10:20 +05:00, 1 000 ₸, cash, commission 0 (no effect on the balance) |
| withdrawal | `0e520a64-45fb-4501-ad90-e8940f98c602` | user_2 | 1 000 ₸, paid |
| withdrawal | `f79636d1-c005-4362-9c4c-7d2845d0ae17` | user_2 | 500 ₸, rejected «Проверка деплоя» |

- Backup before the cleanup: `C:\Users\alish\Documents\arqa-backups\prod-2026-10-12-before-stage6-cleanup.sql` (31 665 bytes), restored into a throwaway PostgreSQL 18: revision `0004`, 134 trips, 2 withdrawals.
- These are the only rows the run added (prod: 134 trips, 2 withdrawals). user_2's balance is 1 280 ₸ until the paid withdrawal is removed; after the cleanup it returns to 2 280 ₸.

### Cleanup of the stage 6 test data (2026-10-12, after «delete»)

- Before deleting, prod had one more withdrawal than the run created: `53c0dcf4-a06f-4dd2-b3bc-1e7ce3fc34a2`, user_1, 200 327 ₸. It was created at 07:16 UTC (about 15 min after the v2.0.0 release) and rejected by `admin` at 07:17 with the reason «g». It is not test data of this run and was not in the «delete» list, so it **was kept**. Being rejected, it does not change any balance.
- Backup first, taken again because of that new row: `C:\Users\alish\Documents\arqa-backups\prod-2026-10-12-before-stage6-cleanup-2.sql` (32 813 bytes). Restored into a throwaway PostgreSQL 18: revision `0004`, 134 trips, 3 withdrawals.
- One transaction (`BEGIN … COMMIT`, `ON_ERROR_STOP`), a `DO` block that deletes the trip `stage6-check-1791787840` and the withdrawals `0e520a64-45fb-4501-ad90-e8940f98c602`, `f79636d1-c005-4362-9c4c-7d2845d0ae17`, and raises (so rolls back) unless exactly 1 trip + 2 withdrawals were deleted. Result: `NOTICE: deleted 1 trip and 2 withdrawals`, `COMMIT`.
- Checked from a new connection: trips **134 → 133**, withdrawals **3 → 1** (the kept user_1 row); none of the three ids remains.
- After: user_2 `GET /balance` → available **2 280** (card 3 000, commission 720, withdrawn 0), `GET /withdrawals` → `[]`. user_1 still **200 327**.

### Release APK on an emulator against prod (2026-10-12)

The v2.0.0 asset itself: `gh release download v2.0.0`, sha256 `2978330b…83fe4dc` (matches the build). Installed on the Android emulator (`Medium_Phone_API_37.0`, 1080×2400), driven with `adb` and `uiautomator`. No trips or withdrawals were created. The logins opened two sessions, both closed with «Выйти». Screenshots: `docs/design/release_check/`.

| Step | Seen on the device | |
|---|---|---|
| Start | login screen, «Русский» selected | ✅ `01_login` |
| First attempt: `adb input text` dropped characters of the masked password | «Неверный логин или пароль» under the password (real 401 from prod; 1 failed attempt, limit 10) | ✅ |
| Sign in `user_1` / `password_1` | Day screen, today (12 October) empty | ✅ `02_day_today` |
| ‹ ×11 → 1 October | net **3 315 ₸** (spoken «3 315 тенге»), revenue 3 900, commission −585, cash 1 500 / card 2 400, 2 trips | ✅ `03_user1_oct1_ru` |
| Menu | «Водитель 1», «@user_1 · Водитель», «Вывод средств · Доступно 200 327 ₸», «Версия 0.2.0» | ✅ `04_menu_ru` |
| «Қазақша» in the menu | applied at once: «Мәзір», «Қаражат шығару», «Қолжетімді: 200 327 ₸», «Нұсқа 0.2.0» | ✅ `05_menu_kk` |
| «Қаражат шығару» (not sent) | balance 200 327 (card 258 450, commission −58 123, withdrawn 0); history: the kept 200 327 ₸ «Қабылданбады», reason «g» | ✅ `06_withdraw_kk` |
| Back to the day | «Қолға 3 315 ₸», «2026 ж. 1 қазан» | ✅ `07_user1_oct1_kk` |
| «Шығу» → confirm | dialog «Аккаунттан шығу керек пе?», then the login screen (in Kazakh, no «session ended» message) | ✅ `08`, `09` |
| Sign in `admin` / `admin` | admin screen, three tabs, chips «Барлық жүргізушілер / Водитель 1 / Водитель 2» | ✅ `10_admin_today_kk` |
| ‹ ×11 → 1 October, all drivers | **7 395 ₸**, revenue 8 700, commission −1 305, 4 trips, each row labelled «Водитель 1» / «Водитель 2» (`driver_id` from the new backend) | ✅ `11_admin_all_oct1_kk` |
| Chip «Водитель 2» | **4 080 ₸**, revenue 4 800, commission −720, 2 trips | ✅ `12_admin_driver2_oct1_kk` |
| «Шығу» → confirm, «Русский» | login screen in Russian | ✅ `13_logged_out_ru` |

Note from the run: at 360-ish widths the third chip «Водитель 2» is partly behind the edge of the scrolling row in Kazakh (by design; the UI stability pass covers it).

### Cleanup of the user's own test withdrawal (2026-10-12, after «delete»)

- The withdrawal kept above (`53c0dcf4-a06f-4dd2-b3bc-1e7ce3fc34a2`, user_1, 200 327 ₸, rejected, reason «g») was the user's own test from the v2.0.0 app.
- Backup first: `C:\Users\alish\Documents\arqa-backups\prod-2026-10-12-before-g-withdrawal-cleanup.sql` (33 250 bytes). Restored into a throwaway PostgreSQL 18: revision `0004`, 133 trips, 1 withdrawal.
- Re-checked right before deleting: the table held exactly that row.
- One transaction (`BEGIN … COMMIT`, `ON_ERROR_STOP`), a `DO` block that deletes the row matching id, amount 200 327, status `rejected` and reason «g», and raises (so rolls back) unless exactly 1 row was deleted. Result: `NOTICE: deleted 1 withdrawal`, `COMMIT`.
- Checked from a new connection: trips **133**, withdrawals **1 → 0**.
- After: user_1 `GET /balance` → available **200 327** (card 258 450, commission 58 123, withdrawn 0), `GET /withdrawals` → `[]`.

## Release v2.0.1 (2026-10-12)

The UI stability fixes (DESIGN.md §10) and their guard tests. Mobile app only: the backend is unchanged and was not deployed.

- `flutter build apk --release` from `main` at `44f43a6` (CI green, app version `0.2.1+3`): `app-release.apk`, 56 538 952 bytes, sha256 `263b889a6361c12513982a8224713c291c1cd1e5001fb668c77ae3b444756764`. Published as `driver-diary.apk` in GitHub release `v2.0.1`.
- Installed over v2.0.0 on the Android emulator (`Medium_Phone_API_37.0`, 1080×2400), app data cleared, against prod.
- The same read-only check as for v2.0.0. No trips or withdrawals were created, no withdrawal was decided. The two logins opened two sessions, both closed with «Шығу».
- Screenshots: `docs/design/release_check/v2.0.1/`.

| Step | Seen on the device | |
|---|---|---|
| Start | login screen, «Русский» selected | ✅ `01_login` |
| Sign in `user_1` / `password_1` (first try) | Day screen, today (12 October) empty | ✅ `02_day_today` |
| ‹ ×11 → 1 October | net **3 315 ₸**, revenue 3 900, commission −585, «Наличные · 38%» 1 500 / «Карта · 62%» 2 400, 2 trips | ✅ `03_user1_oct1_ru` |
| Menu | «Водитель 1», «@user_1 · Водитель», «Вывод средств · Доступно 200 327 ₸», «Версия 0.2.1» | ✅ `04_menu_ru` |
| «Қазақша» in the menu | applied at once: «Мәзір», «Қолжетімді: 200 327 ₸», «Нұсқа 0.2.1» | ✅ `05_menu_kk` |
| «Қаражат шығару» (not sent) | balance 200 327 (card 258 450, commission −58 123, withdrawn 0); history empty after the cleanup above | ✅ `06_withdraw_kk` |
| Back to the day | «Қолға 3 315 теңге», «2026 ж. 1 қазан» | ✅ `07_user1_oct1_kk` |
| «Шығу» → confirm | dialog «Аккаунттан шығу керек пе?», then the login screen in Kazakh | ✅ `08`, `09` |
| Sign in `admin` / `admin` | admin screen, the new short tabs «Сапарлар / Шығару / Жүргізуші» on one line | ✅ `10_admin_today_kk` |
| ‹ ×11 → 1 October, all drivers | **7 395 ₸**, revenue 8 700, commission −1 305, 4 trips, rows labelled «Водитель 1» / «Водитель 2» | ✅ `11_admin_all_oct1_kk` |
| Chip «Водитель 2» | **4 080 ₸**, revenue 4 800, commission −720, 2 trips | ✅ `12_admin_driver2_oct1_kk` |
| Tab «Шығару» (view only) | «Өңделуде» filter, «Өтінім жоқ» | ✅ `13_admin_withdrawals_kk` |
| «Шығу» → confirm, «Русский» | login screen in Russian | ✅ `14_logged_out_ru` |


## Maps — ORS_API_KEY on the api service (2026-10-12)

Configuration only: no code change, no migration, no data change. The key is for the maps iteration (`docs/MAPS.md`); the running code does not read it yet.

- The variable was added in the Railway dashboard as a staged change. Before deploying, the staged patch held exactly one change: `api` → variable `ORS_API_KEY` added, not destructive.
- Deployed by committing the staged change (deployment `181eee4b`, 15:29 UTC, `SUCCESS`).
- Locally the key is in `backend/.env`, ignored by git (`git check-ignore -v backend/.env` → `.gitignore:10:.env`). One reverse-geocode request to ORS from the developer machine returned 200.
- The value was never printed; only the name was checked.

| Check after the deploy | Result | |
|---|---|---|
| `GET /health` | 200 `{"status":"ok","database":"ok"}` | ✅ |
| `POST /auth/login` user_1 | 200, role driver | ✅ |
| `GET /summary?date=2026-10-01&tz=%2B05:00` with its token | 2 trips, 3 900 / 585 / **3 315**, cash 1 500 / card 2 400 — exact | ✅ |
| `POST /auth/logout` | 204 | ✅ |
| Variable names on `api` | `ORS_API_KEY` present (non-empty) | ✅ |
