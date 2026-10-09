/// Everything that can go wrong, as a closed set the UI can switch over.
///
/// Implements [Exception] so a provider can throw it into an `AsyncError`.
sealed class Failure implements Exception {
  const new(this.message);

  /// Short name for logs, e.g. `NetworkFailure`.
  String get kind;

  /// Developer-facing description (the UI shows its own localized text).
  final String message;

  @override
  String toString() => '$kind: $message';
}

/// No connection or timed out, after retries. The request may or may not have
/// reached the server, so a create must be retried with the same trip id.
final class NetworkFailure extends Failure {
  const new([super.message = 'network unavailable']);

  @override
  String get kind => 'NetworkFailure';
}

/// The server rejected input (HTTP 422) or client-side validation failed.
final class ValidationFailure extends Failure {
  const new({required this.code, required String message, this.field})
    : super(message);

  /// Stable server/domain code, e.g. `commission_exceeds_amount`.
  final String code;

  /// Offending field, e.g. `commission`.
  final String? field;

  @override
  String get kind => 'ValidationFailure';
}

/// The id already exists with a different payload, or the state changed
/// (HTTP 409). [code]: `trip_conflict`, `withdrawal_conflict`,
/// `withdrawal_already_decided`, `demo_account_protected`.
final class ConflictFailure extends Failure {
  const new([
    super.message = 'trip already exists with different data',
    this.code = 'trip_conflict',
  ]);

  final String code;

  @override
  String get kind => 'ConflictFailure';
}

/// No valid session (HTTP 401): missing, revoked or unknown token, or
/// wrong credentials at login ([code] `invalid_credentials`).
final class UnauthorizedFailure extends Failure {
  const new({this.code = 'unauthorized', String message = 'unauthorized'})
    : super(message);

  final String code;

  @override
  String get kind => 'UnauthorizedFailure';
}

/// Signed in, but not allowed (HTTP 403); [code] `account_disabled` at
/// login for a blocked account.
final class ForbiddenFailure extends Failure {
  const new({this.code = 'forbidden', String message = 'forbidden'})
    : super(message);

  final String code;

  @override
  String get kind => 'ForbiddenFailure';
}

/// Too many failed logins (HTTP 429).
final class RateLimitedFailure extends Failure {
  const new([super.message = 'rate limited']);

  @override
  String get kind => 'RateLimitedFailure';
}

/// The server failed (5xx) or answered unexpectedly.
final class ServerFailure extends Failure {
  const new({required this.statusCode, String message = 'server error'})
    : super(message);

  final int? statusCode;

  @override
  String get kind => 'ServerFailure';
}

/// A bug or an unreadable response.
final class UnexpectedFailure extends Failure {
  const new([super.message = 'unexpected error']);

  @override
  String get kind => 'UnexpectedFailure';
}
