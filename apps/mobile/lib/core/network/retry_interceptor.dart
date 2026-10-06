import 'package:dio/dio.dart';

/// Retries requests that failed for transient reasons: no connection,
/// timeouts, and 502/503/504.
///
/// POST is retried too. That is safe only because trip creation is
/// idempotent: the retry re-sends the *same* request body, so the same trip
/// id, and the server answers 200 with the stored trip instead of creating a
/// duplicate.
class RetryInterceptor extends Interceptor {
  new(
    this._dio, {
    this.delays = const [Duration(milliseconds: 500), Duration(seconds: 2)],
  });

  final Dio _dio;

  /// Wait before each retry; its length is the number of retries.
  final List<Duration> delays;

  static const _attemptKey = 'retry_attempt';
  static const _retryableStatuses = {502, 503, 504};

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_attemptKey] as int?) ?? 0;
    if (!_isTransient(err) || attempt >= delays.length) {
      handler.next(err);
      return;
    }
    await Future<void>.delayed(delays[attempt]);
    options.extra[_attemptKey] = attempt + 1;
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  static bool _isTransient(DioException err) => switch (err.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => true,
    DioExceptionType.badResponse => _retryableStatuses.contains(
      err.response?.statusCode,
    ),
    _ => false,
  };
}
