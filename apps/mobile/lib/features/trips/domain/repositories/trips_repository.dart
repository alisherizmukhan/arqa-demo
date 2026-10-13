import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/time/calendar_day.dart';
import 'package:driver_diary/core/time/driver_zone.dart';
import 'package:driver_diary/features/trips/domain/entities/place.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';

abstract interface class TripsRepository {
  /// Trips that started on [day] in [zone], ordered by start: the driver's
  /// own, or (admin) all drivers' or one driver's ([driverId]).
  Future<Result<List<Trip>>> tripsForDay(
    CalendarDay day,
    DriverZone zone, {
    String? driverId,
  });

  /// Creates [trip] idempotently: the same id with the same payload is not a
  /// duplicate, so a retry after a network error is safe.
  Future<Result<Trip>> createTrip(Trip trip, DriverZone zone);

  /// One trip with its places and route: the driver's own, or any (admin).
  Future<Result<Trip>> tripById(String id, DriverZone zone);

  /// Builds the trip's route again (after a straight-line fallback).
  Future<Result<Trip>> rebuildRoute(String id, DriverZone zone);
}

/// Address lookups for the place picker (the server asks the map service).
abstract interface class GeoRepository {
  /// The address of [point]; null when nothing is near.
  Future<Result<String?>> reverse(GeoPoint point);

  /// Up to 5 places in Almaty matching [query] (at least 3 characters).
  Future<Result<List<GeoPlace>>> search(String query);
}
