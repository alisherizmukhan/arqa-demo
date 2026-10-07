import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/features/trips/presentation/models/trip_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/fixtures.dart';

void main() {
  final early = trip(id: 'a', start: at(8, 0), amount: 1500);
  final middle = trip(id: 'b', start: at(12, 0), amount: 4000);
  final late = trip(id: 'c', start: at(18, 0), amount: 1500);
  final trips = [middle, late, early];

  List<String> ids(TripOrder order) =>
      order.sort(trips).map((t) => t.id).toList();

  group('TripOrder.sort', () {
    test('time ascending is start order', () {
      expect(ids(TripOrder.timeAscending), ['a', 'b', 'c']);
    });

    test('time descending is reverse start order', () {
      expect(ids(TripOrder.timeDescending), ['c', 'b', 'a']);
    });

    test('by amount; equal amounts keep start order', () {
      expect(ids(TripOrder.amountDescending), ['b', 'a', 'c']);
      expect(ids(TripOrder.amountAscending), ['a', 'c', 'b']);
    });

    test('does not change the given list', () {
      TripOrder.timeDescending.sort(trips);
      expect(trips.map((t) => t.id), ['b', 'c', 'a']);
    });
  });

  group('Day screen', () {
    List<String> shownRanges(WidgetTester tester) => tester
        .widgetList<DkTripTile>(find.byType(DkTripTile))
        .map((t) => t.timeRange)
        .toList();

    testWidgets('starts in time order; the sort sheet changes it', (
      tester,
    ) async {
      useDevice(tester, phone390);
      await pumpDiary(tester, FakeTripsRepository(trips));
      await selectDay(tester, referenceDay);
      await tester.pumpAndSettle();
      expect(shownRanges(tester), [
        '08:00 – 08:20',
        '12:00 – 12:20',
        '18:00 – 18:20',
      ]);

      await tester.tap(find.bySemanticsLabel('Сортировка: сначала ранние'));
      await tester.pumpAndSettle();
      expect(find.text('Сортировка'), findsOneWidget);
      await tester.tap(find.text('Сначала дорогие'));
      await tester.pumpAndSettle();

      expect(shownRanges(tester), [
        '12:00 – 12:20',
        '08:00 – 08:20',
        '18:00 – 18:20',
      ]);
      expect(
        find.bySemanticsLabel('Сортировка: сначала дорогие'),
        findsOneWidget,
      );
      await disposeApp(tester);
    });
  });

  testWidgets('a new trip far down a long list is scrolled into view', (
    tester,
  ) async {
    useDevice(tester, phone390);
    final day = [
      for (var i = 0; i < 15; i++)
        trip(id: 'd$i', start: at(6, i * 20), amount: 1000 + i),
    ];
    await pumpDiary(tester, FakeTripsRepository(day));
    await selectDay(tester, referenceDay);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DkFab));
    await tester.pumpAndSettle();
    await pickTime(tester, 'Начало', 22, 0);
    await pickTime(tester, 'Окончание', 22, 30);
    await tester.enterText(find.byType(TextField).at(0), '5000');
    await tester.enterText(find.byType(TextField).at(1), '500');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    final row = find.byWidgetPredicate(
      (w) => w is DkTripTile && w.timeRange == '22:00 – 22:30',
    );
    expect(tester.widget<DkTripTile>(row).highlighted, isTrue);
    final rect = tester.getRect(row);
    final fab = tester.getRect(find.byType(DkFab));
    // On screen, clear of the FAB.
    expect(rect.top, greaterThan(54));
    expect(rect.bottom, lessThan(fab.top));
    await tester.pump(const Duration(seconds: 3));
    await disposeApp(tester);
  });
}
