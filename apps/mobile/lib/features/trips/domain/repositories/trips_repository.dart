import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/time/calendar_day.dart';
import 'package:driver_diary/core/time/driver_zone.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';

abstract interface class TripsRepository {
  /// Trips that started on [day] in [zone], ordered by start.
  Future<Result<List<Trip>>> tripsForDay(CalendarDay day, DriverZone zone);

  /// Creates [trip] idempotently: the same id with the same payload is not a
  /// duplicate, so a retry after a network error is safe.
  Future<Result<Trip>> createTrip(Trip trip, DriverZone zone);
}
