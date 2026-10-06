import 'package:dio/dio.dart';
import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/network/api_error_dto.dart';

/// Turns a dio error into a [Failure], reading the API's error shape
/// `{"error": {"code", "message", "field"}}` when the response has one.
Failure failureFromDio(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return NetworkFailure(error.message ?? error.type.name);
    case DioExceptionType.badResponse:
      return _fromResponse(error.response);
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.unknown:
      return UnexpectedFailure(error.message ?? error.type.name);
  }
}

Failure _fromResponse(Response<dynamic>? response) {
  final status = response?.statusCode;
  final body = _errorBody(response?.data);
  final message = body?.message ?? 'HTTP $status';
  return switch (status) {
    409 => ConflictFailure(message),
    422 => ValidationFailure(
      code: body?.code ?? 'invalid_request',
      message: message,
      field: body?.field,
    ),
    _ => ServerFailure(statusCode: status, message: message),
  };
}

ApiErrorBodyDto? _errorBody(Object? data) {
  if (data is! Map<String, Object?>) return null;
  try {
    return ApiErrorDto.fromJson(data).error;
    // A body that is not the API's error shape (e.g. a proxy's HTML page).
    // ignore: avoid_catching_errors
  } on TypeError {
    return null;
  }
}
