/// Everything that can go wrong, as a closed set the UI can switch over.
///
/// Implements [Exception] so a provider can throw it into an `AsyncError`.
sealed class Failure implements Exception {
  const new(this.message);

  /// Short name for logs, e.g. `NetworkFailure`.
  String get kind;

  /// Developer-facing description (the UI shows its own Russian text).
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

/// The trip id already exists with a different payload (HTTP 409).
final class ConflictFailure extends Failure {
  const new([super.message = 'trip already exists with different data']);

  @override
  String get kind => 'ConflictFailure';
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
