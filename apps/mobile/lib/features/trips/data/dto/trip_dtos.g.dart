// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TripDto _$TripDtoFromJson(Map<String, dynamic> json) => _TripDto(
  id: json['id'] as String,
  start: json['start'] as String,
  end: json['end'] as String,
  amount: (json['amount'] as num).toInt(),
  payment: json['payment'] as String,
  commission: (json['commission'] as num).toInt(),
);

Map<String, dynamic> _$TripDtoToJson(_TripDto instance) => <String, dynamic>{
  'id': instance.id,
  'start': instance.start,
  'end': instance.end,
  'amount': instance.amount,
  'payment': instance.payment,
  'commission': instance.commission,
};

_DayTripsDto _$DayTripsDtoFromJson(Map<String, dynamic> json) => _DayTripsDto(
  date: json['date'] as String,
  tz: json['tz'] as String,
  trips: (json['trips'] as List<dynamic>)
      .map((e) => TripDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DayTripsDtoToJson(_DayTripsDto instance) =>
    <String, dynamic>{
      'date': instance.date,
      'tz': instance.tz,
      'trips': instance.trips,
    };

_CreateTripRequestDto _$CreateTripRequestDtoFromJson(
  Map<String, dynamic> json,
) => _CreateTripRequestDto(
  id: json['id'] as String,
  start: json['start'] as String,
  end: json['end'] as String,
  amount: (json['amount'] as num).toInt(),
  payment: json['payment'] as String,
  commission: (json['commission'] as num).toInt(),
);

Map<String, dynamic> _$CreateTripRequestDtoToJson(
  _CreateTripRequestDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'start': instance.start,
  'end': instance.end,
  'amount': instance.amount,
  'payment': instance.payment,
  'commission': instance.commission,
};
