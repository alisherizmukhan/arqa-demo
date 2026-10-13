import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/features/trips/domain/entities/place.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/presentation/models/trip_form.dart';
import 'package:driver_diary/features/trips/presentation/screens/add_trip_screen.dart';
import 'package:driver_diary/features/trips/presentation/screens/day_map_screen.dart';
import 'package:driver_diary/features/trips/presentation/screens/place_picker_screen.dart';
import 'package:driver_diary/features/trips/presentation/screens/trip_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';
import 'fakes.dart';
import 'fixtures.dart';
import 'map_fixtures.dart';
import 'scenarios.dart';

/// A trip without places, next to the ones with places.
final Trip _plain = trip(
  id: 'plain',
  start: at(13, 40),
  duration: const Duration(minutes: 25),
  amount: 1900,
  payment: PaymentMethod.cash,
  commission: 285,
);

TripFormInput _form({Place? pickup, Place? dropoff}) => TripFormInput(
  day: referenceDay,
  start: (hour: 8, minute: 10),
  end: (hour: 8, minute: 32),
  amountText: '2400',
  commissionText: '360',
  pickup: pickup,
  dropoff: dropoff,
);

Future<void> _picker(
  WidgetTester tester,
  FakeGeoRepository geo, {
  DkPlaceKind kind = DkPlaceKind.start,
  Place? current,
  Place? near,
}) async {
  await pumpDiary(
    tester,
    FakeTripsRepository(),
    geo: geo,
    home: PlacePickerScreen(kind: kind, current: current, near: near),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _details(WidgetTester tester, Trip shown) async {
  await pumpDiary(
    tester,
    FakeTripsRepository([shown]),
    home: TripDetailsScreen(tripId: shown.id, initial: shown),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// The DESIGN.md §9 screens, through the real app with fakes and tiles
/// drawn on the device (no network).
final mapScenarios = <Scenario>[
  (
    id: 'm01_add_trip_places',
    run: (tester) async {
      await pumpDiary(
        tester,
        FakeTripsRepository(),
        home: AddTripScreen(
          day: referenceDay,
          initialInput: _form(pickup: bazaar, dropoff: esentai),
        ),
      );
      await tester.pump();
    },
  ),
  (
    id: 'm02_add_trip_incomplete',
    run: (tester) async {
      await pumpDiary(
        tester,
        FakeTripsRepository(),
        home: AddTripScreen(
          day: referenceDay,
          initialInput: _form(pickup: bazaar),
        ),
      );
      await tester.pump();
      await tester.tap(find.text(tr.save));
      await tester.pump();
    },
  ),
  (id: 'm03_picker', run: (tester) => _picker(tester, FakeGeoRepository())),
  (
    id: 'm04_picker_resolving',
    run: (tester) =>
        _picker(tester, FakeGeoRepository()..onReverse = (_) => pending()),
  ),
  (
    id: 'm05_picker_not_found',
    run: (tester) => _picker(
      tester,
      FakeGeoRepository()..onReverse = (_) async => const Ok(null),
    ),
  ),
  (
    id: 'm06_picker_search',
    run: (tester) async {
      await _picker(
        tester,
        FakeGeoRepository()
          ..places = [
            (label: 'Зелёный базар', point: bazaar.point),
            (label: 'Зелёный квартал', point: republic.point),
          ],
      );
      await tester.enterText(find.byType(TextField), 'Зелён');
      await tester.pump(const Duration(seconds: 1));
    },
  ),
  (
    id: 'm07_picker_offline',
    run: (tester) => _picker(
      tester,
      FakeGeoRepository()..onReverse = (_) async => const Err(NetworkFailure()),
    ),
  ),
  (
    id: 'm08_picker_end',
    run: (tester) => _picker(
      tester,
      FakeGeoRepository(),
      kind: DkPlaceKind.end,
      near: bazaar,
    ),
  ),
  (
    id: 'm09_day_trips',
    run: (tester) async {
      await pumpDiary(tester, FakeTripsRepository([mapT1, mapT2, _plain]));
      await selectDay(tester, referenceDay);
    },
  ),
  (id: 'm10_details_ready', run: (tester) => _details(tester, mapT1)),
  (
    id: 'm11_details_straight',
    run: (tester) => _details(tester, mapT1Straight),
  ),
  (id: 'm12_details_pending', run: (tester) => _details(tester, mapT2Pending)),
  (
    id: 'm13_day_map',
    run: (tester) async {
      await pumpDiary(
        tester,
        FakeTripsRepository([mapT1, mapT2, _plain]),
        home: DayMapScreen(day: referenceDay),
      );
      await tester.pumpAndSettle();
    },
  ),
  (
    id: 'm14_day_map_admin',
    run: (tester) async {
      await pumpDiary(
        tester,
        FakeTripsRepository([mapT1, mapT2, mapU2t1, mapU2t2]),
        user: adminUser,
        home: DayMapScreen(day: referenceDay, filter: tr.allDrivers),
      );
      await tester.pumpAndSettle();
    },
  ),
  (
    id: 'm15_day_map_selected',
    run: (tester) async {
      await pumpDiary(
        tester,
        FakeTripsRepository([mapT1, mapT2, _plain]),
        home: DayMapScreen(day: referenceDay),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ТРЦ Есентай Молл → Площадь Республики'));
      await tester.pumpAndSettle();
    },
  ),
];

/// Map states also shot in the dark theme.
const darkMapScenarioIds = {
  'm01_add_trip_places',
  'm03_picker',
  'm09_day_trips',
  'm10_details_ready',
  'm11_details_straight',
  'm13_day_map',
  'm15_day_map_selected',
};
