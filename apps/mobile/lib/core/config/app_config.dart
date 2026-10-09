import 'package:driver_diary/core/time/driver_zone.dart';

/// Build-time configuration:
///
///     flutter run --dart-define=API_URL=http://10.0.2.2:8000 \
///                 --dart-define=DRIVER_TZ=+05:00
final class AppConfig {
  const new({required this.apiUrl, required this.driverZone});

  factory fromEnvironment() => AppConfig(
    apiUrl: const String.fromEnvironment(
      'API_URL',
      defaultValue: defaultApiUrl,
    ),
    driverZone: zoneFrom(const String.fromEnvironment('DRIVER_TZ')),
  );

  /// The `DRIVER_TZ` define, or [DriverZone.kazakhstan] (the one named
  /// default, +05:00) when it is not given.
  static DriverZone zoneFrom(String define) =>
      define.isEmpty ? DriverZone.kazakhstan : DriverZone.parse(define);

  /// The app version shown in the menu; equals `version` in pubspec.yaml
  /// (a test checks).
  static const version = '0.2.0';

  /// The deployed API on Railway.
  static const defaultApiUrl = 'https://api-production-6e8b.up.railway.app';

  final String apiUrl;

  /// The driver's UTC offset; day boundaries and times are shown in it.
  final DriverZone driverZone;
}
