import 'dart:async';

import 'package:dio/dio.dart';

/// The session token sent with requests, and the signal that the server no
/// longer accepts it. Shared by the HTTP client and the session, so neither
/// depends on the other.
class AuthGate {
  /// The bearer token; null when signed out. Kept in memory only (the
  /// secure store has the persisted copy) and never logged.
  String? token;

  final _expired = StreamController<void>.broadcast(sync: true);

  /// Fires when a request with the current token got a 401.
  Stream<void> get expired => _expired.stream;

  void _reportExpired() => _expired.add(null);

  Future<void> dispose() => _expired.close();
}

/// Adds `Authorization: Bearer <token>` and reports a 401 to [AuthGate].
///
/// A request opts out of the report with `Options(extra:
/// AuthInterceptor.quiet)`: the logout call, whose 401 only means the session
/// is already gone.
class AuthInterceptor extends Interceptor {
  new(this._gate);

  final AuthGate _gate;

  static const _sentTokenKey = 'auth_token_sent';
  static const _quietKey = 'auth_quiet';

  /// `Options.extra` for a request whose 401 must not end the session.
  static const Map<String, Object?> quiet = {_quietKey: true};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _gate.token;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      options.extra[_sentTokenKey] = token;
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    final sent = options.extra[_sentTokenKey];
    // Only a 401 for the token in use: a late answer to a request sent with
    // an older session must not end the new one.
    if (err.response?.statusCode == 401 &&
        options.extra[_quietKey] != true &&
        sent != null &&
        sent == _gate.token) {
      _gate._reportExpired();
    }
    handler.next(err);
  }
}
