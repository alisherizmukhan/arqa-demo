import 'package:driver_diary/core/time/driver_zone.dart';

/// Build-time configuration:
///
///     flutter run --dart-define=API_URL=http://10.0.2.2:8000 \
///                 --dart-define=DRIVER_TZ=+05:00
///
/// Map tiles (DESIGN.md §9, docs/MAPS.md): `TILE_URL_LIGHT`,
/// `TILE_URL_DARK` (empty: the light tiles, darkened in the dark theme) and
/// `TILE_ATTRIBUTION`; by default OpenStreetMap's standard tiles.
final class AppConfig {
  const new({
    required this.apiUrl,
    required this.driverZone,
    this.tileUrlLight = defaultTileUrl,
    this.tileUrlDark,
    this.tileAttribution = defaultTileAttribution,
  });

  factory fromEnvironment() => AppConfig(
    apiUrl: const String.fromEnvironment(
      'API_URL',
      defaultValue: defaultApiUrl,
    ),
    driverZone: zoneFrom(const String.fromEnvironment('DRIVER_TZ')),
    tileUrlLight: _or(
      const String.fromEnvironment('TILE_URL_LIGHT'),
      defaultTileUrl,
    ),
    tileUrlDark: _orNull(const String.fromEnvironment('TILE_URL_DARK')),
    tileAttribution: _or(
      const String.fromEnvironment('TILE_ATTRIBUTION'),
      defaultTileAttribution,
    ),
  );

  /// An empty define means «not given».
  static String _or(String define, String fallback) =>
      define.isEmpty ? fallback : define;

  static String? _orNull(String define) => define.isEmpty ? null : define;

  /// OpenStreetMap's standard tiles: fine for a demo, not for production
  /// (OSM tile usage policy, docs/MAPS.md).
  static const defaultTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// The OSM credit in its short accepted form (OSMF attribution
  /// guidelines); the full credits open from the map.
  static const defaultTileAttribution = '© OpenStreetMap';

  /// Sent in the tile requests' User-Agent (OSM tile policy): the app id.
  static const userAgentPackageName = 'kz.driverdiary.driver_diary';

  /// The `DRIVER_TZ` define, or [DriverZone.kazakhstan] (the one named
  /// default, +05:00) when it is not given.
  static DriverZone zoneFrom(String define) =>
      define.isEmpty ? DriverZone.kazakhstan : DriverZone.parse(define);

  /// The app version shown in the menu; equals `version` in pubspec.yaml
  /// (a test checks).
  static const version = '0.2.1';

  /// The deployed API on Railway.
  static const defaultApiUrl = 'https://api-production-6e8b.up.railway.app';

  final String apiUrl;

  /// The driver's UTC offset; day boundaries and times are shown in it.
  final DriverZone driverZone;

  /// `{z}/{x}/{y}` template of the light map style.
  final String tileUrlLight;

  /// A dark style; null: [tileUrlLight], darkened in the dark theme.
  final String? tileUrlDark;

  /// The tiles' credit, always on the map.
  final String tileAttribution;
}
