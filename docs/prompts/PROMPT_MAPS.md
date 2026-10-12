# Промпт: карта и маршруты поездок (Алматы)

Запускать **после** промпта на стабильность интерфейса (`PROMPT_UI_STABILITY.md`). Работа идёт в `main`, как в прошлой итерации.
Перед запуском: зарегистрируйтесь на openrouteservice.org (бесплатно), создайте API-ключ и добавьте его переменной `ORS_API_KEY`
в сервис бэкенда на Railway (и в локальный `.env`, который не коммитится).

```
Next iteration: trip locations and route maps (Almaty). Work on main (rules from DECISIONS.md «Branches and deploys»: every commit green, run tool/ci_local.sh before pushing, prod deploys only after my ok, backup before any prod data change, test rows on prod deleted only after my "delete"). All new screens must follow the UI stability rules (DESIGN.md §10). Stages; stop after each with screenshots / command output and wait for my "ok". Decisions → docs/DECISIONS.md, AI mistakes → docs/AI_NOTES.md. All existing rules stay (integer money, +05:00 day boundaries, idempotency, roles, design_kit only, l10n ru/kk, zero warnings).

Goal: when adding a trip the driver may set where it started (A) and ended (B) on a map. The server builds the road route once and stores it. The driver (and admin) can open a past trip and see its route on a map with distance and duration.

────────────────────────────────────────
0. Research check (no code): confirm current versions/limits and write docs/MAPS.md with the final choice:
- Map widget: flutter_map (pure Dart, Android/iOS/web, no native keys) + latlong2.
- Tiles: a provider configurable by --dart-define (TILE_URL_LIGHT, TILE_URL_DARK, TILE_ATTRIBUTION). Default for the demo: a free raster style with a light and a dark variant; if no suitable free dark style, use OpenStreetMap standard tiles for both with proper userAgentPackageName, attribution and caching, and note in MAPS.md that production needs a paid/own tile provider (OSM tile usage policy).
- Routing + geocoding: OpenRouteService (driving-car directions, reverse geocode, autocomplete restricted to Almaty) called ONLY from the backend with ORS_API_KEY. Record the free-plan quotas you verified.
- Alternatives considered (one line each, why not now): Google Maps (billing, key in app), Mapbox/MapLibre (key, native setup), 2GIS SDK (best Almaty data, paid keys, native SDK, no web — candidate for production in KZ), self-hosted OSRM + Nominatim on Kazakhstan extract (free, no quotas, but heavy for Railway — production option), public OSRM demo server (not allowed for apps).
No custom routing algorithm — the routing engine does it.

────────────────────────────────────────
1. Backend
Migration (all new columns nullable — old trips have no locations):
- trips: pickup_lat, pickup_lng, dropoff_lat, dropoff_lng DOUBLE PRECISION; pickup_label, dropoff_label TEXT;
  route_polyline TEXT (Google encoded polyline, precision 5), route_distance_m INT, route_duration_s INT,
  route_status TEXT CHECK IN ('none','pending','ready','straight','failed') DEFAULT 'none'.
Validation (422, same error shape, codes added to l10n):
- either both A and B or neither; lat/lng in the Almaty bounding box 43.05..43.45 N, 76.70..77.20 E (config, not literals); A ≠ B (distance > 50 m); labels ≤ 200 chars.
Idempotency: A/B coordinates and labels are part of the compared payload; route fields are server-derived and NOT compared.
Routing service (infrastructure, behind an application-layer protocol so tests use a fake):
- On create with A and B: call ORS directions (driving-car), store polyline, distance, duration, status ready. Timeout 5 s.
- If ORS fails or quota is exceeded: the trip is still created (201); status 'straight' with a straight-line polyline and haversine distance; a retry endpoint POST /trips/{id}/route (owner or admin) recomputes later. Never block trip creation on routing.
- Distance/duration are integers.
Geocoding endpoints (auth required, rate-limited per user, results cached in DB/memory for 24 h by rounded coords/query):
- GET /geo/reverse?lat=&lng= → {label} (Russian; street + house or POI name, without city/country).
- GET /geo/search?q= → up to 5 {label, lat, lng} inside the Almaty box, for autocomplete (min 3 chars).
Trip responses include the new fields. GET /trips/{id} returns one trip (owner or admin).
Seed: add locations to seed trips (verify the coordinates with /geo/search, fix if off):
- t1 08:10–08:32 card: Зелёный базар (≈43.2627, 76.9539) → ТРЦ Есентай Молл (≈43.2185, 76.9280)
- t2 09:05–09:20 cash: ТРЦ Есентай Молл → Площадь Республики (≈43.2380, 76.9455)
- t3 10:00–10:40 card: Площадь Республики → Аэропорт Алматы (≈43.3521, 77.0405)
- t4 12:15–12:35 cash: ТРЦ MEGA Alma-Ata (≈43.2016, 76.8920) → Зелёный базар
Seed routes are computed via the routing service on first start (status pending → ready), not hardcoded.
Tests: validation; idempotency with coordinates; route stored on success; fallback 'straight' on ORS failure/timeout (fake); retry endpoint; roles (driver can't read others' trip by id → 404); geocode caching; no real network in unit tests (one optional live test tagged `live`).

────────────────────────────────────────
2. Design addendum → DESIGN.md §9 (show showcase screenshots in ru and kk, light + dark, on a review page before wiring; wait for "ok")
Tokens: add DkColors routeLine (light = accent #2450D8, dark = accent #7B9BFF), routeCasing (light #FFFFFF, dark #0B0D10), markerA (= textPrimary), markerB (= accent). Map tiles follow the theme (light/dark style).
New components:
- DkMapView: wraps flutter_map; radius lg, clip; attribution always visible (small, bottom-right); disables rotation; fit-to-bounds with padding 48.
- DkRouteLayer: polyline 5 dp in routeLine over a 8 dp routeCasing; dashed (6/6) when route_status = straight.
- DkPlaceMarker: 32 dp circle, white 2 dp ring, letter «A»/«B» 13/800; A = markerA, B = markerB. Semantics «Начало поездки» / «Конец поездки».
- DkPlaceField: row like DkListRow (min 56): leading DkPlaceMarker (A/B), label «Откуда» / «Куда» caption above the address (bodyStrong) or placeholder «Выбрать на карте» (textTertiary); trailing chevron; clear button 48 when set.
- DkRouteStats: three DkSummaryTiles «Расстояние» («7,4 км»), «В пути» («22 мин»), «За км» («324 ₸»; amount / km, integer, rounded).
Screens:
- Add trip: after the time row, a DkListGroup with two DkPlaceFields (Откуда / Куда). Optional. Tapping opens the Place picker.
- Place picker (full-screen route): DkMapView full screen, fixed center pin (DkPlaceMarker A or B), search field on top (DkTextField with search icon, autocomplete list under it, debounce 400 ms, min 3 chars), address of the center shown in a bottom card (updates after the map stops, reverse geocode debounce 500 ms; «Определяем адрес…» while loading; «Адрес не найден» → still allowed, label = coordinates «43.2380, 76.9455»), DkButton «Выбрать это место». Start view: Almaty center 43.2389, 76.8897, zoom 12; if A is set, B starts at A. No GPS / location permission in this iteration.
- Trip tile: now tappable when the trip has locations (trailing chevron 20 textTertiary; trips without locations stay non-tappable). Second meta line under time: «Зелёный базар → Есентай Молл» (caption, ellipsis).
- Trip details (new pushed screen): top DkMapView height 45% of the screen with route + A/B markers, fit to bounds; below: time range titleM, «22 мин · Карта», amount moneyM + «комиссия 360 ₸», DkRouteStats, two DkPlaceFields read-only (no chevron). Status 'straight': info row «Маршрут построен по прямой — сервис карт был недоступен» + text button «Построить заново» (calls POST /trips/{id}/route). Loading / error states with existing kit components. Map tiles failing to load must not break the screen (grey background + attribution).
- Day screen: a DkIconButton «Карта дня» in the trips list header opens a Day map: all routes of the day on one map, each with A/B markers; tapping a route opens its Trip details. Admin sees the selected driver filter.
Copy (ru; add kk): «Откуда», «Куда», «Выбрать на карте», «Выбрать это место», «Определяем адрес…», «Адрес не найден», «Поиск адреса», «Расстояние», «В пути», «За км», «Маршрут», «Карта дня», «Маршрут построен по прямой — сервис карт был недоступен», «Построить заново», «Начало поездки», «Конец поездки», errors: «Укажите и начало, и конец поездки», «Точка вне Алматы», «Начало и конец совпадают».
Formatting: distance < 1000 m → «850 м», else «7,4 км» (comma, one decimal); ₸ per km as integer with U+202F.

────────────────────────────────────────
3. Mobile
- Polyline decoding in the domain layer (pure Dart, own small decoder or a maintained package), with tests (known encoded string → coordinates).
- Map tile URLs only from config (--dart-define), never literals in widgets; attribution string from config.
- Offline: the add-trip form with A/B still uses the same-id resend; place picker shows a clear offline state («Нет связи — карта не загрузилась») and still allows confirming the center coordinates without a label.
- Tests: place field states, picker debounce (fake geocoder), route rendering (golden with fake tiles — no network in tests), trip details for ready / straight / no-location trips, day map with 2 routes, roles.
- Layout checks (360/390 dp, text scale 1.0/1.3, ru/kk) for all new screens.

────────────────────────────────────────
4. Deploy + verify (docs/DEPLOY_CHECK.md): ORS_API_KEY set on Railway (names only, never print values); migration applied; seed routes ready; create a trip with A/B on the deployed API → 201 with route_status ready and distance; same request again → 200; ORS key temporarily invalid → trip still 201 with 'straight' (do this locally, not in prod). README: maps section (providers, quotas, attribution, how to swap the tile provider, production options: 2GIS / self-hosted OSRM), screenshots: picker, trip details light + dark, day map.

Constraints: small Conventional Commits; never commit keys; analyzers and all tests green. Release: new APK as GitHub release v2.1.0 and tag v2.1 after the deployed verification.
```
