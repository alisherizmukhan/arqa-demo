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

Attribution in the app: «© OpenStreetMap contributors». With routes on the map, add «© openrouteservice.org by HeiGIT».

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
- Remaining quota is in the `x-ratelimit-remaining` / `x-ratelimit-reset` headers. **To do once the key is available:** read these headers on one real call per endpoint and record them here.

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
  - Stage 1 asks for `lang=ru` and checks what comes back. Where OSM has no Russian name, the label stays as OSM has it.

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

`ORS_API_KEY` (checked 2026-10-12, names only, the value never printed):
- **Local:** in `backend/.env`, which `.gitignore` ignores (`git check-ignore -v backend/.env` → `.gitignore:10:.env`). One reverse-geocode request from the developer machine returned `200`.
- **Railway** (`api`, production): added as a staged change, not yet applied, so the running service does not have it yet.

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
