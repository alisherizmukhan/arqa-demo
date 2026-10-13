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

  /// One trip with its places and route (`GET /trips/{id}`).
  Future<TripDto> fetchTrip(String id, {required String tz}) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/trips/${Uri.encodeComponent(id)}',
      queryParameters: {'tz': tz},
    );
    return TripDto.fromJson(bodyOf(response));
  }

  /// Builds the trip's route again (`POST /trips/{id}/route`).
  Future<TripDto> rebuildRoute(String id, {required String tz}) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/trips/${Uri.encodeComponent(id)}/route',
      queryParameters: {'tz': tz},
      options: Options(extra: RetryInterceptor.disabled),
    );
    return TripDto.fromJson(bodyOf(response));
  }

  /// The address of a point (`GET /geo/reverse`).
  Future<GeoLabelDto> reverse({
    required double lat,
    required double lng,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/geo/reverse',
      queryParameters: {'lat': lat, 'lng': lng},
      options: Options(extra: RetryInterceptor.disabled),
    );
    return GeoLabelDto.fromJson(bodyOf(response));
  }

  /// Places matching [query] (`GET /geo/search`).
  Future<GeoSearchDto> search(String query) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/geo/search',
      queryParameters: {'q': query},
      options: Options(extra: RetryInterceptor.disabled),
    );
    return GeoSearchDto.fromJson(bodyOf(response));
  }
}
