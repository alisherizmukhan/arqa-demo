import 'package:dio/dio.dart';
import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/network/failure_mapper.dart';

/// Runs an API call and turns its errors into a [Failure]: dio errors by
/// status and error code, unreadable bodies as [UnexpectedFailure].
Future<Result<T>> guardRequest<T>(Future<T> Function() call) async {
  try {
    return Ok(await call());
  } on DioException catch (error) {
    return Err(failureFromDio(error));
  } on FormatException catch (error) {
    return Err(UnexpectedFailure('unreadable response: ${error.message}'));
    // Generated fromJson casts fields (`as String`); a response of the wrong
    // shape surfaces as a TypeError, which is data, not a bug in this app.
    // ignore: avoid_catching_errors
  } on TypeError catch (error) {
    return Err(UnexpectedFailure('unexpected response shape: $error'));
  }
}

/// The body of [response], or a [FormatException] when it is empty.
Map<String, Object?> bodyOf(Response<Map<String, Object?>> response) =>
    response.data ?? (throw const FormatException('empty response body'));
