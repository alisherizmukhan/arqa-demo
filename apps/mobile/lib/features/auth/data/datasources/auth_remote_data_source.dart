import 'package:dio/dio.dart';
import 'package:driver_diary/core/network/auth_interceptor.dart';
import 'package:driver_diary/core/network/guard.dart';
import 'package:driver_diary/core/network/retry_interceptor.dart';
import 'package:driver_diary/features/auth/data/dto/auth_dtos.dart';

/// HTTP calls to `/auth`. Throws `DioException`/`FormatException`.
class AuthRemoteDataSource {
  const new(this._dio);

  final Dio _dio;

  /// Not retried: a wrong password must not count as several attempts.
  Future<LoginResponseDto> login(String login, String password) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/auth/login',
      data: {'login': login, 'password': password},
      options: Options(extra: RetryInterceptor.disabled),
    );
    return LoginResponseDto.fromJson(bodyOf(response));
  }

  Future<UserDto> me() async {
    final response = await _dio.get<Map<String, Object?>>('/auth/me');
    return UserDto.fromJson(bodyOf(response));
  }

  /// A 401 here only means the session is already gone (no "session
  /// ended" signal).
  Future<void> logout() => _dio.post<void>(
    '/auth/logout',
    options: Options(extra: {...AuthInterceptor.quiet}),
  );
}
