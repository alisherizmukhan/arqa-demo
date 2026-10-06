import 'package:dio/dio.dart';

/// Retries requests that failed for transient reasons: no connection,
/// timeouts, and 502/503/504.
///
/// A request opts out with `Options(extra: RetryInterceptor.disabled)`.
/// Trip creation does: the add-trip form runs its own visible schedule
/// (2/4/8/30 s, DESIGN.md §5.9) with the same trip id, and silent retries
/// here would only delay the «Нет связи» snackbar.
class RetryInterceptor extends Interceptor {
  new(
    this._dio, {
    this.delays = const [Duration(milliseconds: 500), Duration(seconds: 2)],
  });

  final Dio _dio;

  /// Wait before each retry; its length is the number of retries.
  final List<Duration> delays;

  static const _attemptKey = 'retry_attempt';
  static const _disabledKey = 'retry_disabled';

  /// `Options.extra` for a request that must not be retried here.
  static const Map<String, Object?> disabled = {_disabledKey: true};
  static const _retryableStatuses = {502, 503, 504};

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_attemptKey] as int?) ?? 0;
    if (options.extra[_disabledKey] == true ||
        !_isTransient(err) ||
        attempt >= delays.length) {
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
