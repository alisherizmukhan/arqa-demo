// DESIGN.md §9.1: markers sit on the stored place points; a route line that
// starts or ends more than 30 m away (the routing engine snaps to a road)
// gets a dashed connector, and every screen draws the same geometry.

import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/features/trips/domain/entities/place.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/domain/entities/trip_route.dart';
import 'package:driver_diary/features/trips/presentation/screens/day_map_screen.dart';
import 'package:driver_diary/features/trips/presentation/screens/trip_details_screen.dart';
import 'package:driver_diary/features/trips/presentation/widgets/trip_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/fixtures.dart';
import '../../../helpers/map_fixtures.dart';

const _distance = Distance();

double _metres(LatLng a, GeoPoint b) =>
    _distance.as(LengthUnit.Meter, a, LatLng(b.lat, b.lng));

/// The drawn geometry's first and last point: the connector's outer end
/// where there is one, else the line's own end.
({LatLng start, LatLng end}) _drawnEnds(DkRoute route, Trip trip) {
  var start = route.points.first;
  var end = route.points.last;
  for (final c in route.connectors) {
    if (_metres(c.first, trip.pickup!.point) <= connectorMetres) {
      start = c.first;
    }
    if (_metres(c.last, trip.dropoff!.point) <= connectorMetres) end = c.last;
  }
  return (start: start, end: end);
}

void main() {
  final trips = {
    'mapT1': mapT1,
    'mapT2': mapT2,
    'mapU2t1': mapU2t1,
    'mapU2t2': mapU2t2,
    'mapT1Straight': mapT1Straight,
  };

  for (final MapEntry(key: name, value: trip) in trips.entries) {
    test('$name: the drawn route reaches both place points (≤ 30 m)', () {
      final route = dkRouteOf(trip)!;
      final ends = _drawnEnds(route, trip);
      expect(_metres(ends.start, trip.pickup!.point), lessThanOrEqualTo(30));
      expect(_metres(ends.end, trip.dropoff!.point), lessThanOrEqualTo(30));
      // A connector only where the line itself ends farther than 30 m.
      final startGap = _metres(route.points.first, trip.pickup!.point);
      final endGap = _metres(route.points.last, trip.dropoff!.point);
      expect(
        route.connectors.length,
        [startGap, endGap].where((g) => g > connectorMetres).length,
      );
    });
  }

  test('a line that starts far from its place gets a connector from the '
      'place point', () {
    final snapped = mapT1.withRoute(
      // The real t1 polyline, as if its start were snapped 200 m away.
      TripRoute(
        status: RouteStatus.ready,
        distanceMetres: 7496,
        polyline: mapT1.route.polyline,
      ),
    );
    final moved = Trip(
      id: snapped.id,
      start: snapped.start,
      end: snapped.end,
      amount: snapped.amount,
      payment: snapped.payment,
      commission: snapped.commission,
      pickup: const Place(point: GeoPoint(43.2645, 76.9552), label: 'x'),
      dropoff: snapped.dropoff,
      route: snapped.route,
    );
    final route = dkRouteOf(moved)!;
    // t1's real line also ends 55 m from ТРЦ Есентай Молл: two connectors.
    expect(route.connectors, hasLength(2));
    final start = route.connectors.first;
    expect(start.first, const LatLng(43.2645, 76.9552));
    expect(start.last, route.points.first);
  });

  testWidgets('Trip details and the day map draw the same geometry', (
    tester,
  ) async {
    useDevice(tester, phone390);
    await pumpDiary(
      tester,
      FakeTripsRepository([mapT1, mapT2]),
      home: TripDetailsScreen(tripId: mapT1.id, initial: mapT1),
    );
    await tester.pump();
    final details = tester
        .widget<DkRouteLayer>(find.byType(DkRouteLayer))
        .routes
        .single;
    await disposeApp(tester);

    await pumpDiary(
      tester,
      FakeTripsRepository([mapT1, mapT2]),
      home: DayMapScreen(day: referenceDay),
    );
    await tester.pumpAndSettle();
    final onDayMap = tester
        .widget<DkRouteLayer>(find.byType(DkRouteLayer))
        .routes
        .firstWhere((r) => r.id == mapT1.id);
    expect(onDayMap.points, details.points);
    expect(onDayMap.connectors, details.connectors);
    await disposeApp(tester);
  });
}
