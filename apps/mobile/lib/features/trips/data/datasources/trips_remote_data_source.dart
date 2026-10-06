import 'package:dio/dio.dart';
import 'package:driver_diary/features/trips/data/dto/trip_dtos.dart';

/// HTTP calls to the trips API. Throws `DioException`/`FormatException`;
/// the repository maps them to failures.
class TripsRemoteDataSource {
  const new(this._dio);

  final Dio _dio;

  Future<DayTripsDto> fetchDay({
    required String date,
    required String tz,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/trips',
      queryParameters: {'date': date, 'tz': tz},
    );
    return DayTripsDto.fromJson(_body(response));
  }

  Future<TripDto> createTrip(CreateTripRequestDto request) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/trips',
      data: request.toJson(),
    );
    return TripDto.fromJson(_body(response));
  }

  Map<String, Object?> _body(Response<Map<String, Object?>> response) =>
      response.data ?? (throw const FormatException('empty response body'));
}
