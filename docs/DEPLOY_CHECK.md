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
