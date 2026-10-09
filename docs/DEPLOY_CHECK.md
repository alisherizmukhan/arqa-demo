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

### Not done yet

- Deploying stage 1 (`railway up`) — waiting for approval.
