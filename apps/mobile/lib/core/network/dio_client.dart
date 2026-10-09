import 'package:dio/dio.dart';
import 'package:driver_diary/core/config/app_config.dart';
import 'package:driver_diary/core/network/auth_interceptor.dart';
import 'package:driver_diary/core/network/retry_interceptor.dart';

/// Dio with timeouts, the session token ([gate]) and automatic retries of
/// transient failures.
Dio createDio(AppConfig config, AuthGate gate) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  dio.interceptors
    ..add(AuthInterceptor(gate))
    ..add(RetryInterceptor(dio));
  return dio;
}
