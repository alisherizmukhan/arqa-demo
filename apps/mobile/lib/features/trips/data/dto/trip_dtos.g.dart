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
  driverId: json['driver_id'] as String?,
  pickup: json['pickup'] == null
      ? null
      : PlaceDto.fromJson(json['pickup'] as Map<String, dynamic>),
  dropoff: json['dropoff'] == null
      ? null
      : PlaceDto.fromJson(json['dropoff'] as Map<String, dynamic>),
  route: json['route'] == null
      ? null
      : RouteDto.fromJson(json['route'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TripDtoToJson(_TripDto instance) => <String, dynamic>{
  'id': instance.id,
  'start': instance.start,
  'end': instance.end,
  'amount': instance.amount,
  'payment': instance.payment,
  'commission': instance.commission,
  'driver_id': instance.driverId,
  'pickup': instance.pickup,
  'dropoff': instance.dropoff,
  'route': instance.route,
};

_PlaceDto _$PlaceDtoFromJson(Map<String, dynamic> json) => _PlaceDto(
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  label: json['label'] as String?,
);

Map<String, dynamic> _$PlaceDtoToJson(_PlaceDto instance) => <String, dynamic>{
  'lat': instance.lat,
  'lng': instance.lng,
  'label': instance.label,
};

_RouteDto _$RouteDtoFromJson(Map<String, dynamic> json) => _RouteDto(
  status: json['status'] as String,
  polyline: json['polyline'] as String?,
  distanceMetres: (json['distance_m'] as num?)?.toInt(),
  durationSeconds: (json['duration_s'] as num?)?.toInt(),
);

Map<String, dynamic> _$RouteDtoToJson(_RouteDto instance) => <String, dynamic>{
  'status': instance.status,
  'polyline': instance.polyline,
  'distance_m': instance.distanceMetres,
  'duration_s': instance.durationSeconds,
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
  pickup: json['pickup'] == null
      ? null
      : PlaceDto.fromJson(json['pickup'] as Map<String, dynamic>),
  dropoff: json['dropoff'] == null
      ? null
      : PlaceDto.fromJson(json['dropoff'] as Map<String, dynamic>),
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
  'pickup': ?instance.pickup,
  'dropoff': ?instance.dropoff,
};

_GeoLabelDto _$GeoLabelDtoFromJson(Map<String, dynamic> json) =>
    _GeoLabelDto(label: json['label'] as String?);

Map<String, dynamic> _$GeoLabelDtoToJson(_GeoLabelDto instance) =>
    <String, dynamic>{'label': instance.label};

_GeoResultDto _$GeoResultDtoFromJson(Map<String, dynamic> json) =>
    _GeoResultDto(
      label: json['label'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );

Map<String, dynamic> _$GeoResultDtoToJson(_GeoResultDto instance) =>
    <String, dynamic>{
      'label': instance.label,
      'lat': instance.lat,
      'lng': instance.lng,
    };

_GeoSearchDto _$GeoSearchDtoFromJson(Map<String, dynamic> json) =>
    _GeoSearchDto(
      results: (json['results'] as List<dynamic>)
          .map((e) => GeoResultDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GeoSearchDtoToJson(_GeoSearchDto instance) =>
    <String, dynamic>{'results': instance.results};
