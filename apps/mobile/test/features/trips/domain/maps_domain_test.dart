import 'package:driver_diary/features/trips/data/dto/trip_dtos.dart';
import 'package:driver_diary/features/trips/domain/entities/place.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/domain/entities/trip_route.dart';
import 'package:driver_diary/features/trips/domain/entities/trip_rules.dart';
import 'package:driver_diary/features/trips/domain/polyline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fixtures.dart';
import '../../../helpers/map_fixtures.dart';

void main() {
  group('decodePolyline', () {
    test("Google's reference example", () {
      expect(decodePolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@'), const [
        GeoPoint(38.5, -120.2),
        GeoPoint(40.7, -120.95),
        GeoPoint(43.252, -126.453),
      ]);
    });

    test('a real route starts and ends at its places', () {
      final points = decodePolyline(bazaarToEsentai.polyline!);
      expect(points.length, greaterThan(20));
      expect(points.first.lat, closeTo(bazaar.point.lat, 0.002));
      expect(points.last.lat, closeTo(esentai.point.lat, 0.002));
    });

    test('the server straight line is two points', () {
      expect(mapT1Straight.route.points, [bazaar.point, esentai.point]);
    });

    for (final bad in ['_p~iF~ps|U_', '_p~iF', 'abc def']) {
      test('rejects "$bad"', () {
        expect(() => decodePolyline(bad), throwsFormatException);
      });
    }

    test('an unreadable stored polyline draws nothing', () {
      const route = TripRoute(status: RouteStatus.ready, polyline: '_p~iF');
      expect(route.points, isEmpty);
      expect(route.hasLine, isFalse);
    });
  });

  group('places in the payload', () {
    test('places are compared, the route is not', () {
      expect(mapT1.hasSamePayload(mapT1Straight), isTrue);
      expect(mapT1.hasSamePayload(t1), isFalse);
      final relabelled = mapT1
          .withId('t1')
          .hasSamePayload(
            Trip(
              id: 'x',
              start: t1.start,
              end: t1.end,
              amount: t1.amount,
              payment: t1.payment,
              commission: t1.commission,
              pickup: bazaar,
              dropoff: const Place(point: GeoPoint(43.2185, 76.928)),
            ),
          );
      expect(relabelled, isFalse);
    });

    test('both places or neither', () {
      expect(validatePlaces(null, null), isEmpty);
      expect(validatePlaces(bazaar, esentai), isEmpty);
      expect(validatePlaces(bazaar, null), [TripRuleViolation.incompleteRoute]);
      expect(validatePlaces(null, esentai), [
        TripRuleViolation.incompleteRoute,
      ]);
      expect(TripRuleViolation.incompleteRoute.field, TripField.places);
    });

    test('a place without an address shows its coordinates', () {
      const place = Place(point: GeoPoint(43.23801, 76.94549));
      expect(place.displayLabel, '43.2380, 76.9455');
      expect(bazaar.displayLabel, 'Зелёный базар');
    });
  });

  group('DTOs', () {
    test('a trip without places sends no place keys (old servers reject '
        'unknown fields)', () {
      final json = CreateTripRequestDto.fromDomain(t1, kz).toJson();
      expect(json.containsKey('pickup'), isFalse);
      expect(json.containsKey('dropoff'), isFalse);
    });

    test('a trip with places sends them, never the route', () {
      final json = CreateTripRequestDto.fromDomain(mapT1, kz).toJson();
      expect((json['pickup']! as PlaceDto).toJson(), {
        'lat': 43.26275,
        'lng': 76.95519,
        'label': 'Зелёный базар',
      });
      expect(json.containsKey('route'), isFalse);
    });

    test('reads places and the route', () {
      final trip = TripDto.fromJson({
        'id': 't1',
        'start': '2026-10-01T08:10:00+05:00',
        'end': '2026-10-01T08:32:00+05:00',
        'amount': 2400,
        'payment': 'card',
        'commission': 360,
        'driver_id': 'u1',
        'pickup': {'lat': 43.26275, 'lng': 76.95519, 'label': 'Зелёный базар'},
        'dropoff': {'lat': 43.2185, 'lng': 76.928, 'label': null},
        'route': {
          'status': 'straight',
          'polyline': 'ew`gG}hutMpsG|hD',
          'distance_m': 5391,
          'duration_s': null,
        },
      }).toDomain();

      expect(trip.pickup, bazaar);
      expect(trip.dropoff, const Place(point: GeoPoint(43.2185, 76.928)));
      expect(trip.route.status, RouteStatus.straight);
      expect(trip.route.distanceMetres, 5391);
      expect(trip.route.hasLine, isTrue);
    });

    test('an old server answer (no places, no route) is a trip without '
        'places', () {
      final trip = TripDto.fromJson({
        'id': 't1',
        'start': '2026-10-01T08:10:00+05:00',
        'end': '2026-10-01T08:32:00+05:00',
        'amount': 2400,
        'payment': 'card',
        'commission': 360,
      }).toDomain();
      expect(trip.hasPlaces, isFalse);
      expect(trip.route, TripRoute.none);
    });

    test('an unknown route status draws nothing', () {
      expect(RouteStatus.parse('detour'), RouteStatus.none);
    });
  });
}
