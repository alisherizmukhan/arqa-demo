import 'package:driver_diary/features/trips/domain/entities/place.dart';
import 'package:driver_diary/features/trips/domain/entities/trip_route.dart';
import 'package:meta/meta.dart';

/// How the passenger paid.
enum PaymentMethod { cash, card }

/// A trip. Money is whole tenge (`int`); [start]/[end] are UTC instants.
@immutable
final class Trip {
  const new({
    required this.id,
    required this.start,
    required this.end,
    required this.amount,
    required this.payment,
    required this.commission,
    this.driverId,
    this.pickup,
    this.dropoff,
    this.route = TripRoute.none,
  });

  /// Client-generated UUID v4; doubles as the idempotency key.
  final String id;
  final DateTime start;
  final DateTime end;
  final int amount;
  final PaymentMethod payment;
  final int commission;

  /// The driver's user id (from the server; null for a trip not sent yet).
  /// Not part of the payload.
  final String? driverId;

  /// Where the trip started and ended (DESIGN.md §9): both or neither.
  /// Part of the payload.
  final Place? pickup;
  final Place? dropoff;

  /// Built by the server; not part of the payload.
  final TripRoute route;

  int get net => amount - commission;

  bool get hasPlaces => pickup != null && dropoff != null;

  Duration get duration => end.difference(start);

  /// Everything but the id and the route; instants compare by moment, not
  /// by notation. The places are payload, as on the server.
  bool hasSamePayload(Trip other) =>
      start.isAtSameMomentAs(other.start) &&
      end.isAtSameMomentAs(other.end) &&
      amount == other.amount &&
      payment == other.payment &&
      commission == other.commission &&
      pickup == other.pickup &&
      dropoff == other.dropoff;

  Trip withId(String newId) => Trip(
    id: newId,
    start: start,
    end: end,
    amount: amount,
    payment: payment,
    commission: commission,
    driverId: driverId,
    pickup: pickup,
    dropoff: dropoff,
    route: route,
  );

  /// The same trip with the route the server built.
  Trip withRoute(TripRoute newRoute) => Trip(
    id: id,
    start: start,
    end: end,
    amount: amount,
    payment: payment,
    commission: commission,
    driverId: driverId,
    pickup: pickup,
    dropoff: dropoff,
    route: newRoute,
  );

  @override
  bool operator ==(Object other) =>
      other is Trip && other.id == id && hasSamePayload(other);

  @override
  int get hashCode => Object.hash(
    id,
    start.toUtc(),
    end.toUtc(),
    amount,
    payment,
    commission,
    pickup,
    dropoff,
  );

  @override
  String toString() =>
      'Trip($id, ${start.toUtc().toIso8601String()}, $amount ${payment.name})';
}
