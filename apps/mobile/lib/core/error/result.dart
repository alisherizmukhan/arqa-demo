import 'package:driver_diary/core/error/failure.dart';

/// Outcome of a use case: a value or a [Failure]. Exhaustive via `switch`.
sealed class Result<T> {
  const new();
}

/// Success.
final class Ok<T> extends Result<T> {
  const new(this.value);

  final T value;
}

/// Failure.
final class Err<T> extends Result<T> {
  const new(this.failure);

  final Failure failure;
}
