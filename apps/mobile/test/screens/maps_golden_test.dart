// DESIGN.md §9: a route on the map (tiles drawn on the device, no network),
// light and dark: the road route and the straight-line fallback.
//
// A platform golden (goldens/<os>/), compared locally like the other
// platform goldens: under alchemist the map never gets its size (no tiles,
// no fit), so this one is a plain matchesGoldenFile with real frames. CI
// checks the route style through the kit's map tests.
import 'dart:io';

import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/presentation/screens/trip_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/map_fixtures.dart';

void main() {
  final onCi = Platform.environment.containsKey('CI');

  setUpAll(loadAppFonts);

  for (final (name, shown) in [
    ('trip_details_ready', mapT1),
    ('trip_details_straight', mapT1Straight),
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets('$name ${brightness.name}', skip: onCi, (tester) async {
        useDevice(tester, (
          size: phone390.size,
          textScale: 1,
          brightness: brightness,
          pixelRatio: 1,
        ));
        await _pump(tester, shown);
        await expectLater(
          find.byKey(shotKey),
          matchesGoldenFile(
            'goldens/${Platform.operatingSystem}/'
            '${name}_${brightness.name}.png',
          ),
        );
        await disposeApp(tester);
      });
    }
  }
}

Future<void> _pump(WidgetTester tester, Trip shown) async {
  await pumpDiary(
    tester,
    FakeTripsRepository([shown]),
    home: TripDetailsScreen(tripId: shown.id, initial: shown),
  );
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}
