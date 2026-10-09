import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/time/calendar_day.dart';
import 'package:driver_diary/core/time/driver_zone.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/domain/repositories/trips_repository.dart';

/// Trips of one local day, ordered by start.
final class GetDayTrips {
  const new(this._repository);

  final TripsRepository _repository;

  Future<Result<List<Trip>>> call(
    CalendarDay day,
    DriverZone zone, {
    String? driverId,
  }) => _repository.tripsForDay(day, zone, driverId: driverId);
}
