import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/time/driver_zone.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/domain/entities/trip_rules.dart';
import 'package:driver_diary/features/trips/domain/repositories/trips_repository.dart';

/// Validates locally, then creates the trip on the server.
///
/// Retrying after a [NetworkFailure] must reuse the same `trip.id`: the server
/// then returns the stored trip instead of creating a duplicate.
final class CreateTrip {
  const new(this._repository);

  final TripsRepository _repository;

  Future<Result<Trip>> call(Trip trip, DriverZone zone) async {
    final violations = validateTrip(trip);
    if (violations.isNotEmpty) {
      final first = violations.first;
      return Err(
        ValidationFailure(
          code: first.code,
          message: 'client-side validation failed',
          field: first.field.name,
        ),
      );
    }
    return await _repository.createTrip(trip, zone);
  }
}
