import 'package:dio/dio.dart';
import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/network/failure_mapper.dart';
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
  Future<Result<List<Trip>>> tripsForDay(CalendarDay day, DriverZone zone) =>
      _guard(() async {
        final dto = await _remote.fetchDay(
          date: day.toIso(),
          tz: zone.isoOffset,
        );
        return [for (final trip in dto.trips) trip.toDomain()];
      });

  @override
  Future<Result<Trip>> createTrip(Trip trip, DriverZone zone) => _guard(
    () async =>
        (await _remote.createTrip(CreateTripRequestDto.fromDomain(trip, zone)))
            .toDomain(),
  );

  Future<Result<T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Ok(await call());
    } on DioException catch (error) {
      return Err(failureFromDio(error));
    } on FormatException catch (error) {
      return Err(UnexpectedFailure('unreadable response: ${error.message}'));
      // Generated fromJson casts fields (`as String`); a response of the wrong
      // shape surfaces as a TypeError, which is data, not a bug in this app.
      // ignore: avoid_catching_errors
    } on TypeError catch (error) {
      return Err(UnexpectedFailure('unexpected response shape: $error'));
    }
  }
}
