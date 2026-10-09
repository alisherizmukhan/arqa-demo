import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/network/guard.dart';
import 'package:driver_diary/core/time/calendar_day.dart';
import 'package:driver_diary/core/time/driver_zone.dart';
import 'package:driver_diary/features/trips/data/datasources/trips_remote_data_source.dart';
import 'package:driver_diary/features/trips/data/dto/trip_dtos.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/domain/repositories/trips_repository.dart';

final class TripsRepositoryImpl implements TripsRepository {
  const new(this._remote);

  final TripsRemoteDataSource _remote;

  @override
  Future<Result<List<Trip>>> tripsForDay(
    CalendarDay day,
    DriverZone zone, {
    String? driverId,
  }) => guardRequest(() async {
    final dto = await _remote.fetchDay(
      date: day.toIso(),
      tz: zone.isoOffset,
      driverId: driverId,
    );
    return [for (final trip in dto.trips) trip.toDomain()];
  });

  @override
  Future<Result<Trip>> createTrip(Trip trip, DriverZone zone) => guardRequest(
    () async =>
        (await _remote.createTrip(CreateTripRequestDto.fromDomain(trip, zone)))
            .toDomain(),
  );
}
