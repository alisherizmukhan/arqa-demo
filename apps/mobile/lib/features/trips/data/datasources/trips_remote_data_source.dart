import 'package:dio/dio.dart';
import 'package:driver_diary/core/network/guard.dart';
import 'package:driver_diary/core/network/retry_interceptor.dart';
import 'package:driver_diary/features/trips/data/dto/trip_dtos.dart';

/// HTTP calls to the trips API. Throws `DioException`/`FormatException`;
/// the repository maps them to failures.
class TripsRemoteDataSource {
  const new(this._dio);

  final Dio _dio;

  /// [driverId]: admin only, one driver (null: own trips, or all drivers
  /// for an admin).
  Future<DayTripsDto> fetchDay({
    required String date,
    required String tz,
    String? driverId,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/trips',
      queryParameters: {'date': date, 'tz': tz, 'driver_id': ?driverId},
    );
    return DayTripsDto.fromJson(bodyOf(response));
  }

  /// Not retried by dio: the form retries on a visible schedule instead.
  Future<TripDto> createTrip(CreateTripRequestDto request) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/trips',
      data: request.toJson(),
      options: Options(extra: RetryInterceptor.disabled),
    );
    return TripDto.fromJson(bodyOf(response));
  }
}
