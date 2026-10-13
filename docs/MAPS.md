# Maps: providers and choices (Almaty)

Stage 0 of `docs/prompts/PROMPT_MAPS.md`: what was checked on 2026-10-12 and what is used. No code yet.

## Summary

| Need | Choice | Key | Where it runs |
|---|---|---|---|
| Map widget | `flutter_map` 8.3.2 + `latlong2` 0.10.1 | none | app |
| Tiles (demo) | OpenStreetMap standard tiles for both themes; the URLs and attribution come from `--dart-define` | none | app → tile server |
| Routes | OpenRouteService directions, `driving-car` | `ORS_API_KEY` | backend only |
| Addresses | OpenRouteService geocode reverse + autocomplete, limited to the Almaty box | `ORS_API_KEY` | backend only |
| Polyline | own encoder (Python) and decoder (Dart), Google format, precision 5 | — | both |

No routing algorithm of our own: the routing engine builds the route.

## Map widget: flutter_map

Versions from the pub.dev API:
- **`flutter_map` 8.3.2** (2026-08-27). It needs Dart ≥ 3.6 and Flutter ≥ 3.27; we have Dart 3.13 and Flutter 3.47.6. It is pure Dart, runs on Android, iOS and web, and needs no native setup or key.
- **`latlong2` 0.10.1** (2026-04-27). flutter_map 8.3.2 accepts `>=0.9.1 <0.11.0`.

Checked in the 8.3.2 source:
- **Tile caching:** caching to disk is on by default (`BuiltInMapCachingProvider`, since 8.2). It honours the HTTP cache headers, as the OSM policy asks.
- **Cancellation:** tile requests that are no longer needed are cancelled (`abortObsoleteRequests`, on by default). The separate `flutter_map_cache` and `flutter_map_cancellable_tile_provider` plugins are therefore not needed.
- **User-Agent:** flutter_map sends `flutter_map (<userAgentPackageName>)` and warns when it is left at `unknown`. We pass `kz.driverdiary.driver_diary`.
- **Dark variant:** `darkModeTileBuilder` is included (an inverting colour filter).
- **Rotation** can be switched off with `InteractionOptions`. A fit-to-bounds with padding is available as `CameraFit.bounds`.

## Tiles

The tile URLs and the attribution are build-time config, never literals in widgets:
- `TILE_URL_LIGHT`
- `TILE_URL_DARK`
- `TILE_ATTRIBUTION`

**Demo default: OpenStreetMap standard tiles (`https://tile.openstreetmap.org/{z}/{x}/{y}.png`) for both themes.**

Why not a free style with its own dark variant:
- **CARTO** (`light_all` / `dark_all`) is the usual free pair. Since its terms of **29 September 2026** every tile URL needs `?key=…`; without a key the tiles get an «API key required» watermark.
  - The key is free. Business use is free up to 1 M requests a month and non-commercial use up to 5 M; above that it is paid ($500/month for 10 M).
  - It needs a registration and a key in the app. It is the ready swap: two `--dart-define`s, no code change.
- **Stadia Maps** (Alidade Smooth / Dark): the free plan is 200 000 credits a month (1 tile = 1 credit), commercial use is not allowed, and apps need a key.
- **The app ships with the light theme only** (`ThemeMode.light`, DECISIONS «Post-redesign UI fixes»), but the map must still work in the dark theme (dark goldens, and a dark mode later).

**Dark theme: the same OSM tiles, darkened in the app.**
- In the dark theme the tile layer gets `tileBuilder: darkModeTileBuilder` (flutter_map's inverting colour filter), or an equivalent `ColorFilter`, so the map is not a bright white block next to dark cards. `TILE_URL_DARK` defaults to the same OSM URL; when a real dark style is configured (CARTO `dark_all` with a key), the filter is switched off for it.
- Only the tiles are filtered. The route line, the markers and the attribution are drawn in layers above the tile layer, so the filter never touches them, and they take their colours from the theme tokens.
- Readability on both themes is checked in stage 2: the route line and the markers against light and darkened tiles, and the attribution on its own surface chip (theme surface colour, ≥ 4.5:1 text contrast), in light and dark goldens.

OSM tile usage policy (operations.osmfoundation.org/policies/tiles):
- Send a stable, app-specific User-Agent.
- Keep the attribution visible on the map, not behind a button.
- Honour the cache headers, or cache for at least 7 days.
- No bulk download or prefetch of tiles the user is not looking at, and no offline packs.
- Best effort with no SLA; access can be blocked without notice. Commercial services are warned that access «may be withdrawn at any point».

**Production needs its own or a paid tile provider:**
- CARTO commercial;
- 2GIS;
- or self-hosted tiles: vector tiles from an OSM extract of Kazakhstan.

### Attribution (stage 3, checked 2026-10-13)

What the map shows, always, on one line (11 px, bottom right):
- «© OpenStreetMap»;
- plus « · © openrouteservice.org by HeiGIT» while a route that ORS built is drawn (not for a straight-line fallback, not in the picker). This is ORS's requested wording (decided after stage 3); the chip scales a long credit down rather than wrapping, so it stays one line at 360 dp and text ×1.3 (tested).

Tapping it opens «Данные карты» with the full credits and links, as selectable text (the app has no link opener):
- «Map data © OpenStreetMap contributors, available under the Open Database License (ODbL): https://www.openstreetmap.org/copyright»;
- «Map tiles: OpenStreetMap, https://www.openstreetmap.org — tile usage policy: https://operations.osmfoundation.org/policies/tiles/»;
- «Routes and addresses: © openrouteservice.org by HeiGIT | Map data © OpenStreetMap contributors — https://openrouteservice.org».

Why this meets the terms:
- **OSM** (OSMF Attribution Guidelines, osmfoundation.org/wiki/Licence/Attribution_Guidelines):
  - «Attribution must be to OpenStreetMap»; «© OpenStreetMap contributors» and «© OpenStreetMap» are both accepted forms.
  - On a browsable map, the credit goes in a corner of the map and must be legible: 11 px textSecondary on a 90 % surface chip, contrast ≥ 4.5:1 in both themes.
  - There must be a way to reach the licence information when the credit itself does not carry it, e.g. a link. Here that is the tap-to-open credits with the ODbL link.
- **ORS** asks for «© openrouteservice.org by HeiGIT | Map data © OpenStreetMap contributors» (openrouteservice.org terms; the HeiGIT account page uses «© openrouteservice by HeiGIT | Data from OpenStreetMap»). Its results are licensed CC-BY 4.0 (openrouteservice.org) or CC-BY-SA 4.0 (HeiGIT). Both licences accept credit «in any reasonable manner based on the medium», including through a link.
  - The map carries ORS's requested wording «© openrouteservice.org by HeiGIT»; the OSM part of their string («Map data © OpenStreetMap contributors») is covered by the «© OpenStreetMap» credit next to it and the full line in the credits sheet.
- **Addresses** from ORS geocoding (labels typed into trips) are not separately credited on every screen; the credits sheet covers them.

## Routing and geocoding: OpenRouteService (backend only)

Endpoints:
- `POST /v2/directions/driving-car` — the route, distance (m) and duration (s). The geometry is a Google encoded polyline with precision 5 (1e5). With elevation it gets a third value and a standard decoder breaks, so we never ask for elevation.
- `GET /geocode/reverse` — the address of a point.
- `GET /geocode/autocomplete` — address search, limited to a rectangle with `boundary.rect.*`.

**Standard plan (free) quotas**, verified from the plan definitions served by HeiGIT's account dashboard (`account.heigit.org`, plan «Standard»):

| Endpoint | Per day | Per minute |
|---|---|---|
| Directions v2 | 2 000 | 40 |
| Geocode autocomplete | 1 000 | 100 |
| Geocode reverse | 1 000 | 100 |
| Geocode search | 1 000 | 100 |

The ORS FAQ gives the same directions numbers.
- The daily window starts with the first request and lasts 24 h.
- Over the daily limit the API returns `403`; over the per-minute limit, `429`.
- Remaining quota is in the `x-ratelimit-remaining` / `x-ratelimit-reset` headers. What they really contain: see «Stage 1» below.

What the quotas mean for us:
- **Routes:** a route is built once per trip and stored. 2 000 a day is far more than a demo needs, and a failed or over-quota call gives a `straight` route, never a failed trip.
- **Geocoding:** results are cached for 24 h, by rounded coordinates for reverse and by the query text for search. The pin's reverse geocode is debounced by 500 ms and the search by 400 ms (3 characters minimum). With 1 000 calls a day each, these are the quotas to watch.
- **Rate limit:** our own per-user limit on `/geo/*` keeps one user from using up the shared daily quota.

Terms:
- **Attribution:** «© openrouteservice.org by HeiGIT | Map data © OpenStreetMap contributors».
- **License of results:** ORS results are under CC-BY 4.0 according to openrouteservice.org, and CC-BY-SA 4.0 according to the newer HeiGIT account terms. Either way, storing routes with attribution is allowed.
- **Commercial use:** the Standard plan is «free for everyone»; HeiGIT asks commercial users to contact them for larger quotas.

### Checks before stage 1

- **Seed points against OSM** (Nominatim, one lookup per place):

  | Seed point | Distance from the OSM object |
  |---|---|
  | Зелёный базар | 151 m |
  | Есентай Молл | 132 m |
  | Площадь Республики | 98 m |
  | MEGA Alma-Ata | 26 m |
  | Аэропорт Алматы | 433 m (from the centre of the airport area, a large polygon) |

  All of them are inside the Almaty box 43.05..43.45 N, 76.70..77.20 E. Stage 1 checks them again through `/geo/search` and uses the address ORS returns.
- **Language of labels:**
  - OSM names in Almaty are often in Kazakh: Nominatim gave «Көк Базар», «Республика алаңы».
  - The prompt wants Russian labels («Зелёный базар»). ORS geocoding (Pelias) takes a `lang` parameter.
  - Checked in stage 1: see «Does `lang=ru` work?» below.

## Polyline

Same algorithm on both sides, with tests on Google's reference example (`_p~iF~ps|U_ulLnnqC_mqNvxq`@`):
- **Backend:** a ~20-line encoder for the straight-line fallback. The routes from ORS already come encoded.
- **App:** a ~25-line decoder in the domain layer.

No package, and why:
- `google_polyline_algorithm` (Dart) was last published in 2021 and needs Dart < 3.
- `flutter_polyline_points` 3.1.0 is built around Google Directions and brings `http` with it.
- Python `polyline` 2.0.4 would do, but is not worth a dependency for one function.

## Alternatives considered (why not now)

- **Google Maps:** needs a billing account and a key in the app, and the native SDK has no web map in the same widget. Routes and Places are paid per request after the free usage.
- **Mapbox / MapLibre:**
  - Mapbox needs an access token and native SDK setup.
  - MapLibre itself is free, but still needs a style and tile host, and native setup on mobile.
  - flutter_map gives us the same raster map in pure Dart.
- **2GIS:** the best data for Almaty, including entrances and house numbers.
  - The official Flutter SDK (`dgis_mobile_sdk_full` / `_map`) is native.
  - It needs a paid subscription and a `dgissdk.key` file, and has no Flutter web (web is the separate MapGL JS API).
  - **Candidate for production in Kazakhstan.**
- **Self-hosted OSRM + Nominatim on a Kazakhstan extract:** free, with no quotas and our own data.
  - It needs a few GB of RAM and disk and periodic re-imports: too heavy for the Railway demo.
  - **Production option.**
- **Public OSRM demo server:** «restricted to reasonable, non-commercial use-cases», at most 1 request a second, with no guarantees. Not for an app.

## ORS key

`ORS_API_KEY`: names checked only, the value is never printed.
- **Local:** in `backend/.env`, which git ignores (`.gitignore:10:.env`). The tests blank the variable (`tests/conftest.py`), so they never use it; only the `live` test reads it from the file.
- **Railway** (`api`, production): set and deployed on 2026-10-12 (DEPLOY_CHECK «Maps — ORS_API_KEY»). `.railway/railway.ts` keeps it with `preserve()`.
- Without a key the API still works: routes become straight lines, `/geo/*` answers 503 `maps_unavailable`.

## Stage 1: what ORS really returns (2026-10-12)

Checked with the key, about 25 requests in all.

**Quota headers.**
- Every answer carries `X-Ratelimit-Limit`, `X-Ratelimit-Remaining` and `X-Ratelimit-Reset` (a unix time).
- Geocoding: limit **100**, remaining going down by one per call. Directions: limit **200**.
- The reset time does not match the documented windows: about 24 h ahead on geocoding, 2 s ahead on directions.
- So the headers are not used. The documented quotas above stay the reference, and any `403` / `429` is simply «unavailable»: a straight line for routes, 503 for lookups.

**Directions.**
- Зелёный базар → Есентай Молл: **7.2 km, 12 min**, a 365-character polyline.
- Points inside large areas (the market, the airport) need a snap radius: we send `radiuses: [1000, 1000]`, ORS's default is 350 m.

**Russian labels (`lang=ru`).**
- Russian when OSM has a Russian name: «Площадь Республики», «Зеленый базар», «Международный аэропорт Алматы», «улица Розыбакиева».
- Otherwise the name OSM has: «Esentai Mall», «MEGA Alma-Ata», «Almaty International Airport» (the terminal node), «Rozybakiev Street» (one street segment).
- ORS's own `label` always ends in «, AC, Казахстан». We build the label ourselves: the place name, or «street, house», or the street.

**Does `lang=ru` work?** Yes, ORS accepts it. Its answer echoes `lang: Russian, via: querystring, defaulted: false`; without the parameter it is `English, defaulted: true`. What it changes:

| Request | Without `lang` | With `lang=ru` |
|---|---|---|
| search «Достык» | «Достық», «Достық даңғылы» (Kazakh) | «Достык», «Достык плаза» |
| search «аэропорт» | «Аэропорт», «Кольцо Аэропорт» | «Международный аэропорт Алматы» first |
| search «Абая» | the same 4 places | the same |
| search «Abay» (Latin) | «Абая», «Театр оперы и балета им. Абая» | «Abay», «Abay Avenue (West)» — English |
| reverse at 3 points | the same names | the same names |

- Where OSM has no Russian name, ORS falls back to the default name by itself («Almaty International Airport»), so no fallback code is needed.
- **So:** reverse always sends `lang=ru`; search sends it only when the text contains Cyrillic, because for a Latin query it gives English names and the default gives Russian ones.

**Reverse geocoding picks the address first.**
- The nearest objects are often shops inside a mall («Dolce & Gabbana» at Esentai, «Бургер Кинг» at the market).
- So the label is the nearest house address within 75 m («площадь Республики, 2»). If there is none, it is the nearest named place («Almaty International Airport»), then the street.

**Seed points against `/geo/search`.**

Coordinates more than 100 m from the OSM object were corrected. The seed labels are explicit Russian names stored in `data/trips.json` («Зелёный базар», «ТРЦ Есентай Молл», «Площадь Республики», «Аэропорт Алматы», «ТРЦ MEGA Alma-Ata»), never what reverse geocoding returns.

| Seed point | Prompt | `/geo/search` | Gap | Used |
|---|---|---|---|---|
| Зелёный базар | 43.2627, 76.9539 | «Зелёный базар» 43.26275, 76.95519 | 105 m | **43.26275, 76.95519** |
| Есентай Молл | 43.2185, 76.9280 | «Esentai Mall» 43.21847, 76.92745 | 45 m | **43.2189, 76.9279** (after the day-map review: see below) |
| Площадь Республики | 43.2380, 76.9455 | 43.23863, 76.94536 | 71 m | prompt |
| Аэропорт Алматы | 43.3521, 77.0405 | area centre 43.35896, 77.02110 (1.7 km); reverse: the terminal «Almaty International Airport», 3 m | — | prompt (the terminal) |
| MEGA Alma-Ata | 43.2016, 76.8920 | 43.20243, 76.89317 | 132 m | **43.2026, 76.8946** (after the day-map review: see below) |

The seed trips with places (times and money as before). The routes were built on the developer database; user_2's routes are built the same way on the next start.

| Trip | Driver, time | Route | Distance | Time |
|---|---|---|---|---|
| t1 | user_1, 1 Oct 08:10 | Зелёный базар → ТРЦ Есентай Молл | 7 496 m | 788 s |
| t2 | user_1, 1 Oct 09:05 | ТРЦ Есентай Молл → Площадь Республики | 4 918 m | 550 s |
| t3 | user_1, 30 Sep 18:40 | Площадь Республики → Аэропорт Алматы | 25 641 m | 2 867 s |
| t4 | user_1, 30 Sep 23:50 (crosses midnight) | ТРЦ MEGA Alma-Ata → Зелёный базар | 12 200 m | 1 042 s |
| u2-t1 | user_2, 1 Oct 10:00 | Площадь Республики → Аэропорт Алматы | 25 641 m | 2 867 s |
| u2-t2 | user_2, 1 Oct 12:15 | ТРЦ MEGA Alma-Ata → ТРЦ Есентай Молл | 4 660 m | 423 s |

**Snapped route ends (after the day-map review, 13 Oct 2026).** ORS snaps a place to the nearest road; how far each seed route's line ends from its place points (developer database, live ORS):

| Trip | Route | Start gap | End gap | Detours left (real turnarounds) |
|---|---|---|---|---|
| t1 | Зелёный базар → ТРЦ Есентай Молл | 6 m | 40 m | — |
| t2 | ТРЦ Есентай Молл → Площадь Республики | 40 m | 25 m | parking-loop U-turn at 2.5 km (156 m) |
| t3 | Площадь Республики → Аэропорт Алматы | 25 m | 67 m | U-turn at 8 km (396 m) |
| t4 | ТРЦ MEGA Alma-Ata → Зелёный базар | 9 m | 6 m | — |
| u2-t1 | Площадь Республики → Аэропорт Алматы | 25 m | 67 m | as t3 |
| u2-t2 | ТРЦ MEGA Alma-Ata → ТРЦ Есентай Молл | 9 m | 40 m | U-turn at 1.3 km (272 m) |

- Gaps over 30 m get a dashed connector from the place (DESIGN.md §9.1).
- t1 ends and t2 starts at the same snapped point (43.21914, 76.92754), so both lines meet; the «2» marker sits on the place point 40 m away.
- Moved: Есентай (t2 began with a 987 m loop) and MEGA (t4 began with a U-turn); see DECISIONS.

## Sources

- flutter_map: pub.dev API, `CHANGELOG.md` and the 8.3.2 source (`tile_layer.dart`, `built_in_caching_provider.dart`).
- OSM tile usage policy: https://operations.osmfoundation.org/policies/tiles/
- CARTO basemaps keys and terms (29 September 2026): https://www.carto.com/basemaps/apikey/
- Stadia Maps pricing: https://stadiamaps.com/pricing/
- ORS FAQ (limits, headers, 403/429): https://giscience.github.io/openrouteservice/frequently-asked-questions.html
- ORS plans: https://account.heigit.org/info/plans (plan definitions read from the page's own scripts)
- ORS geometry decoding: https://giscience.github.io/openrouteservice/api-reference/endpoints/directions/geometry-decoding
- ORS terms: https://openrouteservice.org/terms-of-service/ and https://account.heigit.org/info/tos
- OSRM demo server: https://github.com/Project-OSRM/osrm-backend/wiki/Demo-server
- 2GIS Flutter SDK: https://docs.2gis.com/en/flutter/sdk/overview
