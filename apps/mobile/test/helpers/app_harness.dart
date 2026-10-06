import 'dart:async';
import 'dart:convert';

import 'package:driver_diary/app.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/providers.dart';
import 'package:driver_diary/core/time/calendar_day.dart';
import 'package:driver_diary/core/time/driver_zone.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/domain/repositories/trips_repository.dart';
import 'package:driver_diary/features/trips/presentation/models/trip_form.dart';
import 'package:driver_diary/features/trips/presentation/providers/trips_providers.dart';
import 'package:driver_diary/features/trips/presentation/screens/add_trip_screen.dart';
import 'package:driver_diary/features/trips/presentation/screens/day_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

/// In-memory repository; [onLoad] / [onCreate] replace the default answers.
class FakeTripsRepository implements TripsRepository {
  new([Iterable<Trip> trips = const []]) : trips = [...trips];

  final List<Trip> trips;
  final created = <Trip>[];
  int loads = 0;
  Future<Result<List<Trip>>> Function(CalendarDay day)? onLoad;
  Future<Result<Trip>> Function(Trip trip)? onCreate;

  @override
  Future<Result<List<Trip>>> tripsForDay(
    CalendarDay day,
    DriverZone zone,
  ) async {
    loads++;
    if (onLoad case final load?) return await load(day);
    return Ok(
      trips.where((t) => zone.dayOf(t.start) == day).toList()
        ..sort((a, b) => a.start.compareTo(b.start)),
    );
  }

  @override
  Future<Result<Trip>> createTrip(Trip trip, DriverZone zone) async {
    created.add(trip);
    if (onCreate case final create?) return await create(trip);
    trips.add(trip);
    return Ok(trip);
  }
}

/// A future that never completes (a request still in flight).
Future<T> pending<T>() => Completer<T>().future;

/// Wraps the whole app, overlays included, for screenshots.
final GlobalKey shotKey = GlobalKey();

/// "Now" in the scenarios: 2026-10-06 12:00 +05:00 (mockup 03's «Сегодня»).
final DateTime scenarioNow = at(12, 0, day: 6);

/// Device and appearance for one run.
typedef Device = ({
  Size size,
  double textScale,
  Brightness brightness,
  double pixelRatio,
});

const Device phone390 = (
  size: Size(390, 844),
  textScale: 1,
  brightness: Brightness.light,
  pixelRatio: 1,
);

/// Sets the test view to [device], with the mockups' safe area (54 / 34).
void useDevice(WidgetTester tester, Device device) {
  final r = device.pixelRatio;
  tester.view
    ..physicalSize = device.size * r
    ..devicePixelRatio = r
    ..padding = FakeViewPadding(top: 54 * r, bottom: 34 * r)
    ..viewPadding = FakeViewPadding(top: 54 * r, bottom: 34 * r);
  tester.platformDispatcher
    ..textScaleFactorTestValue = device.textScale
    ..platformBrightnessTestValue = device.brightness;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

/// Pumps the app (Day screen unless [home]) with [repository].
Future<void> pumpDiary(
  WidgetTester tester,
  FakeTripsRepository repository, {
  Widget? home,
  DateTime? now,
}) async {
  await tester.pumpWidget(
    RepaintBoundary(
      key: shotKey,
      child: ProviderScope(
        overrides: [
          tripsRepositoryProvider.overrideWithValue(repository),
          driverZoneProvider.overrideWithValue(kz),
          clockProvider.overrideWithValue(() => now ?? scenarioNow),
        ],
        retry: (_, _) => null,
        child: home == null ? const App() : App(home: home),
      ),
    ),
  );
}

/// The app's provider container.
ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(App)));

/// Shows [day] on the Day screen.
Future<void> selectDay(WidgetTester tester, CalendarDay day) async {
  containerOf(tester).read(selectedDayProvider.notifier).select(day);
  await tester.pump();
  await tester.pump();
}

/// Picks [hour]:[minute] in the time field labelled [label] through the
/// Material time picker (keyboard entry).
Future<void> pickTime(
  WidgetTester tester,
  String label,
  int hour,
  int minute,
) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.keyboard_outlined));
  await tester.pumpAndSettle();
  final dialog = find.byType(Dialog);
  final inputs = find.descendant(of: dialog, matching: find.byType(TextField));
  await tester.enterText(inputs.at(0), '$hour'.padLeft(2, '0'));
  await tester.enterText(inputs.at(1), '$minute'.padLeft(2, '0'));
  await tester.tap(find.text('ОК'));
  await tester.pumpAndSettle();
}

/// Loads every font in the app's font manifest (Manrope, IBM Plex Sans,
/// Lucide), so text and icons render and measure as on a device.
Future<void> loadAppFonts() async {
  final manifest = jsonDecode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family'] as String);
    for (final font in (entry['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

/// The Day screen is showing.
Finder get dayScreen => find.byType(DayScreen);

/// Unmounts the app and lets its timers (snackbar, highlight) run out.
Future<void> disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 5));
}

/// A screen that opens the form the way the Day screen does (pushed,
/// full-screen) and shows its result as «host: …».
class FormHost extends StatefulWidget {
  const new({this.input, super.key});

  final TripFormInput? input;

  @override
  State<FormHost> createState() => _FormHostState();
}

class _FormHostState extends State<FormHost> {
  Object? result = 'open';

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () async {
          final trip = await Navigator.of(context).push<Trip>(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => AddTripScreen(
                day: widget.input?.day ?? referenceDay,
                initialInput: widget.input,
              ),
            ),
          );
          setState(() => result = trip);
        },
        child: Text('host: $result'),
      ),
    ),
  );
}

/// Opens the form over [FormHost].
Future<void> pumpFormOverHost(
  WidgetTester tester,
  FakeTripsRepository repository, {
  TripFormInput? input,
}) async {
  await pumpDiary(tester, repository, home: FormHost(input: input));
  await tester.tap(find.byType(TextButton));
  await tester.pumpAndSettle();
}
