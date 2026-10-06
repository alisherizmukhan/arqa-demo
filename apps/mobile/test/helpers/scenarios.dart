import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/time/calendar_day.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/presentation/models/trip_form.dart';
import 'package:driver_diary/features/trips/presentation/screens/add_trip_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';
import 'fixtures.dart';

/// One mockup state, reached through the real app (fake repository only).
typedef Scenario = ({String id, Future<void> Function(WidgetTester) run});

final _sep30 = CalendarDay(2026, 9, 30);

/// Mockup 06's trips on 2026-09-30, before the new one is added.
final _sep30Trip = Trip(
  id: 'sep30-1',
  start: at(22, 10, day: 0),
  end: at(22, 35, day: 0),
  amount: 2000,
  payment: PaymentMethod.card,
  commission: 300,
);

TripFormInput _input(
  CalendarDay day, {
  ClockTime? start = (hour: 8, minute: 10),
  ClockTime? end = (hour: 8, minute: 32),
  String amount = '2400',
  String commission = '360',
  PaymentMethod payment = PaymentMethod.card,
}) => TripFormInput(
  day: day,
  start: start,
  end: end,
  amountText: amount,
  commissionText: commission,
  payment: payment,
);

Future<void> _form(
  WidgetTester tester,
  FakeTripsRepository repository,
  TripFormInput input,
) async {
  await pumpDiary(
    tester,
    repository,
    home: AddTripScreen(day: input.day, initialInput: input),
  );
  await tester.pump();
}

/// Lets a save attempt run and its dialog/snackbar settle in.
Future<void> _tapSave(WidgetTester tester) async {
  await tester.tap(find.text('Сохранить'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 600)); // ink ripple
}

final scenarios = <Scenario>[
  (
    id: '01_day_light',
    run: (tester) async {
      await pumpDiary(tester, FakeTripsRepository([t1, t2]));
      await selectDay(tester, referenceDay);
    },
  ),
  (
    id: '03_day_empty',
    run: (tester) async {
      await pumpDiary(tester, FakeTripsRepository());
      await tester.pumpAndSettle(); // the loading FAB animates out
    },
  ),
  (
    id: '04_day_loading',
    run: (tester) async {
      final repository = FakeTripsRepository()..onLoad = (_) => pending();
      await pumpDiary(tester, repository);
      await selectDay(tester, CalendarDay(2026, 10, 5));
    },
  ),
  (
    id: '05_day_error',
    run: (tester) async {
      final repository = FakeTripsRepository()
        ..onLoad = (_) async => const Err(NetworkFailure());
      await pumpDiary(tester, repository);
      await selectDay(tester, referenceDay);
      await tester.pumpAndSettle(); // the loading FAB animates out
    },
  ),
  (
    id: '06_day_trip_added',
    run: (tester) async {
      await pumpDiary(tester, FakeTripsRepository([_sep30Trip]));
      await selectDay(tester, _sep30);
      await tester.tap(find.text('Поездка'));
      await tester.pumpAndSettle();
      await pickTime(tester, 'Начало', 23, 50);
      await pickTime(tester, 'Окончание', 0, 20);
      await tester.enterText(find.byType(TextField).at(0), '3000');
      await tester.enterText(find.byType(TextField).at(1), '450');
      await tester.tap(find.text('Наличные'));
      await tester.pump();
      await tester.tap(find.text('Сохранить'));
      // Save, close the form, reload the day, place the snackbar.
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    },
  ),
  (
    id: '07_add_trip',
    run: (tester) async {
      await _form(tester, FakeTripsRepository(), _input(referenceDay));
      await tester.tap(find.byType(TextField).at(0));
      await tester.pump();
    },
  ),
  (
    id: '08_add_trip_errors',
    run: (tester) async {
      await _form(
        tester,
        FakeTripsRepository(),
        _input(
          referenceDay,
          start: (hour: 9, minute: 20),
          end: (hour: 9, minute: 5),
          amount: '0',
          commission: '225',
          payment: PaymentMethod.cash,
        ),
      );
      await _tapSave(tester);
    },
  ),
  (
    id: '09_add_trip_saving',
    run: (tester) async {
      final repository = FakeTripsRepository()..onCreate = (_) => pending();
      await _form(tester, repository, _input(referenceDay));
      await _tapSave(tester);
    },
  ),
  (
    id: '10_add_trip_offline',
    run: (tester) async {
      final repository = FakeTripsRepository()
        ..onCreate = (_) async => const Err(NetworkFailure());
      await _form(tester, repository, _input(referenceDay));
      await _tapSave(tester);
    },
  ),
  (
    id: '11_add_trip_midnight',
    run: (tester) async {
      await _form(
        tester,
        FakeTripsRepository(),
        _input(
          _sep30,
          start: (hour: 23, minute: 50),
          end: (hour: 0, minute: 20),
          amount: '3000',
          commission: '450',
          payment: PaymentMethod.cash,
        ),
      );
    },
  ),
  (
    id: '12_add_trip_conflict_409',
    run: (tester) async {
      final repository = FakeTripsRepository()
        ..onCreate = (_) async => const Err(ConflictFailure());
      await _form(tester, repository, _input(referenceDay));
      await _tapSave(tester);
    },
  ),
];

/// Mockup 02 is 01 in the dark theme; 07 and 12 have no dark mockup.
const darkScenarioIds = {
  '01_day_light',
  '07_add_trip',
  '12_add_trip_conflict_409',
};

/// Extra states for the layout matrix only (no mockup): the largest sums.
final stressScenarios = <Scenario>[
  (
    id: 'day_max_amounts',
    run: (tester) async {
      await pumpDiary(
        tester,
        FakeTripsRepository([
          for (var i = 0; i < 6; i++)
            trip(
              id: 'big-$i',
              start: at(8 + i, 0),
              amount: 9999990,
              commission: 1499998,
              payment: i.isEven ? PaymentMethod.cash : PaymentMethod.card,
            ),
        ]),
      );
      await selectDay(tester, referenceDay);
    },
  ),
  (
    id: 'add_trip_max_amounts',
    run: (tester) async {
      await _form(
        tester,
        FakeTripsRepository(),
        _input(referenceDay, amount: '99999999', commission: '99999999'),
      );
    },
  ),
];
