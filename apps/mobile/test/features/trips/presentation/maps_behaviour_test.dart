import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/features/trips/domain/entities/place.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/presentation/screens/day_map_screen.dart';
import 'package:driver_diary/features/trips/presentation/screens/place_picker_screen.dart';
import 'package:driver_diary/features/trips/presentation/screens/trip_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fixtures.dart';
import '../../../helpers/map_fixtures.dart';

/// Opens the picker over a host page and shows its result as «picked: …».
class _PickerHost extends StatefulWidget {
  const new({this.kind = DkPlaceKind.start, this.current, this.near});

  final DkPlaceKind kind;
  final Place? current;
  final Place? near;

  @override
  State<_PickerHost> createState() => _PickerHostState();
}

class _PickerHostState extends State<_PickerHost> {
  Object? picked = 'nothing';

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () async {
          final place = await pickPlace(
            context,
            kind: widget.kind,
            current: widget.current,
            near: widget.near,
          );
          setState(() => picked = place);
        },
        child: Text('picked: $picked'),
      ),
    ),
  );
}

Future<void> _openPicker(
  WidgetTester tester,
  FakeGeoRepository geo, {
  _PickerHost host = const _PickerHost(),
}) async {
  useDevice(tester, phone390);
  await pumpDiary(tester, FakeTripsRepository(), home: host, geo: geo);
  await tester.tap(find.byType(TextButton));
  await tester.pumpAndSettle();
}

MapController _controller(WidgetTester tester) =>
    tester.widget<DkMapView>(find.byType(DkMapView)).controller!;

void main() {
  setUpAll(loadAppFonts);

  group('place picker', () {
    testWidgets('looks the center up 500 ms after the map stops', (
      tester,
    ) async {
      final geo = FakeGeoRepository();
      await _openPicker(tester, geo);
      // The start view (Almaty center) is looked up once.
      expect(geo.reverses, [almatyCenter]);
      expect(find.text('площадь Республики, 2'), findsOneWidget);

      // A drag: several moves, one lookup after the last.
      await tester.drag(find.byType(FlutterMap), const Offset(-80, 40));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(tr.resolvingAddress), findsOneWidget);
      expect(geo.reverses, hasLength(1));
      await tester.pump(reverseDebounce);
      expect(geo.reverses, hasLength(2));
      expect(find.text(tr.resolvingAddress), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('search waits 400 ms and 3 characters; a result moves the '
        'map and keeps its name', (tester) async {
      final geo = FakeGeoRepository()
        ..places = [(label: 'Зелёный базар', point: bazaar.point)];
      await _openPicker(tester, geo);

      await tester.enterText(find.byType(TextField), 'Зе');
      await tester.pump(const Duration(seconds: 1));
      expect(geo.searches, isEmpty);

      await tester.enterText(find.byType(TextField), 'Зел');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(find.byType(TextField), 'Зелён');
      await tester.pump(searchDebounce);
      expect(geo.searches, ['Зелён']);

      await tester.tap(find.text('Зелёный базар'));
      await tester.pumpAndSettle();
      final center = _controller(tester).camera.center;
      expect(center.latitude, closeTo(bazaar.point.lat, 1e-6));
      // The result's name, not a reverse lookup of it.
      expect(find.text('Зелёный базар'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(geo.reverses, hasLength(1));

      await tester.tap(find.text(tr.pickThisPlace));
      await tester.pumpAndSettle();
      expect(
        find.text('picked: ${Place(point: bazaar.point, label: bazaar.label)}'),
        findsOneWidget,
      );
      await disposeApp(tester);
    });

    testWidgets('no address: the coordinates are the label, and the place '
        'can still be chosen without one', (tester) async {
      final geo = FakeGeoRepository()..onReverse = (_) async => const Ok(null);
      await _openPicker(tester, geo);
      expect(find.text(tr.addressNotFound), findsOneWidget);
      expect(find.text('43.2389, 76.8897'), findsOneWidget);

      await tester.tap(find.text(tr.pickThisPlace));
      await tester.pumpAndSettle();
      expect(
        find.text('picked: ${const Place(point: almatyCenter)}'),
        findsOneWidget,
      );
      await disposeApp(tester);
    });

    testWidgets('offline: an info row, the button still works', (tester) async {
      final geo = FakeGeoRepository()
        ..onReverse = (_) async => const Err(NetworkFailure());
      await _openPicker(tester, geo);
      expect(find.text(tr.mapOffline), findsOneWidget);
      expect(tapEnabled(tester, tr.pickThisPlace), isTrue);
      await disposeApp(tester);
    });

    testWidgets('while looking up, the button waits', (tester) async {
      final geo = FakeGeoRepository()..onReverse = (_) => pending();
      await _openPicker(tester, geo);
      expect(find.text(tr.resolvingAddress), findsOneWidget);
      expect(tapEnabled(tester, tr.pickThisPlace), isFalse);
      await disposeApp(tester);
    });

    testWidgets('B starts at A, zoomed in; a known place is not looked up '
        'again', (tester) async {
      final geo = FakeGeoRepository();
      await _openPicker(
        tester,
        geo,
        host: const _PickerHost(
          kind: DkPlaceKind.end,
          current: esentai,
          near: bazaar,
        ),
      );
      expect(geo.reverses, isEmpty);
      expect(find.text('ТРЦ Есентай Молл'), findsOneWidget);
      final camera = _controller(tester).camera;
      expect(camera.center, const LatLng(43.2185, 76.928));
      expect(camera.zoom, 16);
      await disposeApp(tester);
    });
  });

  group('add trip with places', () {
    testWidgets('A and B picked: the trip is sent with both', (tester) async {
      final repository = FakeTripsRepository();
      useDevice(tester, phone390);
      await pumpFormOverHost(tester, repository);
      await pickTime(tester, tr.start, 8, 10);
      await pickTime(tester, tr.end, 8, 32);

      await tester.tap(find.text(tr.placeFrom));
      await tester.pumpAndSettle();
      await tester.tap(find.text(tr.pickThisPlace));
      await tester.pumpAndSettle();
      expect(find.text('площадь Республики, 2'), findsOneWidget);
      expect(find.text(tr.errIncompleteRoute), findsOneWidget);

      await tester.tap(find.text(tr.placeTo));
      await tester.pumpAndSettle();
      // B starts at A: move it, so the places differ.
      await tester.drag(find.byType(FlutterMap), const Offset(0, -200));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text(tr.pickThisPlace));
      await tester.pumpAndSettle();
      expect(find.text(tr.errIncompleteRoute), findsNothing);

      await tester.enterText(find.byType(TextField).at(0), '2400');
      await tester.enterText(find.byType(TextField).at(1), '360');
      await tester.tap(find.text(tr.save));
      await tester.pumpAndSettle();

      final sent = repository.created.single;
      expect(sent.pickup!.point, almatyCenter);
      expect(sent.dropoff, isNotNull);
      expect(sent.dropoff!.point, isNot(almatyCenter));
      await disposeApp(tester);
    });

    testWidgets('a place can be cleared', (tester) async {
      useDevice(tester, phone390);
      await pumpFormOverHost(tester, FakeTripsRepository());
      await tester.tap(find.text(tr.placeFrom));
      await tester.pumpAndSettle();
      await tester.tap(find.text(tr.pickThisPlace));
      await tester.pumpAndSettle();
      expect(find.text('площадь Республики, 2'), findsOneWidget);

      await tester.tap(iconButton(tr.clearPlace));
      await tester.pump();
      expect(find.text('площадь Республики, 2'), findsNothing);
      expect(find.text(tr.pickOnMap), findsNWidgets(2));
      await disposeApp(tester);
    });

    testWidgets('a server error about a place shows under the places', (
      tester,
    ) async {
      final repository = FakeTripsRepository()
        ..onCreate = (_) async => const Err(
          ValidationFailure(
            code: 'outside_service_area',
            message: 'outside',
            field: 'dropoff',
          ),
        );
      useDevice(tester, phone390);
      await pumpFormOverHost(tester, repository);
      await pickTime(tester, tr.start, 8, 10);
      await pickTime(tester, tr.end, 8, 32);
      for (final field in [tr.placeFrom, tr.placeTo]) {
        await tester.tap(find.text(field));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(FlutterMap), const Offset(0, -150));
        await tester.pump(const Duration(seconds: 1));
        await tester.tap(find.text(tr.pickThisPlace));
        await tester.pumpAndSettle();
      }
      await tester.enterText(find.byType(TextField).at(0), '2400');
      await tester.enterText(find.byType(TextField).at(1), '360');
      await tester.tap(find.text(tr.save));
      await tester.pumpAndSettle();
      expect(find.text(tr.errOutsideArea), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('trip details', () {
    Future<void> openDetails(
      WidgetTester tester,
      FakeTripsRepository repo,
      Trip trip,
    ) async {
      useDevice(tester, phone390);
      await pumpDiary(
        tester,
        repo,
        home: TripDetailsScreen(tripId: trip.id, initial: trip),
      );
      await tester.pump();
    }

    testWidgets('ready: the route, the stats, both places; ORS credited', (
      tester,
    ) async {
      await openDetails(tester, FakeTripsRepository([mapT1]), mapT1);
      expect(find.byType(DkRouteLayer), findsOneWidget);
      final line = tester
          .widget<DkRouteLayer>(find.byType(DkRouteLayer))
          .routes
          .single;
      expect(line.straight, isFalse);
      expect(find.text('7,2 км'), findsOneWidget);
      expect(find.text(DkMoney.format(333)), findsOneWidget); // per km
      expect(
        find.text(DkMoney.format(109)),
        findsOneWidget,
      ); // per minute: 2400 / 22
      expect(find.text('Зелёный базар'), findsOneWidget);
      expect(find.text('ТРЦ Есентай Молл'), findsOneWidget);
      expect(
        find.text('© OpenStreetMap · © openrouteservice.org by HeiGIT'),
        findsOneWidget,
      );
      expect(find.text(tr.routeStraightInfo), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('straight: dashed, the info row; «Построить заново» builds '
        'it again', (tester) async {
      final repo = FakeTripsRepository([mapT1Straight])
        ..onRebuild = (_) async => Ok(mapT1);
      await openDetails(tester, repo, mapT1Straight);
      final line = tester
          .widget<DkRouteLayer>(find.byType(DkRouteLayer))
          .routes
          .single;
      expect(line.straight, isTrue);
      expect(find.text(tr.routeStraightInfo), findsOneWidget);
      // A straight line is not ORS's: only the tiles are credited.
      expect(find.text('© OpenStreetMap'), findsOneWidget);

      repo
        ..trips.clear()
        ..trips.add(mapT1);
      await tester.tap(find.text(tr.routeRebuild));
      await tester.pumpAndSettle();
      expect(repo.rebuilt, ['t1']);
      expect(find.text(tr.routeStraightInfo), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('pending: markers without a line, distance unknown', (
      tester,
    ) async {
      await openDetails(
        tester,
        FakeTripsRepository([mapT2Pending]),
        mapT2Pending,
      );
      expect(find.byType(DkRouteLayer), findsNothing);
      expect(find.byType(DkPlaceMarkers), findsOneWidget);
      expect(find.text('—'), findsNWidgets(2)); // distance, per km
      await disposeApp(tester);
    });

    testWidgets('a trip without places: no map', (tester) async {
      await openDetails(tester, FakeTripsRepository([t1]), t1);
      expect(find.byType(DkMapView), findsNothing);
      expect(find.byType(DkRouteStats), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('loading, then an error with retry', (tester) async {
      final repo = FakeTripsRepository()
        ..onTripById = (_) async => const Err(NetworkFailure());
      useDevice(tester, phone390);
      await pumpDiary(
        tester,
        repo,
        home: const TripDetailsScreen(tripId: 't1'),
      );
      expect(find.byType(DkSkeleton), findsWidgets);
      await tester.pumpAndSettle();
      expect(find.text(tr.loadFailedTitle), findsOneWidget);

      repo.onTripById = (_) async => Ok(mapT1);
      await tester.tap(find.text(tr.retry));
      await tester.pumpAndSettle();
      expect(find.text('Зелёный базар'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('the attribution opens the full credits', (tester) async {
      await openDetails(tester, FakeTripsRepository([mapT1]), mapT1);
      await tester.tap(
        find.text('© OpenStreetMap · © openrouteservice.org by HeiGIT'),
      );
      await tester.pumpAndSettle();
      expect(find.text(tr.mapCredits), findsOneWidget);
      expect(
        find.textContaining('openstreetmap.org/copyright'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Routes and addresses: © openrouteservice.org'),
        findsOneWidget,
      );
      await disposeApp(tester);
    });
  });

  group('day', () {
    testWidgets('rows with places open their details; others do not', (
      tester,
    ) async {
      final plain = trip(id: 'plain', start: at(13, 40));
      useDevice(tester, phone390);
      await pumpDiary(tester, FakeTripsRepository([mapT1, mapT2, plain]));
      await selectDay(tester, referenceDay);

      expect(find.text('Зелёный базар → ТРЦ Есентай Молл'), findsOneWidget);
      final tiles = tester
          .widgetList<DkTripTile>(find.byType(DkTripTile))
          .toList();
      expect(tiles.map((t) => t.onTap != null), [true, true, false]);

      await tester.tap(find.text('Зелёный базар → ТРЦ Есентай Молл'));
      await tester.pumpAndSettle();
      expect(find.byType(TripDetailsScreen), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('«Карта дня» only when a trip has places', (tester) async {
      useDevice(tester, phone390);
      await pumpDiary(tester, FakeTripsRepository([t1, t2]));
      await selectDay(tester, referenceDay);
      expect(find.bySemanticsLabel(tr.dayMap), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('the day map: numbered routes; one marker where a trip '
        'starts at the previous end', (tester) async {
      useDevice(tester, phone390);
      await pumpDiary(tester, FakeTripsRepository([mapT1, mapT2]));
      await selectDay(tester, referenceDay);
      await tester.tap(iconButton(tr.dayMap));
      await tester.pumpAndSettle();

      expect(find.byType(DayMapScreen), findsOneWidget);
      final routes = tester
          .widget<DkRouteLayer>(find.byType(DkRouteLayer))
          .routes;
      expect(routes.map((r) => r.id), ['t1', 't2']);
      final markers = tester
          .widget<DkPlaceMarkers>(find.byType(DkPlaceMarkers))
          .markers;
      // t1 ends at ТРЦ Есентай Молл, where t2 starts: one marker («2»)
      // there, no dot under it; t2's end is a dot.
      expect(markers.map((m) => m.marker.dot ? 'dot' : '${m.marker.number}'), [
        'dot',
        '1',
        '2',
      ]);
      expect(markers.last.marker.number, 2);
      expect(find.text(tr.routesCount(2)), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('a row selects its route (map fits to it); again clears; '
        'the button opens the trip', (tester) async {
      final semantics = tester.ensureSemantics();
      useDevice(tester, phone390);
      await pumpDiary(tester, FakeTripsRepository([mapT1, mapT2]));
      await selectDay(tester, referenceDay);
      await tester.tap(iconButton(tr.dayMap));
      await tester.pumpAndSettle();
      final allFit = tester.widget<DkMapView>(find.byType(DkMapView)).fit;
      expect(
        find.bySemanticsLabel(RegExp('^${tr.routeOf(2, 2)}')),
        findsOneWidget,
      );

      await tester.tap(find.text('ТРЦ Есентай Молл → Площадь Республики'));
      await tester.pumpAndSettle();
      final layer = tester.widget<DkRouteLayer>(find.byType(DkRouteLayer));
      expect(layer.selected, 't2');
      final fit = tester.widget<DkMapView>(find.byType(DkMapView)).fit;
      expect(fit.length, lessThan(allFit.length));
      final rows = tester.widgetList<DkListRow>(find.byType(DkListRow));
      expect(rows.map((r) => r.selected), [false, true]);

      // Tapping the selected route on the map clears it too.
      layer.onTap!('t2');
      await tester.pumpAndSettle();
      expect(
        tester.widget<DkRouteLayer>(find.byType(DkRouteLayer)).selected,
        isNull,
      );

      await tester.tap(
        find
            .byWidgetPredicate(
              (w) => w is DkIconButton && w.label == tr.openTrip,
            )
            .last,
      );
      await tester.pumpAndSettle();
      expect(find.byType(TripDetailsScreen), findsOneWidget);
      expect(find.text('Площадь Республики'), findsOneWidget);
      await disposeApp(tester);
      semantics.dispose();
    });

    testWidgets('admin: the day map follows the driver filter', (tester) async {
      final repo = FakeTripsRepository([mapT1, mapT2, mapU2t1, mapU2t2]);
      final admin = FakeAdminRepository();
      useDevice(tester, phone390);
      await pumpDiary(tester, repo, user: adminUser, admin: admin);
      await selectDay(tester, referenceDay);
      await tester.pumpAndSettle();
      await tester.tap(find.text(driver2.displayName).first);
      await tester.pumpAndSettle();
      await tester.tap(iconButton(tr.dayMap));
      await tester.pumpAndSettle();

      final routes = tester
          .widget<DkRouteLayer>(find.byType(DkRouteLayer))
          .routes;
      expect(routes.map((r) => r.id), ['u2-t1', 'u2-t2']);
      expect(find.textContaining(driver2.displayName), findsWidgets);
      expect(repo.driverFilters, contains(driver2.id));
      await disposeApp(tester);
    });
  });
}
