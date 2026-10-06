import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/app.dart';
import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/providers.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/presentation/providers/trips_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fixtures.dart';

void main() {
  setUpAll(registerFallbacks);

  late MockTripsRepository repository;

  setUp(() => repository = MockTripsRepository());

  /// The app with "now" = 2026-10-01 12:00 in +05:00 (the reference day).
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(412, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tripsRepositoryProvider.overrideWithValue(repository),
          driverZoneProvider.overrideWithValue(kz),
          clockProvider.overrideWithValue(() => at(12, 0)),
        ],
        retry: (_, _) => null,
        child: const App(),
      ),
    );
  }

  String money(int amount) => DkMoney.format(amount);

  testWidgets('day screen renders the reference summary and trips', (
    tester,
  ) async {
    when(() => repository.tripsForDay(any(), any()))
        .thenAnswer((_) async => Ok([t1, t2]));

    await pumpApp(tester);
    await tester.pump();

    expect(find.text('Сегодня'), findsOneWidget);
    expect(find.text('1 октября 2026'), findsOneWidget);
    expect(find.text(money(3315)), findsOneWidget); // net
    expect(find.text(money(3900)), findsOneWidget); // revenue
    expect(find.text(DkMoney.format(-585)), findsOneWidget); // commission
    expect(find.text(money(1500)), findsWidgets); // cash total + t2 row
    expect(find.text(money(2400)), findsWidgets); // card total + t1 row
    expect(find.text('08:10 – 08:32'), findsOneWidget);
    expect(find.text('09:05 – 09:20'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty day shows the empty state and zero totals', (
    tester,
  ) async {
    when(() => repository.tripsForDay(any(), any()))
        .thenAnswer((_) async => const Ok([]));

    await pumpApp(tester);
    await tester.pump();
    expect(find.text('Поездок нет'), findsOneWidget);
    expect(find.text(money(0)), findsWidgets);
  });

  testWidgets('error state retries', (tester) async {
    var calls = 0;
    when(() => repository.tripsForDay(any(), any())).thenAnswer((_) async {
      calls++;
      return calls == 1 ? const Err(NetworkFailure()) : Ok([t1, t2]);
    });

    await pumpApp(tester);
    await tester.pump();
    expect(find.textContaining('Нет связи с сервером'), findsOneWidget);

    await tester.tap(find.text('Повторить'));
    await tester.pump();
    await tester.pump();

    expect(find.text(money(3315)), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('add trip: validation errors are shown before any request', (
    tester,
  ) async {
    when(() => repository.tripsForDay(any(), any()))
        .thenAnswer((_) async => const Ok([]));

    await pumpApp(tester);
    await tester.pump();
    await tester.tap(find.text('Добавить поездку'));
    await tester.pumpAndSettle();

    // Nothing filled in: every required field explains itself.
    await tester.tap(find.text('Сохранить'));
    await tester.pump();
    expect(find.text('Укажите время начала'), findsOneWidget);
    expect(find.text('Укажите сумму'), findsOneWidget);
    verifyNever(() => repository.createTrip(any(), any()));

    // Commission larger than the amount is caught before any request.
    await tester.enterText(find.byType(TextField).at(0), '1000');
    await tester.enterText(find.byType(TextField).at(1), '1500');
    await tester.pump();
    expect(find.text('Комиссия не может быть больше суммы'), findsOneWidget);
    verifyNever(() => repository.createTrip(any(), any()));
  });

  testWidgets('no overflow on a 360dp phone with large totals', (tester) async {
    final big = [
      for (var i = 0; i < 6; i++)
        trip(
          id: 'big-$i',
          start: at(8 + i, 0),
          amount: 9999990,
          commission: 1499998,
          payment: i.isEven ? PaymentMethod.cash : PaymentMethod.card,
        ),
    ];
    when(() => repository.tripsForDay(any(), any()))
        .thenAnswer((_) async => Ok(big));

    await pumpApp(tester);
    tester.view.physicalSize = const Size(360, 1600);
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Добавить поездку'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
