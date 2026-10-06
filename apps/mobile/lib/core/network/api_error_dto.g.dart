// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_error_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ApiErrorDto _$ApiErrorDtoFromJson(Map<String, dynamic> json) => _ApiErrorDto(
  error: ApiErrorBodyDto.fromJson(json['error'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ApiErrorDtoToJson(_ApiErrorDto instance) =>
    <String, dynamic>{'error': instance.error};

_ApiErrorBodyDto _$ApiErrorBodyDtoFromJson(Map<String, dynamic> json) =>
    _ApiErrorBodyDto(
      code: json['code'] as String,
      message: json['message'] as String,
      field: json['field'] as String?,
    );

Map<String, dynamic> _$ApiErrorBodyDtoToJson(_ApiErrorBodyDto instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'field': instance.field,
    };
