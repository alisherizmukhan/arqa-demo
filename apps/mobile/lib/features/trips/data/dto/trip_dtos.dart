import 'package:driver_diary/core/time/driver_zone.dart';
import 'package:driver_diary/features/trips/domain/entities/place.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/domain/entities/trip_route.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_dtos.freezed.dart';
part 'trip_dtos.g.dart';

// Classic freezed factories, not Dart 3.13 primary constructors: freezed 4
// generates no JSON code for primary constructors, and json_serializable
// 6.14 does not support them yet.

/// A trip as returned by the API (`TripOut`).
@freezed
abstract class TripDto with _$TripDto {
  const factory({
    required String id,
    required String start,
    required String end,
    required int amount,
    required String payment,
    required int commission,
    @JsonKey(name: 'driver_id') String? driverId,
    PlaceDto? pickup,
    PlaceDto? dropoff,
    RouteDto? route,
  }) = _TripDto;

  const new _();

  factory fromJson(Map<String, Object?> json) => _$TripDtoFromJson(json);

  /// Throws [FormatException] on an unknown payment method or a bad
  /// timestamp; the repository turns that into a failure.
  Trip toDomain() => Trip(
    id: id,
    start: DateTime.parse(start).toUtc(),
    end: DateTime.parse(end).toUtc(),
    amount: amount,
    payment: switch (payment) {
      'cash' => PaymentMethod.cash,
      'card' => PaymentMethod.card,
      _ => throw FormatException('unknown payment method', payment),
    },
    commission: commission,
    driverId: driverId,
    pickup: pickup?.toDomain(),
    dropoff: dropoff?.toDomain(),
    route: route?.toDomain() ?? TripRoute.none,
  );
}

/// A place in a trip (`PlaceIn` / `PlaceOut`).
@freezed
abstract class PlaceDto with _$PlaceDto {
  const factory({required double lat, required double lng, String? label}) =
      _PlaceDto;

  const new _();

  factory fromJson(Map<String, Object?> json) => _$PlaceDtoFromJson(json);

  factory fromDomain(Place place) =>
      PlaceDto(lat: place.point.lat, lng: place.point.lng, label: place.label);

  Place toDomain() => Place(point: GeoPoint(lat, lng), label: label);
}

/// A trip's route (`RouteOut`), built by the server.
@freezed
abstract class RouteDto with _$RouteDto {
  const factory({
    required String status,
    String? polyline,
    @JsonKey(name: 'distance_m') int? distanceMetres,
    @JsonKey(name: 'duration_s') int? durationSeconds,
  }) = _RouteDto;

  const new _();

  factory fromJson(Map<String, Object?> json) => _$RouteDtoFromJson(json);

  TripRoute toDomain() => TripRoute(
    status: RouteStatus.parse(status),
    polyline: polyline,
    distanceMetres: distanceMetres,
    durationSeconds: durationSeconds,
  );
}

/// `GET /trips` response.
@freezed
abstract class DayTripsDto with _$DayTripsDto {
  const factory({
    required String date,
    required String tz,
    required List<TripDto> trips,
  }) = _DayTripsDto;

  factory fromJson(Map<String, Object?> json) => _$DayTripsDtoFromJson(json);
}

/// `POST /trips` body (`TripIn`). Timestamps carry the driver's offset.
@freezed
abstract class CreateTripRequestDto with _$CreateTripRequestDto {
  const factory({
    required String id,
    required String start,
    required String end,
    required int amount,
    required String payment,
    required int commission,
    // Left out when there are none: a server without maps rejects unknown
    // fields, and trips without places are the same payload as before.
    @JsonKey(includeIfNull: false) PlaceDto? pickup,
    @JsonKey(includeIfNull: false) PlaceDto? dropoff,
  }) = _CreateTripRequestDto;

  factory fromJson(Map<String, Object?> json) =>
      _$CreateTripRequestDtoFromJson(json);

  factory fromDomain(Trip trip, DriverZone zone) => CreateTripRequestDto(
    id: trip.id,
    start: zone.formatIso(trip.start),
    end: zone.formatIso(trip.end),
    amount: trip.amount,
    payment: trip.payment.name,
    commission: trip.commission,
    pickup: switch (trip.pickup) {
      final place? => PlaceDto.fromDomain(place),
      null => null,
    },
    dropoff: switch (trip.dropoff) {
      final place? => PlaceDto.fromDomain(place),
      null => null,
    },
  );
}

/// `GET /geo/reverse` response.
@freezed
abstract class GeoLabelDto with _$GeoLabelDto {
  const factory({String? label}) = _GeoLabelDto;

  factory fromJson(Map<String, Object?> json) => _$GeoLabelDtoFromJson(json);
}

/// One `GET /geo/search` result.
@freezed
abstract class GeoResultDto with _$GeoResultDto {
  const factory({
    required String label,
    required double lat,
    required double lng,
  }) = _GeoResultDto;

  const new _();

  factory fromJson(Map<String, Object?> json) => _$GeoResultDtoFromJson(json);

  GeoPlace toDomain() => (label: label, point: GeoPoint(lat, lng));
}

/// `GET /geo/search` response.
@freezed
abstract class GeoSearchDto with _$GeoSearchDto {
  const factory({required List<GeoResultDto> results}) = _GeoSearchDto;

  factory fromJson(Map<String, Object?> json) => _$GeoSearchDtoFromJson(json);
}
