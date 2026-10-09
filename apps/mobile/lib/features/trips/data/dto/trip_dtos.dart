import 'package:driver_diary/core/time/driver_zone.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
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
  );
}
