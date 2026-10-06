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
    driverZone: DriverZone.parse(
      const String.fromEnvironment('DRIVER_TZ', defaultValue: '+05:00'),
    ),
  );

  /// The deployed API on Railway.
  static const defaultApiUrl = 'https://api-production-6e8b.up.railway.app';

  final String apiUrl;

  /// The driver's UTC offset; day boundaries and times are shown in it.
  final DriverZone driverZone;
}
