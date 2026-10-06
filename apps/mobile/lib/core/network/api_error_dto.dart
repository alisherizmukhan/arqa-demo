import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_error_dto.freezed.dart';
part 'api_error_dto.g.dart';

/// Every API error: `{"error": {"code", "message", "field"}}`.
@freezed
abstract class ApiErrorDto with _$ApiErrorDto {
  const factory({required ApiErrorBodyDto error}) = _ApiErrorDto;

  factory fromJson(Map<String, Object?> json) => _$ApiErrorDtoFromJson(json);
}

@freezed
abstract class ApiErrorBodyDto with _$ApiErrorBodyDto {
  const factory({
    required String code,
    required String message,
    String? field,
  }) = _ApiErrorBodyDto;

  factory fromJson(Map<String, Object?> json) =>
      _$ApiErrorBodyDtoFromJson(json);
}
