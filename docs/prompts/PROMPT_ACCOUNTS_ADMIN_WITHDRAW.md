# Промпт: аккаунты, роли, админка, вывод денег, ru/kk, Railway

Запускать **после** завершения редизайна (этапы 4–6). Перед запуском положите этот файл в `docs/` — промпт ссылается на раздел «Design addendum» ниже.

```
Next iteration of "Дневник смен": accounts and roles, admin panel, withdrawals, in-app language switch (ru/kk), mandatory Postgres on Railway, production-readiness. Work in stages; after each stage stop, show what was done (screenshots for UI, command output for backend/deploy) and wait for my "ok". Record every decision in docs/DECISIONS.md (decision → why) and AI mistakes in docs/AI_NOTES.md.

Keep all existing rules from the original task (integer money, day boundaries in +05:00, trip idempotency 200/201/409, 422 error shape, clean architecture, Riverpod, design_kit only, zero analyzer warnings). DESIGN.md stays the source of truth for the existing screens; new screens follow the "Design addendum" below, which you add to DESIGN.md as §8 (root + kit copy).

────────────────────────────────────────
0. Audit first (no code changes) → docs/PROD_AUDIT.md
- Data flow: every number on the Day screen comes from the API → Postgres. Grep release code (apps/mobile/lib, packages/design_kit/lib; not example/ or test/) for mockup values: 3315, 3 315, 3900, 585, 2400, 1500, 360, 225, "08:10", "09:05", "2026", "октября", fake/mock/demo/stub repositories, hardcoded DateTime(…) or "today". Each hit = finding.
- Config: API_URL via --dart-define; timezone +05:00 is one named constant; backend settings only via env (pydantic-settings); no localhost fallbacks in production paths.
- Railway: run `railway status`, `railway service`, `railway variables` (print variable NAMES only, never values). Report: project linked? backend service? Postgres service? DATABASE_URL referenced? /health 200?
  If the CLI is not logged in, stop and ask me to run `railway login` myself.

────────────────────────────────────────
1. Database is mandatory (Postgres on Railway)
- If the linked Railway project has no Postgres: `railway add --database postgres`, set the backend variable DATABASE_URL to the reference ${{Postgres.DATABASE_URL}}, redeploy. If Postgres exists, only verify the link. Never delete/recreate services, volumes or data; ask me before anything destructive or paid.
- Local: docker-compose Postgres stays; tests use real Postgres.
- Alembic migrations for all new tables (below). Migrations must run on an existing DB with the current trips table (backfill driver_id for existing rows = user_1).

────────────────────────────────────────
2. Accounts, roles, sessions (backend)
Tables:
- users(id UUID PK, login TEXT UNIQUE, password_hash TEXT, role TEXT CHECK IN ('driver','admin'), display_name TEXT, is_active BOOL DEFAULT true, created_at TIMESTAMPTZ)
- sessions(id UUID PK, user_id FK, token_hash TEXT UNIQUE, created_at, last_used_at, revoked_at NULL, user_agent TEXT NULL)
- trips: add driver_id UUID FK NOT NULL (index on driver_id, start).
- withdrawals (see §4).

Seed (idempotent, runs on startup when DEMO_SEED=true, default true; credentials overridable by env so production can change them without code):
- user_1 / password_1 — role driver, display_name "Водитель 1"
- user_2 / password_2 — role driver, display_name "Водитель 2"
- admin / admin — role admin
- Trips from data/trips.json: add "driver": "user_1" to t1, t2; add two trips for user_2 on 2026-10-01:
  {"id":"t3","driver":"user_2","start":"2026-10-01T10:00:00+05:00","end":"2026-10-01T10:40:00+05:00","amount":3000,"payment":"card","commission":450}
  {"id":"t4","driver":"user_2","start":"2026-10-01T12:15:00+05:00","end":"2026-10-01T12:35:00+05:00","amount":1800,"payment":"cash","commission":270}
- Passwords hashed with argon2id (argon2-cffi) or bcrypt. Never store or log plaintext. README must state these are demo credentials and how to override them (SEED_ADMIN_PASSWORD, SEED_USER1_PASSWORD, SEED_USER2_PASSWORD).

Auth:
- POST /auth/login {login, password} → 200 {token, user:{id, login, role, display_name}}; wrong credentials → 401 {error:{code:"invalid_credentials"}} (same response for unknown login and wrong password). Simple rate limit: 10 failed attempts per login per 15 min → 429.
- Token = opaque random 32 bytes (base64url). Store only sha256(token) in sessions. **No expiry**: the session stays valid until the user logs out or an admin revokes it. Update last_used_at at most once per hour.
- Authorization: Bearer <token> on every endpoint except /health and /auth/login. Missing/revoked/unknown → 401. Inactive user → 401.
- POST /auth/logout → revokes the current session (204). GET /auth/me → current user.
- Why opaque tokens and not a non-expiring JWT: a JWT without expiry cannot be revoked, so logout would be fake. Write this in DECISIONS.md.

Authorization rules (enforce in the application layer + tests for every endpoint):
- driver: sees and creates only own trips/withdrawals. Any driver_id parameter from a driver is ignored/forbidden (403).
- admin: sees everything; endpoints accept optional driver_id (absent = all drivers aggregated).
- Trip idempotency now per owner: same id from the same driver → existing rules (200/409 with "existing"); id already used by ANOTHER driver → 409 trip_conflict WITHOUT "existing" (never leak other drivers' data).

Endpoints (existing ones now require auth and are scoped by role):
- GET /trips?date=&tz=[&driver_id=]   GET /summary?date=&tz=[&driver_id=]   POST /trips (driver only)
- GET /balance[?driver_id=]   GET /withdrawals[?driver_id=&status=]   POST /withdrawals (driver only)
- Admin only: GET /admin/users, PATCH /admin/users/{id} {is_active}, POST /admin/users/{id}/revoke-sessions, POST /admin/withdrawals/{id}/approve, POST /admin/withdrawals/{id}/reject {reason}
- OpenAPI shows the bearer scheme, all error shapes (401/403/409/422/429) with examples.

────────────────────────────────────────
3. Reference cases (tests on backend AND client domain)
- user_1, 2026-10-01: 2 trips, revenue 3900, commission 585, net 3315, cash 1500 / card 2400.
- user_2, 2026-10-01: 2 trips, revenue 4800, commission 720, net 4080, cash 1800 / card 3000.
- admin, all drivers, 2026-10-01: 4 trips, revenue 8700, commission 1305, net 7395, cash 3300 / card 5400.
- user_1 must get 0 trips of user_2 and vice versa (403 or empty — test both list and summary).

────────────────────────────────────────
4. Withdrawals (вывод денег) — this is the vacancy's question 4, implement it carefully
Domain rule (record in DECISIONS.md): card payments go to the park; cash stays with the driver; the park's commission is owed on ALL trips. So
  available_balance = Σ card amounts − Σ commissions (all trips) − Σ withdrawals in status pending or paid.
It can be ≤ 0 (then withdrawal is impossible). Integers only.
- withdrawals(id UUID PK = client idempotency key, driver_id FK, amount INT CHECK > 0, status TEXT CHECK IN ('pending','paid','rejected'), reject_reason TEXT NULL, created_at, decided_at NULL, decided_by FK users NULL).
- POST /withdrawals {id, amount}: client generates id (UUID v4) when the user taps «Вывести»; retries reuse it.
  same id + same amount → 200 existing; same id + different amount → 409; new → 201 pending.
  amount > available → 422 {code:"insufficient_funds", field:"amount"}. amount ≤ 0 → 422.
- Double-spend protection: inside one transaction lock the driver's row (SELECT … FROM users WHERE id=… FOR UPDATE), recompute balance, insert with ON CONFLICT (id) DO NOTHING, then fetch and compare. Tests: two concurrent POSTs with the same id → one row; two concurrent POSTs with different ids whose sum exceeds the balance → exactly one succeeds, the other 422.
- Admin approve → paid; reject → rejected (money returns to available). Approve/reject are idempotent (repeating returns current state; deciding an already-decided withdrawal differently → 409).
- Balance for seed: user_1 = 2400 − 585 = 1815 ₸; user_2 = 3000 − 720 = 2280 ₸. Test these.

────────────────────────────────────────
5. Mobile app
- Auth: token in flutter_secure_storage; on start: token present → GET /auth/me → home by role; 401 anywhere → clear token, go to Login (with snackbar «Сессия завершена. Войдите снова.»). Never log the token. No automatic logout by time.
- Logout: in the menu, with confirm dialog; calls POST /auth/logout (if offline, clear locally anyway and retry the call later is NOT needed — just clear).
- Language: in-app switch Русский / Қазақша in the Menu screen AND on the Login screen; stored locally (shared_preferences), applied immediately without restart; default = device language if ru/kk, else ru.
  flutter_localizations + gen-l10n, ARB: app_ru.arb (source) + app_kk.arb. Every visible string via AppLocalizations; design_kit has no strings of its own (texts are parameters). CI grep: no Cyrillic literals in apps/mobile/lib and packages/design_kit/lib outside generated l10n.
  Plurals via ICU (ru one/few/many/other; kk one/other). Dates via intl with the active locale (kk e.g. "2026 ж. 1 қазан"; Сегодня/Бүгін, Вчера/Кеше). Money format identical in both (U+202F, ₸).
  Server errors: show localized text by error code/field, never the server message.
  Kazakh strings are machine translations: list them in docs/L10N.md as ru | kk | "needs native review".
- Role routing: driver → Day screen (own data). admin → Admin screen (§8.6).
- Withdrawals: screen per §8.4; idempotent retries with the same id (same policy as trips: snackbar immediately on first failure, background retries 2/4/8/30 s, «Повторить»); editing the amount after a failed send → new id.
- Run all layout checks (360 and 390 dp, text scale 1.0 and 1.3, no overflow) in ru AND kk; goldens for Login, Menu, Withdraw, Admin in both languages, light + dark.

────────────────────────────────────────
6. Stages (stop after each)
0. Audit (§0) — no changes.
1. Railway Postgres + migrations + seed users/trips (§1, §2 tables, seed) + deploy check.
2. Auth + roles + scoping + tests (§2, §3).
3. Withdrawals backend + concurrency tests (§4).
4. Design addendum: add §8 to DESIGN.md, build new kit components, showcase screenshots of every new screen state in ru (light + dark) BEFORE wiring them. Wait for my "ok".
5. Mobile: login, menu, language switch, l10n ru/kk, withdrawals, admin; tests.
6. Deployed verification → docs/DEPLOY_CHECK.md: /health; login as each user; reference cases §3 against the deployed URL; trip idempotency 201/200/409; withdrawal 201/200/409/422 and balance after approve/reject; 401 after logout; 403 driver→admin endpoint. Update README (accounts, roles, demo credentials warning, how to switch language, screenshots ru + kk, admin flow). Tick PROD_AUDIT.md.

Constraints: small Conventional Commits; analyzers/mypy/ruff clean; all tests green; never print or commit secrets; don't change the visual design of existing screens beyond adding the menu button in the Day header (§8.2).
```

---

## Design addendum — DESIGN.md §8 (новые экраны в стиле варианта A)

Все экраны используют только существующие токены и компоненты. Новые компоненты перечислены в 8.0.

```
## 8. New screens (accounts, menu, withdrawals, admin)

### 8.0 New kit components
- DkIconButton: 48×48, radius md, icon 24, transparent; used in headers.
- DkListGroup + DkListRow: DkCard(padding 0, clip) with rows min 56, padding 0 16, gap 12: leading icon tile 40 (surfaceMuted, icon 22), title bodyStrong (or titleM-weight 600 16/24), optional subtitle caption textTertiary, trailing (chevron-right 20 textTertiary | value | control). Dividers 1px divider inset 68. Destructive row: title + icon in `error`.
- DkStatusChip: height 24, radius sm, padding h 8, gap 4, icon 14 + text badge style.
  pending: bg surfaceMuted, fg textSecondary, icon clock; paid: bg successSoft, fg success, icon circle-check; rejected: bg errorSoft, fg error, icon circle-x. Always icon + text.
- DkPasswordField: DkTextField + trailing DkIconButton eye / eye-off («Показать пароль» / «Скрыть пароль»).
- DkLanguageSwitch: DkSegmentedControl with two segments «Русский» / «Қазақша» (no icons). Labels are always in their own language, never translated.
- DkFilterChips: horizontal scroll row of chips height 40 (tap area 48), radius pill, padding h 16; selected bg accent fg onAccent; unselected bg surface, border 1 border, fg textPrimary; label 14/600.

### 8.1 Login
- bg `bg`, SafeArea, padding 16. Top-right: DkLanguageSwitch compact (width 200, height 48).
- Centered block (max width 360): wordmark (accent square 16 + «Дневник смен» wordmark style), gap 32, title «Вход» titleL, gap 24, fields «Логин» (DkTextField, autofill username), gap 16 «Пароль» (DkPasswordField, autofill password), gap 24, DkButton primary expand «Войти» (loading «Входим…»).
- Error: under the password field, error row «Неверный логин или пароль». Rate-limit: «Слишком много попыток. Попробуйте через 15 минут.» Offline: error snackbar «Нет связи. Проверьте интернет.»
- Keyboard: Enter on login → focus password; Enter on password → submit.

### 8.2 Day screen header change (only change to existing screens)
- Wordmark row gets a trailing DkIconButton (icon `circle-user-round`, Semantics «Меню»). Opens Menu (8.3). Nothing else changes.

### 8.3 Menu («Меню»)
- Pushed page. App bar like Add trip but with back arrow (`chevron-left`, «Назад») instead of close; title «Меню».
- Profile card (DkCard, padding 16, row gap 12): icon tile 40 with `user-round`, column: display_name titleM, «@user_1 · Водитель» caption textTertiary (admin: «Администратор»).
- gap 16, DkListGroup:
  1. «Вывод средств» — icon `wallet`, subtitle «Доступно 1 815 ₸» (from /balance), chevron → 8.4. (Drivers only.)
  2. «Язык» — icon `languages`, trailing nothing; below the row inside the group: DkLanguageSwitch full width (padding 0 16 16).
- gap 16, DkListGroup: «Выйти» destructive row (icon `log-out`). Tap → DkDialog: icon log-out (errorSoft/error), title «Выйти из аккаунта?», message «Чтобы снова увидеть поездки, нужно будет войти по логину и паролю.», primary «Выйти», secondary «Отмена».
- Footer caption textTertiary centered: app version.

### 8.4 Withdraw («Вывод средств»)
- Pushed page, back arrow, title «Вывод средств». Scrollable, padding 16, gap 16; bottom bar like Add trip with DkButton «Вывести».
- Balance card = DkCard hero (radius xl, padding 20, gap 16): label «Доступно к выводу» → moneyHero accent amount; divider; 3-col DkSummaryTile grid: «Безнал» (Σ card), «Комиссия» (−Σ commission), «Выведено» (−Σ pending+paid).
  Helper under the card (caption textTertiary): «Наличные остаются у вас, поэтому комиссия за них тоже списывается с безнала.»
- Amount: DkTextField money «Сумма вывода», helper «Не больше 1 815 ₸». Trailing text button «Всё» (fills the available amount).
- History: DkListHeader «История» + DkTripTile-like rows in a DkCard: icon tile `wallet` / title amount bodyStrong / subtitle date «5 октября 2026, 14:20» caption / trailing DkStatusChip («В обработке» / «Выплачено» / «Отклонено»; rejected shows reason as second subtitle line).
- States:
  - loading: skeleton of balance card + 3 history rows;
  - empty history: small text «Заявок на вывод пока не было.» in the history card;
  - balance ≤ 0: amount field disabled, button disabled, info row (icon `info`, textSecondary) «Сейчас нечего выводить.»;
  - validation: «Сумма больше доступной», «Сумма должна быть больше 0»;
  - saving: button loading «Отправляем…»;
  - offline: error snackbar «Нет связи. Повторим запрос — деньги не уйдут дважды.» + «Повторить»;
  - success: back to the top, new row highlighted (accentSoft 2 s), success snackbar «Заявка на вывод создана»;
  - 409: DkDialog «Эта заявка уже отправлена с другой суммой», primary «Понятно» (refresh history).

### 8.5 Session ended
- Any 401 → Login with error snackbar «Сессия завершена. Войдите снова.»

### 8.6 Admin («Админка»)
- Day-screen layout reused. Header: wordmark + caption «Администратор» + DkIconButton menu (Menu without «Вывод средств»).
- Under the header: DkSegmentedControl with 3 segments: «Поездки» / «Выводы» / «Водители».
- Поездки: DkFilterChips «Все водители», «Водитель 1», «Водитель 2» (from /admin/users) → DkDaySwitcher → summary card + payment card + trip list for the selection. In «Все водители» each trip row's meta line is «22 мин · Карта · Водитель 1». No FAB (admin does not create trips).
- Выводы: DkFilterChips «В обработке», «Все»; list rows: driver name, amount, date, status chip; pending rows have two buttons under the row content: DkButton secondary «Отклонить» and primary «Выплатить» (each 48 high, side by side). Reject opens a dialog with a text field «Причина» (required). Approve → no dialog, button loading then row updates; success snackbar «Отмечено как выплачено».
- Водители: DkListGroup rows: display name, «@user_1», trailing balance moneyM; row tap → bottom sheet with actions: «Заблокировать» / «Разблокировать» (is_active), «Сбросить все сессии» (confirm dialog «Водитель выйдет на всех устройствах»).
- Empty / error / loading states reuse DkEmptyState, DkErrorState, DkSkeleton.

### 8.7 Copy additions (ru; kk goes to app_kk.arb)
login «Логин», password «Пароль», loginTitle «Вход», signIn «Войти», signingIn «Входим…», showPassword «Показать пароль», hidePassword «Скрыть пароль», errInvalidCredentials «Неверный логин или пароль», errRateLimited «Слишком много попыток. Попробуйте через 15 минут.», sessionEnded «Сессия завершена. Войдите снова.», menu «Меню», back «Назад», roleDriver «Водитель», roleAdmin «Администратор», withdraw «Вывод средств», available «Доступно {amount}», language «Язык», logout «Выйти», logoutTitle «Выйти из аккаунта?», logoutMessage «Чтобы снова увидеть поездки, нужно будет войти по логину и паролю.», cancel «Отмена», availableToWithdraw «Доступно к выводу», cardTotal «Безнал», withdrawn «Выведено», cashNote «Наличные остаются у вас, поэтому комиссия за них тоже списывается с безнала.», withdrawAmount «Сумма вывода», maxHint «Не больше {amount}», all «Всё», history «История», noWithdrawals «Заявок на вывод пока не было.», nothingToWithdraw «Сейчас нечего выводить.», errInsufficient «Сумма больше доступной», withdrawButton «Вывести», sending «Отправляем…», withdrawOffline «Нет связи. Повторим запрос — деньги не уйдут дважды.», withdrawCreated «Заявка на вывод создана», withdrawConflict «Эта заявка уже отправлена с другой суммой», ok «Понятно», statusPending «В обработке», statusPaid «Выплачено», statusRejected «Отклонено», admin «Админка», tabTrips «Поездки», tabWithdrawals «Выводы», tabDrivers «Водители», allDrivers «Все водители», approve «Выплатить», reject «Отклонить», rejectReason «Причина», markedPaid «Отмечено как выплачено», block «Заблокировать», unblock «Разблокировать», revokeSessions «Сбросить все сессии», revokeSessionsMessage «Водитель выйдет на всех устройствах».
```

