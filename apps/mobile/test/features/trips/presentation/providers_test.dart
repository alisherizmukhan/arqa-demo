import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/providers.dart';
import 'package:driver_diary/core/time/calendar_day.dart';
import 'package:driver_diary/features/trips/domain/entities/daily_summary.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/presentation/providers/trips_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fixtures.dart';

void main() {
  setUpAll(registerFallbacks);

  late MockTripsRepository repository;

  /// "Now" is 2026-10-01 20:00 UTC: already 2026-10-02 01:00 in +05:00.
  ProviderContainer makeContainer({DateTime? now}) => ProviderContainer.test(
    overrides: [
      tripsRepositoryProvider.overrideWithValue(repository),
      driverZoneProvider.overrideWithValue(kz),
      clockProvider.overrideWithValue(
        () => now ?? DateTime.utc(2026, 10, 1, 20),
      ),
    ],
    retry: (_, _) => null,
  );

  setUp(() {
    repository = MockTripsRepository();
    when(() => repository.tripsForDay(any(), any()))
        .thenAnswer((_) async => const Ok([]));
  });

  group('selected day', () {
    test('starts at today in the driver zone, not UTC', () {
      final container = makeContainer();

      expect(container.read(selectedDayProvider), CalendarDay(2026, 10, 2));
    });

    test('moves back and forward but never past today', () {
      final container = makeContainer();
      final notifier = container.read(selectedDayProvider.notifier)
        ..previous()
        ..previous();
      expect(container.read(selectedDayProvider), CalendarDay(2026, 9, 30));

      notifier
        ..next()
        ..next()
        ..next();
      expect(container.read(selectedDayProvider), CalendarDay(2026, 10, 2));

      notifier.select(CalendarDay(2030, 1, 1));
      expect(container.read(selectedDayProvider), CalendarDay(2026, 10, 2));
    });
  });

  group('day trips and summary', () {
    test('load the selected day and the reference summary', () async {
      when(() => repository.tripsForDay(referenceDay, kz))
          .thenAnswer((_) async => Ok([t1, t2]));
      final container = makeContainer();

      final trips = await container.read(dayTripsProvider(referenceDay).future);
      final summary = await container.read(
        daySummaryProvider(referenceDay).future,
      );

      expect(trips, [t1, t2]);
      expect(
        summary,
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

    test(
      'each day is fetched once and stays cached after it is left',
      () async {
        final container = makeContainer();
        final today = CalendarDay(2026, 10, 2);
        final yesterday = CalendarDay(2026, 10, 1);

        // Viewed and left (no listener), then viewed again.
        for (final day in [today, yesterday, today, yesterday]) {
          final sub = container.listen(dayTripsProvider(day), (_, _) {});
          await container.read(dayTripsProvider(day).future);
          sub.close();
          await Future<void>.delayed(Duration.zero);
        }

        verify(() => repository.tripsForDay(today, kz)).called(1);
        verify(() => repository.tripsForDay(yesterday, kz)).called(1);
      },
    );

    test('a failed day is not cached: the next view refetches', () async {
      var calls = 0;
      when(() => repository.tripsForDay(any(), any())).thenAnswer((_) async {
        calls++;
        return calls == 1 ? const Err(NetworkFailure()) : Ok([t1]);
      });
      final container = makeContainer();

      final failing = container.listen(
        dayTripsProvider(referenceDay),
        (_, _) {},
      );
      await expectLater(
        container.read(dayTripsProvider(referenceDay).future),
        throwsA(isA<NetworkFailure>()),
      );
      failing.close();
      await Future<void>.delayed(Duration.zero);

      expect(await container.read(dayTripsProvider(referenceDay).future), [t1]);
      expect(calls, 2);
    });

    test('a failure surfaces as AsyncError with the Failure', () async {
      when(() => repository.tripsForDay(any(), any()))
          .thenAnswer((_) async => const Err(NetworkFailure()));
      final container = makeContainer();

      final sub = container.listen(dayTripsProvider(referenceDay), (_, _) {});

      await expectLater(
        container.read(dayTripsProvider(referenceDay).future),
        throwsA(isA<NetworkFailure>()),
      );
      expect(
        container.read(dayTripsProvider(referenceDay)).error,
        isA<NetworkFailure>(),
      );
      sub.close();
    });
  });

  group('add trip controller', () {
    late List<Trip> sent;

    setUp(() => sent = []);

    void answerCreate(List<Result<Trip>> results) {
      var call = 0;
      when(() => repository.createTrip(any(), any()))
          .thenAnswer((invocation) async {
            sent.add(invocation.positionalArguments.first as Trip);
            return results[call++];
          });
    }

    test(
      'retrying the same trip after a network error reuses its id',
      () async {
        answerCreate([const Err(NetworkFailure()), Ok(t1)]);
        final container = makeContainer();
        final sub = container.listen(addTripControllerProvider, (_, _) {});
        final controller = container.read(addTripControllerProvider.notifier);

        await controller.save(trip(id: 'first-id'));
        await controller.save(trip(id: 'fresh-id-from-form'));

        expect(sent.map((t) => t.id), ['first-id', 'first-id']);
        sub.close();
      },
    );

    test('a changed trip after a failure gets the new id', () async {
      answerCreate([const Err(NetworkFailure()), Ok(t1)]);
      final container = makeContainer();
      final sub = container.listen(addTripControllerProvider, (_, _) {});
      final controller = container.read(addTripControllerProvider.notifier);

      await controller.save(trip(id: 'first-id'));
      await controller.save(trip(id: 'second-id', amount: 2100));

      expect(sent.map((t) => t.id), ['first-id', 'second-id']);
      sub.close();
    });

    test('after a conflict the next save uses a new id', () async {
      answerCreate([const Err(ConflictFailure()), Ok(t1)]);
      final container = makeContainer();
      final sub = container.listen(addTripControllerProvider, (_, _) {});
      final controller = container.read(addTripControllerProvider.notifier);

      await controller.save(trip(id: 'taken'));
      await controller.save(trip(id: 'fresh'));

      expect(sent.map((t) => t.id), ['taken', 'fresh']);
      sub.close();
    });

    test('success refreshes the day list', () async {
      answerCreate([Ok(t1)]);
      final container = makeContainer();
      final sub = container.listen(addTripControllerProvider, (_, _) {});
      final tripsSub = container.listen(
        dayTripsProvider(referenceDay),
        (_, _) {},
      );
      await container.read(dayTripsProvider(referenceDay).future);

      final result = await container
          .read(addTripControllerProvider.notifier)
          .save(t1);
      await container.read(dayTripsProvider(referenceDay).future);

      expect(result, isA<Ok<Trip>>());
      expect(container.read(addTripControllerProvider).value, t1);
      verify(() => repository.tripsForDay(any(), any())).called(2);
      sub.close();
      tripsSub.close();
    });
  });
}
