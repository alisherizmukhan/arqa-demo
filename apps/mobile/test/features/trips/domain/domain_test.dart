import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/features/trips/domain/entities/daily_summary.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/domain/entities/trip_rules.dart';
import 'package:driver_diary/features/trips/domain/usecases/create_trip.dart';
import 'package:driver_diary/features/trips/domain/usecases/get_day_trips.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fixtures.dart';

void main() {
  setUpAll(registerFallbacks);

  group('calculateDailySummary', () {
    test('reference case 2026-10-01', () {
      expect(
        calculateDailySummary(referenceDay, [t1, t2], kz),
        DailySummary(
          day: referenceDay,
          tripsCount: 2,
          revenue: 3900,
          commission: 585,
          net: 3315,
          cash: 1500,
          card: 2400,
        ),
      );
    });

    test('empty day is all zeros', () {
      final summary = calculateDailySummary(referenceDay, const [], kz);
      expect(
        [summary.tripsCount, summary.revenue, summary.net, summary.cash],
        [0, 0, 0, 0],
      );
    });

    test('a trip crossing midnight counts fully on its start day', () {
      final late = trip(
        start: at(23, 50),
        duration: const Duration(minutes: 30),
        amount: 3200,
        commission: 480,
        payment: PaymentMethod.cash,
      );

      final summary = calculateDailySummary(referenceDay, [late], kz);

      expect(
        (summary.tripsCount, summary.revenue, summary.cash),
        (1, 3200, 3200),
      );
    });

    test('00:00 belongs to the day, 23:59 too; the next 00:00 does not', () {
      final first = trip(id: 'a', start: at(0, 0));
      final last = trip(id: 'b', start: at(23, 59));
      expect(
        calculateDailySummary(referenceDay, [first, last], kz).tripsCount,
        2,
      );
      expect(
        () => calculateDailySummary(referenceDay, [
          trip(start: at(0, 0, day: 2)),
        ], kz),
        throwsArgumentError,
      );
    });

    test('invariants hold for a mixed day', () {
      final trips = [
        for (var i = 0; i < 20; i++)
          trip(
            id: 't$i',
            start: at(8 + i ~/ 3, (i * 17) % 60),
            amount: 900 + i * 137,
            commission: (900 + i * 137) * 15 ~/ 100,
            payment: i.isEven ? PaymentMethod.cash : PaymentMethod.card,
          ),
      ];

      final s = calculateDailySummary(referenceDay, trips, kz);

      expect(s.net, s.revenue - s.commission);
      expect(s.cash + s.card, s.revenue);
      expect(s.revenue, trips.fold<int>(0, (sum, t) => sum + t.amount));
    });
  });

  group('validateTrip (mirrors the server)', () {
    test('valid trip, boundary values', () {
      expect(validateTrip(trip(amount: 1, commission: 0)), isEmpty);
      expect(validateTrip(trip(amount: 2400, commission: 2400)), isEmpty);
      expect(validateTrip(trip(duration: const Duration(hours: 24))), isEmpty);
    });

    final cases = <String, (Trip, TripRuleViolation)>{
      'amount 0': (
        trip(amount: 0, commission: 0),
        TripRuleViolation.invalidAmount,
      ),
      'negative amount': (
        trip(amount: -5, commission: 0),
        TripRuleViolation.invalidAmount,
      ),
      'amount too large': (
        trip(amount: TripLimits.maxAmount + 1),
        TripRuleViolation.amountTooLarge,
      ),
      'negative commission': (
        trip(commission: -1),
        TripRuleViolation.invalidCommission,
      ),
      'commission > amount': (
        trip(amount: 1000, commission: 1001),
        TripRuleViolation.commissionExceedsAmount,
      ),
      'end == start': (
        trip(duration: Duration.zero),
        TripRuleViolation.invalidTimeRange,
      ),
      'end < start': (
        trip(duration: const Duration(minutes: -1)),
        TripRuleViolation.invalidTimeRange,
      ),
      'longer than 24h': (
        trip(duration: const Duration(hours: 24, seconds: 1)),
        TripRuleViolation.tripTooLong,
      ),
      'before 2000': (
        trip(start: DateTime.utc(1999, 12, 31, 23)),
        TripRuleViolation.datetimeOutOfRange,
      ),
    };
    for (final MapEntry(key: name, value: (t, violation)) in cases.entries) {
      test(name, () => expect(validateTrip(t), contains(violation)));
    }

    test('codes match the server error codes', () {
      expect(
        TripRuleViolation.values.map((v) => v.code),
        containsAll([
          'invalid_amount',
          'amount_too_large',
          'invalid_commission',
          'commission_exceeds_amount',
          'invalid_time_range',
          'trip_too_long',
          'datetime_out_of_range',
        ]),
      );
    });
  });

  group('use cases', () {
    late MockTripsRepository repository;
    setUp(() => repository = MockTripsRepository());

    test('GetDayTrips asks the repository for the day and zone', () async {
      when(() => repository.tripsForDay(any(), any()))
          .thenAnswer((_) async => Ok([t1, t2]));

      final result = await GetDayTrips(repository)(referenceDay, kz);

      expect(result, isA<Ok<List<Trip>>>());
      verify(() => repository.tripsForDay(referenceDay, kz)).called(1);
    });

    test(
      'CreateTrip rejects an invalid trip without calling the API',
      () async {
        final result = await CreateTrip(repository)(
          trip(amount: 1000, commission: 1500),
          kz,
        );

        expect(
          result,
          isA<Err<Trip>>().having(
            (e) => e.failure,
            'failure',
            isA<ValidationFailure>()
                .having((f) => f.code, 'code', 'commission_exceeds_amount')
                .having((f) => f.field, 'field', 'commission'),
          ),
        );
        verifyNever(() => repository.createTrip(any(), any()));
      },
    );

    test('CreateTrip passes a valid trip through unchanged', () async {
      when(() => repository.createTrip(any(), any())).thenAnswer(
        (invocation) async => Ok(invocation.positionalArguments.first as Trip),
      );

      final result = await CreateTrip(repository)(t1, kz);

      expect((result as Ok<Trip>).value, t1);
      verify(() => repository.createTrip(t1, kz)).called(1);
    });
  });
}
