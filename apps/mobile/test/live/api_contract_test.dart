// Contract test: the real client stack (dio + retry + DTOs + repository)
// against a running backend. Skipped unless LIVE_API_URL is set:
//
//   LIVE_API_URL=http://127.0.0.1:8000 flutter test test/live
//
// With LIVE_LOGIN / LIVE_PASSWORD it signs in first (needed when the backend
// has AUTH_REQUIRED=true). It creates trips on 2026-10-10, so point it at a
// local/dev backend.
@Tags(['live'])
library;

import 'dart:io';

import 'package:driver_diary/core/config/app_config.dart';
import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/network/auth_interceptor.dart';
import 'package:driver_diary/core/network/dio_client.dart';
import 'package:driver_diary/core/time/calendar_day.dart';
import 'package:driver_diary/core/time/driver_zone.dart';
import 'package:driver_diary/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:driver_diary/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:driver_diary/features/trips/data/datasources/trips_remote_data_source.dart';
import 'package:driver_diary/features/trips/data/repositories/trips_repository_impl.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

void main() {
  final apiUrl = Platform.environment['LIVE_API_URL'];
  const zone = DriverZone.kazakhstan;
  final day = CalendarDay(2026, 10, 10);

  final login = Platform.environment['LIVE_LOGIN'];
  final password = Platform.environment['LIVE_PASSWORD'] ?? '';

  late TripsRepositoryImpl repository;
  setUp(() async {
    final gate = AuthGate();
    final dio = createDio(
      AppConfig(apiUrl: apiUrl ?? '', driverZone: zone),
      gate,
    );
    repository = TripsRepositoryImpl(TripsRemoteDataSource(dio));
    if (apiUrl != null && login != null) {
      final auth = AuthRepositoryImpl(AuthRemoteDataSource(dio));
      final session = await auth.login(login, password);
      gate.token = switch (session) {
        Ok(:final value) => value.token,
        Err(:final failure) => fail('login failed: $failure'),
      };
    }
  });

  Trip newTrip({int amount = 2500}) => Trip(
    id: const Uuid().v4(),
    start: zone.instantAt(day, 23, 50),
    end: zone.instantAt(day.addDays(1), 0, 15),
    amount: amount,
    payment: PaymentMethod.cash,
    commission: 375,
  );

  test(
    'create, idempotent retry, conflict, and listing by local day',
    () async {
      final trip = newTrip();

      final created = await repository.createTrip(trip, zone);
      final retried = await repository.createTrip(trip, zone);
      final conflict = await repository.createTrip(
        newTrip(amount: 9999).withId(trip.id),
        zone,
      );
      final listed = await repository.tripsForDay(day, zone);
      final nextDay = await repository.tripsForDay(day.addDays(1), zone);

      expect((created as Ok<Trip>).value, trip);
      expect((retried as Ok<Trip>).value, trip);
      expect((conflict as Err).failure, isA<ConflictFailure>());
      // Crosses midnight: listed on its start day only.
      expect((listed as Ok<List<Trip>>).value, contains(trip));
      expect((nextDay as Ok<List<Trip>>).value, isNot(contains(trip)));
    },
    skip: apiUrl == null ? 'set LIVE_API_URL to run' : null,
  );

  test('server-side validation comes back as a ValidationFailure', () async {
    // Bypasses client-side rules on purpose by calling the repository.
    final invalid = newTrip(amount: 100);

    final result = await repository.createTrip(invalid, zone);

    expect(
      (result as Err).failure,
      isA<ValidationFailure>()
          .having((f) => f.code, 'code', 'commission_exceeds_amount')
          .having((f) => f.field, 'field', 'commission'),
    );
  }, skip: apiUrl == null ? 'set LIVE_API_URL to run' : null);
}
