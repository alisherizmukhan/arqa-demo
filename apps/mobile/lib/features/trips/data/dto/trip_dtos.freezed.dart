// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_dtos.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TripDto {

 String get id; String get start; String get end; int get amount; String get payment; int get commission;@JsonKey(name: 'driver_id') String? get driverId; PlaceDto? get pickup; PlaceDto? get dropoff; RouteDto? get route;
/// Create a copy of TripDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripDtoCopyWith<TripDto> get copyWith => _$TripDtoCopyWithImpl<TripDto>(this as TripDto, _$identity);

  /// Serializes this TripDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TripDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.start, _this.start) || other.start == _this.start)&&(identical(other.end, _this.end) || other.end == _this.end)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.payment, _this.payment) || other.payment == _this.payment)&&(identical(other.commission, _this.commission) || other.commission == _this.commission)&&(identical(other.driverId, _this.driverId) || other.driverId == _this.driverId)&&(identical(other.pickup, _this.pickup) || other.pickup == _this.pickup)&&(identical(other.dropoff, _this.dropoff) || other.dropoff == _this.dropoff)&&(identical(other.route, _this.route) || other.route == _this.route));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TripDto;
  return Object.hash(runtimeType,_this.id,_this.start,_this.end,_this.amount,_this.payment,_this.commission,_this.driverId,_this.pickup,_this.dropoff,_this.route);
}

@override
String toString() {
  final _this = this as TripDto;
  return 'TripDto(id: ${_this.id}, start: ${_this.start}, end: ${_this.end}, amount: ${_this.amount}, payment: ${_this.payment}, commission: ${_this.commission}, driverId: ${_this.driverId}, pickup: ${_this.pickup}, dropoff: ${_this.dropoff}, route: ${_this.route})';
}


}

/// @nodoc
abstract mixin class $TripDtoCopyWith<$Res>  {
  factory $TripDtoCopyWith(TripDto value, $Res Function(TripDto) _then) = _$TripDtoCopyWithImpl;
@useResult
$Res call({
 String id, String start, String end, int amount, String payment, int commission,@JsonKey(name: 'driver_id') String? driverId, PlaceDto? pickup, PlaceDto? dropoff, RouteDto? route
});


$PlaceDtoCopyWith<$Res>? get pickup;$PlaceDtoCopyWith<$Res>? get dropoff;$RouteDtoCopyWith<$Res>? get route;

}
/// @nodoc
class _$TripDtoCopyWithImpl<$Res>
    implements $TripDtoCopyWith<$Res> {
  _$TripDtoCopyWithImpl(this._self, this._then);

  final TripDto _self;
  final $Res Function(TripDto) _then;

/// Create a copy of TripDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? start = null,Object? end = null,Object? amount = null,Object? payment = null,Object? commission = null,Object? driverId = freezed,Object? pickup = freezed,Object? dropoff = freezed,Object? route = freezed,}) {
  return _then(TripDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as String,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,payment: null == payment ? _self.payment : payment // ignore: cast_nullable_to_non_nullable
as String,commission: null == commission ? _self.commission : commission // ignore: cast_nullable_to_non_nullable
as int,driverId: freezed == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String?,pickup: freezed == pickup ? _self.pickup : pickup // ignore: cast_nullable_to_non_nullable
as PlaceDto?,dropoff: freezed == dropoff ? _self.dropoff : dropoff // ignore: cast_nullable_to_non_nullable
as PlaceDto?,route: freezed == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as RouteDto?,
  ));
}
/// Create a copy of TripDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaceDtoCopyWith<$Res>? get pickup {
    if (_self.pickup == null) {
    return null;
  }

  return $PlaceDtoCopyWith<$Res>(_self.pickup!, (value) {
    return _then(_self.copyWith(pickup: value));
  });
}/// Create a copy of TripDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaceDtoCopyWith<$Res>? get dropoff {
    if (_self.dropoff == null) {
    return null;
  }

  return $PlaceDtoCopyWith<$Res>(_self.dropoff!, (value) {
    return _then(_self.copyWith(dropoff: value));
  });
}/// Create a copy of TripDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RouteDtoCopyWith<$Res>? get route {
    if (_self.route == null) {
    return null;
  }

  return $RouteDtoCopyWith<$Res>(_self.route!, (value) {
    return _then(_self.copyWith(route: value));
  });
}
}


/// Adds pattern-matching-related methods to [TripDto].
extension TripDtoPatterns on TripDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripDto value)  $default,){
final _that = this;
switch (_that) {
case _TripDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripDto value)?  $default,){
final _that = this;
switch (_that) {
case _TripDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String start,  String end,  int amount,  String payment,  int commission, @JsonKey(name: 'driver_id')  String? driverId,  PlaceDto? pickup,  PlaceDto? dropoff,  RouteDto? route)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripDto() when $default != null:
return $default(_that.id,_that.start,_that.end,_that.amount,_that.payment,_that.commission,_that.driverId,_that.pickup,_that.dropoff,_that.route);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String start,  String end,  int amount,  String payment,  int commission, @JsonKey(name: 'driver_id')  String? driverId,  PlaceDto? pickup,  PlaceDto? dropoff,  RouteDto? route)  $default,) {final _that = this;
switch (_that) {
case _TripDto():
return $default(_that.id,_that.start,_that.end,_that.amount,_that.payment,_that.commission,_that.driverId,_that.pickup,_that.dropoff,_that.route);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String start,  String end,  int amount,  String payment,  int commission, @JsonKey(name: 'driver_id')  String? driverId,  PlaceDto? pickup,  PlaceDto? dropoff,  RouteDto? route)?  $default,) {final _that = this;
switch (_that) {
case _TripDto() when $default != null:
return $default(_that.id,_that.start,_that.end,_that.amount,_that.payment,_that.commission,_that.driverId,_that.pickup,_that.dropoff,_that.route);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripDto extends TripDto {
  const _TripDto({required this.id, required this.start, required this.end, required this.amount, required this.payment, required this.commission, @JsonKey(name: 'driver_id') this.driverId, this.pickup, this.dropoff, this.route}): super._();
  factory _TripDto.fromJson(Map<String, dynamic> json) => _$TripDtoFromJson(json);

@override final  String id;
@override final  String start;
@override final  String end;
@override final  int amount;
@override final  String payment;
@override final  int commission;
@override@JsonKey(name: 'driver_id') final  String? driverId;
@override final  PlaceDto? pickup;
@override final  PlaceDto? dropoff;
@override final  RouteDto? route;

/// Create a copy of TripDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripDtoCopyWith<_TripDto> get copyWith => __$TripDtoCopyWithImpl<_TripDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripDto&&(identical(other.id, id) || other.id == id)&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.payment, payment) || other.payment == payment)&&(identical(other.commission, commission) || other.commission == commission)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.pickup, pickup) || other.pickup == pickup)&&(identical(other.dropoff, dropoff) || other.dropoff == dropoff)&&(identical(other.route, route) || other.route == route));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,start,end,amount,payment,commission,driverId,pickup,dropoff,route);
}

@override
String toString() {
    return 'TripDto(id: $id, start: $start, end: $end, amount: $amount, payment: $payment, commission: $commission, driverId: $driverId, pickup: $pickup, dropoff: $dropoff, route: $route)';
}


}

/// @nodoc
abstract mixin class _$TripDtoCopyWith<$Res> implements $TripDtoCopyWith<$Res> {
  factory _$TripDtoCopyWith(_TripDto value, $Res Function(_TripDto) _then) = __$TripDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String start, String end, int amount, String payment, int commission,@JsonKey(name: 'driver_id') String? driverId, PlaceDto? pickup, PlaceDto? dropoff, RouteDto? route
});


@override $PlaceDtoCopyWith<$Res>? get pickup;@override $PlaceDtoCopyWith<$Res>? get dropoff;@override $RouteDtoCopyWith<$Res>? get route;

}
/// @nodoc
class __$TripDtoCopyWithImpl<$Res>
    implements _$TripDtoCopyWith<$Res> {
  __$TripDtoCopyWithImpl(this._self, this._then);

  final _TripDto _self;
  final $Res Function(_TripDto) _then;

/// Create a copy of TripDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? start = null,Object? end = null,Object? amount = null,Object? payment = null,Object? commission = null,Object? driverId = freezed,Object? pickup = freezed,Object? dropoff = freezed,Object? route = freezed,}) {
  return _then(_TripDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as String,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,payment: null == payment ? _self.payment : payment // ignore: cast_nullable_to_non_nullable
as String,commission: null == commission ? _self.commission : commission // ignore: cast_nullable_to_non_nullable
as int,driverId: freezed == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String?,pickup: freezed == pickup ? _self.pickup : pickup // ignore: cast_nullable_to_non_nullable
as PlaceDto?,dropoff: freezed == dropoff ? _self.dropoff : dropoff // ignore: cast_nullable_to_non_nullable
as PlaceDto?,route: freezed == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as RouteDto?,
  ));
}

/// Create a copy of TripDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaceDtoCopyWith<$Res>? get pickup {
    if (_self.pickup == null) {
    return null;
  }

  return $PlaceDtoCopyWith<$Res>(_self.pickup!, (value) {
    return _then(_self.copyWith(pickup: value));
  });
}/// Create a copy of TripDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaceDtoCopyWith<$Res>? get dropoff {
    if (_self.dropoff == null) {
    return null;
  }

  return $PlaceDtoCopyWith<$Res>(_self.dropoff!, (value) {
    return _then(_self.copyWith(dropoff: value));
  });
}/// Create a copy of TripDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RouteDtoCopyWith<$Res>? get route {
    if (_self.route == null) {
    return null;
  }

  return $RouteDtoCopyWith<$Res>(_self.route!, (value) {
    return _then(_self.copyWith(route: value));
  });
}
}


/// @nodoc
mixin _$PlaceDto {

 double get lat; double get lng; String? get label;
/// Create a copy of PlaceDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaceDtoCopyWith<PlaceDto> get copyWith => _$PlaceDtoCopyWithImpl<PlaceDto>(this as PlaceDto, _$identity);

  /// Serializes this PlaceDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlaceDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceDto&&(identical(other.lat, _this.lat) || other.lat == _this.lat)&&(identical(other.lng, _this.lng) || other.lng == _this.lng)&&(identical(other.label, _this.label) || other.label == _this.label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlaceDto;
  return Object.hash(runtimeType,_this.lat,_this.lng,_this.label);
}

@override
String toString() {
  final _this = this as PlaceDto;
  return 'PlaceDto(lat: ${_this.lat}, lng: ${_this.lng}, label: ${_this.label})';
}


}

/// @nodoc
abstract mixin class $PlaceDtoCopyWith<$Res>  {
  factory $PlaceDtoCopyWith(PlaceDto value, $Res Function(PlaceDto) _then) = _$PlaceDtoCopyWithImpl;
@useResult
$Res call({
 double lat, double lng, String? label
});




}
/// @nodoc
class _$PlaceDtoCopyWithImpl<$Res>
    implements $PlaceDtoCopyWith<$Res> {
  _$PlaceDtoCopyWithImpl(this._self, this._then);

  final PlaceDto _self;
  final $Res Function(PlaceDto) _then;

/// Create a copy of PlaceDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lat = null,Object? lng = null,Object? label = freezed,}) {
  return _then(PlaceDto(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaceDto].
extension PlaceDtoPatterns on PlaceDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaceDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaceDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaceDto value)  $default,){
final _that = this;
switch (_that) {
case _PlaceDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaceDto value)?  $default,){
final _that = this;
switch (_that) {
case _PlaceDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double lat,  double lng,  String? label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaceDto() when $default != null:
return $default(_that.lat,_that.lng,_that.label);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double lat,  double lng,  String? label)  $default,) {final _that = this;
switch (_that) {
case _PlaceDto():
return $default(_that.lat,_that.lng,_that.label);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double lat,  double lng,  String? label)?  $default,) {final _that = this;
switch (_that) {
case _PlaceDto() when $default != null:
return $default(_that.lat,_that.lng,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlaceDto extends PlaceDto {
  const _PlaceDto({required this.lat, required this.lng, this.label}): super._();
  factory _PlaceDto.fromJson(Map<String, dynamic> json) => _$PlaceDtoFromJson(json);

@override final  double lat;
@override final  double lng;
@override final  String? label;

/// Create a copy of PlaceDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaceDtoCopyWith<_PlaceDto> get copyWith => __$PlaceDtoCopyWithImpl<_PlaceDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaceDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaceDto&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,lat,lng,label);
}

@override
String toString() {
    return 'PlaceDto(lat: $lat, lng: $lng, label: $label)';
}


}

/// @nodoc
abstract mixin class _$PlaceDtoCopyWith<$Res> implements $PlaceDtoCopyWith<$Res> {
  factory _$PlaceDtoCopyWith(_PlaceDto value, $Res Function(_PlaceDto) _then) = __$PlaceDtoCopyWithImpl;
@override @useResult
$Res call({
 double lat, double lng, String? label
});




}
/// @nodoc
class __$PlaceDtoCopyWithImpl<$Res>
    implements _$PlaceDtoCopyWith<$Res> {
  __$PlaceDtoCopyWithImpl(this._self, this._then);

  final _PlaceDto _self;
  final $Res Function(_PlaceDto) _then;

/// Create a copy of PlaceDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lat = null,Object? lng = null,Object? label = freezed,}) {
  return _then(_PlaceDto(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$RouteDto {

 String get status; String? get polyline;@JsonKey(name: 'distance_m') int? get distanceMetres;@JsonKey(name: 'duration_s') int? get durationSeconds;
/// Create a copy of RouteDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RouteDtoCopyWith<RouteDto> get copyWith => _$RouteDtoCopyWithImpl<RouteDto>(this as RouteDto, _$identity);

  /// Serializes this RouteDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RouteDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteDto&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.polyline, _this.polyline) || other.polyline == _this.polyline)&&(identical(other.distanceMetres, _this.distanceMetres) || other.distanceMetres == _this.distanceMetres)&&(identical(other.durationSeconds, _this.durationSeconds) || other.durationSeconds == _this.durationSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RouteDto;
  return Object.hash(runtimeType,_this.status,_this.polyline,_this.distanceMetres,_this.durationSeconds);
}

@override
String toString() {
  final _this = this as RouteDto;
  return 'RouteDto(status: ${_this.status}, polyline: ${_this.polyline}, distanceMetres: ${_this.distanceMetres}, durationSeconds: ${_this.durationSeconds})';
}


}

/// @nodoc
abstract mixin class $RouteDtoCopyWith<$Res>  {
  factory $RouteDtoCopyWith(RouteDto value, $Res Function(RouteDto) _then) = _$RouteDtoCopyWithImpl;
@useResult
$Res call({
 String status, String? polyline,@JsonKey(name: 'distance_m') int? distanceMetres,@JsonKey(name: 'duration_s') int? durationSeconds
});




}
/// @nodoc
class _$RouteDtoCopyWithImpl<$Res>
    implements $RouteDtoCopyWith<$Res> {
  _$RouteDtoCopyWithImpl(this._self, this._then);

  final RouteDto _self;
  final $Res Function(RouteDto) _then;

/// Create a copy of RouteDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? polyline = freezed,Object? distanceMetres = freezed,Object? durationSeconds = freezed,}) {
  return _then(RouteDto(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,polyline: freezed == polyline ? _self.polyline : polyline // ignore: cast_nullable_to_non_nullable
as String?,distanceMetres: freezed == distanceMetres ? _self.distanceMetres : distanceMetres // ignore: cast_nullable_to_non_nullable
as int?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [RouteDto].
extension RouteDtoPatterns on RouteDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RouteDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RouteDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RouteDto value)  $default,){
final _that = this;
switch (_that) {
case _RouteDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RouteDto value)?  $default,){
final _that = this;
switch (_that) {
case _RouteDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  String? polyline, @JsonKey(name: 'distance_m')  int? distanceMetres, @JsonKey(name: 'duration_s')  int? durationSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RouteDto() when $default != null:
return $default(_that.status,_that.polyline,_that.distanceMetres,_that.durationSeconds);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  String? polyline, @JsonKey(name: 'distance_m')  int? distanceMetres, @JsonKey(name: 'duration_s')  int? durationSeconds)  $default,) {final _that = this;
switch (_that) {
case _RouteDto():
return $default(_that.status,_that.polyline,_that.distanceMetres,_that.durationSeconds);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  String? polyline, @JsonKey(name: 'distance_m')  int? distanceMetres, @JsonKey(name: 'duration_s')  int? durationSeconds)?  $default,) {final _that = this;
switch (_that) {
case _RouteDto() when $default != null:
return $default(_that.status,_that.polyline,_that.distanceMetres,_that.durationSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RouteDto extends RouteDto {
  const _RouteDto({required this.status, this.polyline, @JsonKey(name: 'distance_m') this.distanceMetres, @JsonKey(name: 'duration_s') this.durationSeconds}): super._();
  factory _RouteDto.fromJson(Map<String, dynamic> json) => _$RouteDtoFromJson(json);

@override final  String status;
@override final  String? polyline;
@override@JsonKey(name: 'distance_m') final  int? distanceMetres;
@override@JsonKey(name: 'duration_s') final  int? durationSeconds;

/// Create a copy of RouteDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RouteDtoCopyWith<_RouteDto> get copyWith => __$RouteDtoCopyWithImpl<_RouteDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RouteDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RouteDto&&(identical(other.status, status) || other.status == status)&&(identical(other.polyline, polyline) || other.polyline == polyline)&&(identical(other.distanceMetres, distanceMetres) || other.distanceMetres == distanceMetres)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,status,polyline,distanceMetres,durationSeconds);
}

@override
String toString() {
    return 'RouteDto(status: $status, polyline: $polyline, distanceMetres: $distanceMetres, durationSeconds: $durationSeconds)';
}


}

/// @nodoc
abstract mixin class _$RouteDtoCopyWith<$Res> implements $RouteDtoCopyWith<$Res> {
  factory _$RouteDtoCopyWith(_RouteDto value, $Res Function(_RouteDto) _then) = __$RouteDtoCopyWithImpl;
@override @useResult
$Res call({
 String status, String? polyline,@JsonKey(name: 'distance_m') int? distanceMetres,@JsonKey(name: 'duration_s') int? durationSeconds
});




}
/// @nodoc
class __$RouteDtoCopyWithImpl<$Res>
    implements _$RouteDtoCopyWith<$Res> {
  __$RouteDtoCopyWithImpl(this._self, this._then);

  final _RouteDto _self;
  final $Res Function(_RouteDto) _then;

/// Create a copy of RouteDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? polyline = freezed,Object? distanceMetres = freezed,Object? durationSeconds = freezed,}) {
  return _then(_RouteDto(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,polyline: freezed == polyline ? _self.polyline : polyline // ignore: cast_nullable_to_non_nullable
as String?,distanceMetres: freezed == distanceMetres ? _self.distanceMetres : distanceMetres // ignore: cast_nullable_to_non_nullable
as int?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$DayTripsDto {

 String get date; String get tz; List<TripDto> get trips;
/// Create a copy of DayTripsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayTripsDtoCopyWith<DayTripsDto> get copyWith => _$DayTripsDtoCopyWithImpl<DayTripsDto>(this as DayTripsDto, _$identity);

  /// Serializes this DayTripsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DayTripsDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayTripsDto&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.tz, _this.tz) || other.tz == _this.tz)&&const DeepCollectionEquality().equals(other.trips, _this.trips));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DayTripsDto;
  return Object.hash(runtimeType,_this.date,_this.tz,const DeepCollectionEquality().hash(_this.trips));
}

@override
String toString() {
  final _this = this as DayTripsDto;
  return 'DayTripsDto(date: ${_this.date}, tz: ${_this.tz}, trips: ${_this.trips})';
}


}

/// @nodoc
abstract mixin class $DayTripsDtoCopyWith<$Res>  {
  factory $DayTripsDtoCopyWith(DayTripsDto value, $Res Function(DayTripsDto) _then) = _$DayTripsDtoCopyWithImpl;
@useResult
$Res call({
 String date, String tz, List<TripDto> trips
});




}
/// @nodoc
class _$DayTripsDtoCopyWithImpl<$Res>
    implements $DayTripsDtoCopyWith<$Res> {
  _$DayTripsDtoCopyWithImpl(this._self, this._then);

  final DayTripsDto _self;
  final $Res Function(DayTripsDto) _then;

/// Create a copy of DayTripsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? tz = null,Object? trips = null,}) {
  return _then(DayTripsDto(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,tz: null == tz ? _self.tz : tz // ignore: cast_nullable_to_non_nullable
as String,trips: null == trips ? _self.trips : trips // ignore: cast_nullable_to_non_nullable
as List<TripDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [DayTripsDto].
extension DayTripsDtoPatterns on DayTripsDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayTripsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayTripsDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayTripsDto value)  $default,){
final _that = this;
switch (_that) {
case _DayTripsDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayTripsDto value)?  $default,){
final _that = this;
switch (_that) {
case _DayTripsDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String date,  String tz,  List<TripDto> trips)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayTripsDto() when $default != null:
return $default(_that.date,_that.tz,_that.trips);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String date,  String tz,  List<TripDto> trips)  $default,) {final _that = this;
switch (_that) {
case _DayTripsDto():
return $default(_that.date,_that.tz,_that.trips);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String date,  String tz,  List<TripDto> trips)?  $default,) {final _that = this;
switch (_that) {
case _DayTripsDto() when $default != null:
return $default(_that.date,_that.tz,_that.trips);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DayTripsDto implements DayTripsDto {
  const _DayTripsDto({required this.date, required this.tz, required  List<TripDto> trips}): _trips = trips;
  factory _DayTripsDto.fromJson(Map<String, dynamic> json) => _$DayTripsDtoFromJson(json);

@override final  String date;
@override final  String tz;
 final  List<TripDto> _trips;
@override List<TripDto> get trips {
  if (_trips is EqualUnmodifiableListView) return _trips;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_trips);
}


/// Create a copy of DayTripsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayTripsDtoCopyWith<_DayTripsDto> get copyWith => __$DayTripsDtoCopyWithImpl<_DayTripsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DayTripsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayTripsDto&&(identical(other.date, date) || other.date == date)&&(identical(other.tz, tz) || other.tz == tz)&&const DeepCollectionEquality().equals(other.trips, _trips));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,date,tz,const DeepCollectionEquality().hash(_trips));
}

@override
String toString() {
    return 'DayTripsDto(date: $date, tz: $tz, trips: $trips)';
}


}

/// @nodoc
abstract mixin class _$DayTripsDtoCopyWith<$Res> implements $DayTripsDtoCopyWith<$Res> {
  factory _$DayTripsDtoCopyWith(_DayTripsDto value, $Res Function(_DayTripsDto) _then) = __$DayTripsDtoCopyWithImpl;
@override @useResult
$Res call({
 String date, String tz, List<TripDto> trips
});




}
/// @nodoc
class __$DayTripsDtoCopyWithImpl<$Res>
    implements _$DayTripsDtoCopyWith<$Res> {
  __$DayTripsDtoCopyWithImpl(this._self, this._then);

  final _DayTripsDto _self;
  final $Res Function(_DayTripsDto) _then;

/// Create a copy of DayTripsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? tz = null,Object? trips = null,}) {
  return _then(_DayTripsDto(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,tz: null == tz ? _self.tz : tz // ignore: cast_nullable_to_non_nullable
as String,trips: null == trips ? _self._trips : trips // ignore: cast_nullable_to_non_nullable
as List<TripDto>,
  ));
}


}


/// @nodoc
mixin _$CreateTripRequestDto {

 String get id; String get start; String get end; int get amount; String get payment; int get commission;@JsonKey(includeIfNull: false) PlaceDto? get pickup;@JsonKey(includeIfNull: false) PlaceDto? get dropoff;
/// Create a copy of CreateTripRequestDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateTripRequestDtoCopyWith<CreateTripRequestDto> get copyWith => _$CreateTripRequestDtoCopyWithImpl<CreateTripRequestDto>(this as CreateTripRequestDto, _$identity);

  /// Serializes this CreateTripRequestDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CreateTripRequestDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateTripRequestDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.start, _this.start) || other.start == _this.start)&&(identical(other.end, _this.end) || other.end == _this.end)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.payment, _this.payment) || other.payment == _this.payment)&&(identical(other.commission, _this.commission) || other.commission == _this.commission)&&(identical(other.pickup, _this.pickup) || other.pickup == _this.pickup)&&(identical(other.dropoff, _this.dropoff) || other.dropoff == _this.dropoff));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CreateTripRequestDto;
  return Object.hash(runtimeType,_this.id,_this.start,_this.end,_this.amount,_this.payment,_this.commission,_this.pickup,_this.dropoff);
}

@override
String toString() {
  final _this = this as CreateTripRequestDto;
  return 'CreateTripRequestDto(id: ${_this.id}, start: ${_this.start}, end: ${_this.end}, amount: ${_this.amount}, payment: ${_this.payment}, commission: ${_this.commission}, pickup: ${_this.pickup}, dropoff: ${_this.dropoff})';
}


}

/// @nodoc
abstract mixin class $CreateTripRequestDtoCopyWith<$Res>  {
  factory $CreateTripRequestDtoCopyWith(CreateTripRequestDto value, $Res Function(CreateTripRequestDto) _then) = _$CreateTripRequestDtoCopyWithImpl;
@useResult
$Res call({
 String id, String start, String end, int amount, String payment, int commission,@JsonKey(includeIfNull: false) PlaceDto? pickup,@JsonKey(includeIfNull: false) PlaceDto? dropoff
});


$PlaceDtoCopyWith<$Res>? get pickup;$PlaceDtoCopyWith<$Res>? get dropoff;

}
/// @nodoc
class _$CreateTripRequestDtoCopyWithImpl<$Res>
    implements $CreateTripRequestDtoCopyWith<$Res> {
  _$CreateTripRequestDtoCopyWithImpl(this._self, this._then);

  final CreateTripRequestDto _self;
  final $Res Function(CreateTripRequestDto) _then;

/// Create a copy of CreateTripRequestDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? start = null,Object? end = null,Object? amount = null,Object? payment = null,Object? commission = null,Object? pickup = freezed,Object? dropoff = freezed,}) {
  return _then(CreateTripRequestDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as String,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,payment: null == payment ? _self.payment : payment // ignore: cast_nullable_to_non_nullable
as String,commission: null == commission ? _self.commission : commission // ignore: cast_nullable_to_non_nullable
as int,pickup: freezed == pickup ? _self.pickup : pickup // ignore: cast_nullable_to_non_nullable
as PlaceDto?,dropoff: freezed == dropoff ? _self.dropoff : dropoff // ignore: cast_nullable_to_non_nullable
as PlaceDto?,
  ));
}
/// Create a copy of CreateTripRequestDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaceDtoCopyWith<$Res>? get pickup {
    if (_self.pickup == null) {
    return null;
  }

  return $PlaceDtoCopyWith<$Res>(_self.pickup!, (value) {
    return _then(_self.copyWith(pickup: value));
  });
}/// Create a copy of CreateTripRequestDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaceDtoCopyWith<$Res>? get dropoff {
    if (_self.dropoff == null) {
    return null;
  }

  return $PlaceDtoCopyWith<$Res>(_self.dropoff!, (value) {
    return _then(_self.copyWith(dropoff: value));
  });
}
}


/// Adds pattern-matching-related methods to [CreateTripRequestDto].
extension CreateTripRequestDtoPatterns on CreateTripRequestDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateTripRequestDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateTripRequestDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateTripRequestDto value)  $default,){
final _that = this;
switch (_that) {
case _CreateTripRequestDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateTripRequestDto value)?  $default,){
final _that = this;
switch (_that) {
case _CreateTripRequestDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String start,  String end,  int amount,  String payment,  int commission, @JsonKey(includeIfNull: false)  PlaceDto? pickup, @JsonKey(includeIfNull: false)  PlaceDto? dropoff)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateTripRequestDto() when $default != null:
return $default(_that.id,_that.start,_that.end,_that.amount,_that.payment,_that.commission,_that.pickup,_that.dropoff);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String start,  String end,  int amount,  String payment,  int commission, @JsonKey(includeIfNull: false)  PlaceDto? pickup, @JsonKey(includeIfNull: false)  PlaceDto? dropoff)  $default,) {final _that = this;
switch (_that) {
case _CreateTripRequestDto():
return $default(_that.id,_that.start,_that.end,_that.amount,_that.payment,_that.commission,_that.pickup,_that.dropoff);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String start,  String end,  int amount,  String payment,  int commission, @JsonKey(includeIfNull: false)  PlaceDto? pickup, @JsonKey(includeIfNull: false)  PlaceDto? dropoff)?  $default,) {final _that = this;
switch (_that) {
case _CreateTripRequestDto() when $default != null:
return $default(_that.id,_that.start,_that.end,_that.amount,_that.payment,_that.commission,_that.pickup,_that.dropoff);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateTripRequestDto implements CreateTripRequestDto {
  const _CreateTripRequestDto({required this.id, required this.start, required this.end, required this.amount, required this.payment, required this.commission, @JsonKey(includeIfNull: false) this.pickup, @JsonKey(includeIfNull: false) this.dropoff});
  factory _CreateTripRequestDto.fromJson(Map<String, dynamic> json) => _$CreateTripRequestDtoFromJson(json);

@override final  String id;
@override final  String start;
@override final  String end;
@override final  int amount;
@override final  String payment;
@override final  int commission;
@override@JsonKey(includeIfNull: false) final  PlaceDto? pickup;
@override@JsonKey(includeIfNull: false) final  PlaceDto? dropoff;

/// Create a copy of CreateTripRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateTripRequestDtoCopyWith<_CreateTripRequestDto> get copyWith => __$CreateTripRequestDtoCopyWithImpl<_CreateTripRequestDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateTripRequestDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateTripRequestDto&&(identical(other.id, id) || other.id == id)&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.payment, payment) || other.payment == payment)&&(identical(other.commission, commission) || other.commission == commission)&&(identical(other.pickup, pickup) || other.pickup == pickup)&&(identical(other.dropoff, dropoff) || other.dropoff == dropoff));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,start,end,amount,payment,commission,pickup,dropoff);
}

@override
String toString() {
    return 'CreateTripRequestDto(id: $id, start: $start, end: $end, amount: $amount, payment: $payment, commission: $commission, pickup: $pickup, dropoff: $dropoff)';
}


}

/// @nodoc
abstract mixin class _$CreateTripRequestDtoCopyWith<$Res> implements $CreateTripRequestDtoCopyWith<$Res> {
  factory _$CreateTripRequestDtoCopyWith(_CreateTripRequestDto value, $Res Function(_CreateTripRequestDto) _then) = __$CreateTripRequestDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String start, String end, int amount, String payment, int commission,@JsonKey(includeIfNull: false) PlaceDto? pickup,@JsonKey(includeIfNull: false) PlaceDto? dropoff
});


@override $PlaceDtoCopyWith<$Res>? get pickup;@override $PlaceDtoCopyWith<$Res>? get dropoff;

}
/// @nodoc
class __$CreateTripRequestDtoCopyWithImpl<$Res>
    implements _$CreateTripRequestDtoCopyWith<$Res> {
  __$CreateTripRequestDtoCopyWithImpl(this._self, this._then);

  final _CreateTripRequestDto _self;
  final $Res Function(_CreateTripRequestDto) _then;

/// Create a copy of CreateTripRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? start = null,Object? end = null,Object? amount = null,Object? payment = null,Object? commission = null,Object? pickup = freezed,Object? dropoff = freezed,}) {
  return _then(_CreateTripRequestDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as String,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,payment: null == payment ? _self.payment : payment // ignore: cast_nullable_to_non_nullable
as String,commission: null == commission ? _self.commission : commission // ignore: cast_nullable_to_non_nullable
as int,pickup: freezed == pickup ? _self.pickup : pickup // ignore: cast_nullable_to_non_nullable
as PlaceDto?,dropoff: freezed == dropoff ? _self.dropoff : dropoff // ignore: cast_nullable_to_non_nullable
as PlaceDto?,
  ));
}

/// Create a copy of CreateTripRequestDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaceDtoCopyWith<$Res>? get pickup {
    if (_self.pickup == null) {
    return null;
  }

  return $PlaceDtoCopyWith<$Res>(_self.pickup!, (value) {
    return _then(_self.copyWith(pickup: value));
  });
}/// Create a copy of CreateTripRequestDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaceDtoCopyWith<$Res>? get dropoff {
    if (_self.dropoff == null) {
    return null;
  }

  return $PlaceDtoCopyWith<$Res>(_self.dropoff!, (value) {
    return _then(_self.copyWith(dropoff: value));
  });
}
}


/// @nodoc
mixin _$GeoLabelDto {

 String? get label;
/// Create a copy of GeoLabelDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GeoLabelDtoCopyWith<GeoLabelDto> get copyWith => _$GeoLabelDtoCopyWithImpl<GeoLabelDto>(this as GeoLabelDto, _$identity);

  /// Serializes this GeoLabelDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GeoLabelDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GeoLabelDto&&(identical(other.label, _this.label) || other.label == _this.label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GeoLabelDto;
  return Object.hash(runtimeType,_this.label);
}

@override
String toString() {
  final _this = this as GeoLabelDto;
  return 'GeoLabelDto(label: ${_this.label})';
}


}

/// @nodoc
abstract mixin class $GeoLabelDtoCopyWith<$Res>  {
  factory $GeoLabelDtoCopyWith(GeoLabelDto value, $Res Function(GeoLabelDto) _then) = _$GeoLabelDtoCopyWithImpl;
@useResult
$Res call({
 String? label
});




}
/// @nodoc
class _$GeoLabelDtoCopyWithImpl<$Res>
    implements $GeoLabelDtoCopyWith<$Res> {
  _$GeoLabelDtoCopyWithImpl(this._self, this._then);

  final GeoLabelDto _self;
  final $Res Function(GeoLabelDto) _then;

/// Create a copy of GeoLabelDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = freezed,}) {
  return _then(GeoLabelDto(
label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GeoLabelDto].
extension GeoLabelDtoPatterns on GeoLabelDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GeoLabelDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GeoLabelDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GeoLabelDto value)  $default,){
final _that = this;
switch (_that) {
case _GeoLabelDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GeoLabelDto value)?  $default,){
final _that = this;
switch (_that) {
case _GeoLabelDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GeoLabelDto() when $default != null:
return $default(_that.label);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? label)  $default,) {final _that = this;
switch (_that) {
case _GeoLabelDto():
return $default(_that.label);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? label)?  $default,) {final _that = this;
switch (_that) {
case _GeoLabelDto() when $default != null:
return $default(_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GeoLabelDto implements GeoLabelDto {
  const _GeoLabelDto({this.label});
  factory _GeoLabelDto.fromJson(Map<String, dynamic> json) => _$GeoLabelDtoFromJson(json);

@override final  String? label;

/// Create a copy of GeoLabelDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GeoLabelDtoCopyWith<_GeoLabelDto> get copyWith => __$GeoLabelDtoCopyWithImpl<_GeoLabelDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GeoLabelDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GeoLabelDto&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,label);
}

@override
String toString() {
    return 'GeoLabelDto(label: $label)';
}


}

/// @nodoc
abstract mixin class _$GeoLabelDtoCopyWith<$Res> implements $GeoLabelDtoCopyWith<$Res> {
  factory _$GeoLabelDtoCopyWith(_GeoLabelDto value, $Res Function(_GeoLabelDto) _then) = __$GeoLabelDtoCopyWithImpl;
@override @useResult
$Res call({
 String? label
});




}
/// @nodoc
class __$GeoLabelDtoCopyWithImpl<$Res>
    implements _$GeoLabelDtoCopyWith<$Res> {
  __$GeoLabelDtoCopyWithImpl(this._self, this._then);

  final _GeoLabelDto _self;
  final $Res Function(_GeoLabelDto) _then;

/// Create a copy of GeoLabelDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = freezed,}) {
  return _then(_GeoLabelDto(
label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$GeoResultDto {

 String get label; double get lat; double get lng;
/// Create a copy of GeoResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GeoResultDtoCopyWith<GeoResultDto> get copyWith => _$GeoResultDtoCopyWithImpl<GeoResultDto>(this as GeoResultDto, _$identity);

  /// Serializes this GeoResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GeoResultDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GeoResultDto&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.lat, _this.lat) || other.lat == _this.lat)&&(identical(other.lng, _this.lng) || other.lng == _this.lng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GeoResultDto;
  return Object.hash(runtimeType,_this.label,_this.lat,_this.lng);
}

@override
String toString() {
  final _this = this as GeoResultDto;
  return 'GeoResultDto(label: ${_this.label}, lat: ${_this.lat}, lng: ${_this.lng})';
}


}

/// @nodoc
abstract mixin class $GeoResultDtoCopyWith<$Res>  {
  factory $GeoResultDtoCopyWith(GeoResultDto value, $Res Function(GeoResultDto) _then) = _$GeoResultDtoCopyWithImpl;
@useResult
$Res call({
 String label, double lat, double lng
});




}
/// @nodoc
class _$GeoResultDtoCopyWithImpl<$Res>
    implements $GeoResultDtoCopyWith<$Res> {
  _$GeoResultDtoCopyWithImpl(this._self, this._then);

  final GeoResultDto _self;
  final $Res Function(GeoResultDto) _then;

/// Create a copy of GeoResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? lat = null,Object? lng = null,}) {
  return _then(GeoResultDto(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [GeoResultDto].
extension GeoResultDtoPatterns on GeoResultDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GeoResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GeoResultDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GeoResultDto value)  $default,){
final _that = this;
switch (_that) {
case _GeoResultDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GeoResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _GeoResultDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  double lat,  double lng)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GeoResultDto() when $default != null:
return $default(_that.label,_that.lat,_that.lng);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  double lat,  double lng)  $default,) {final _that = this;
switch (_that) {
case _GeoResultDto():
return $default(_that.label,_that.lat,_that.lng);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  double lat,  double lng)?  $default,) {final _that = this;
switch (_that) {
case _GeoResultDto() when $default != null:
return $default(_that.label,_that.lat,_that.lng);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GeoResultDto extends GeoResultDto {
  const _GeoResultDto({required this.label, required this.lat, required this.lng}): super._();
  factory _GeoResultDto.fromJson(Map<String, dynamic> json) => _$GeoResultDtoFromJson(json);

@override final  String label;
@override final  double lat;
@override final  double lng;

/// Create a copy of GeoResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GeoResultDtoCopyWith<_GeoResultDto> get copyWith => __$GeoResultDtoCopyWithImpl<_GeoResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GeoResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GeoResultDto&&(identical(other.label, label) || other.label == label)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,label,lat,lng);
}

@override
String toString() {
    return 'GeoResultDto(label: $label, lat: $lat, lng: $lng)';
}


}

/// @nodoc
abstract mixin class _$GeoResultDtoCopyWith<$Res> implements $GeoResultDtoCopyWith<$Res> {
  factory _$GeoResultDtoCopyWith(_GeoResultDto value, $Res Function(_GeoResultDto) _then) = __$GeoResultDtoCopyWithImpl;
@override @useResult
$Res call({
 String label, double lat, double lng
});




}
/// @nodoc
class __$GeoResultDtoCopyWithImpl<$Res>
    implements _$GeoResultDtoCopyWith<$Res> {
  __$GeoResultDtoCopyWithImpl(this._self, this._then);

  final _GeoResultDto _self;
  final $Res Function(_GeoResultDto) _then;

/// Create a copy of GeoResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? lat = null,Object? lng = null,}) {
  return _then(_GeoResultDto(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$GeoSearchDto {

 List<GeoResultDto> get results;
/// Create a copy of GeoSearchDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GeoSearchDtoCopyWith<GeoSearchDto> get copyWith => _$GeoSearchDtoCopyWithImpl<GeoSearchDto>(this as GeoSearchDto, _$identity);

  /// Serializes this GeoSearchDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GeoSearchDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GeoSearchDto&&const DeepCollectionEquality().equals(other.results, _this.results));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GeoSearchDto;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.results));
}

@override
String toString() {
  final _this = this as GeoSearchDto;
  return 'GeoSearchDto(results: ${_this.results})';
}


}

/// @nodoc
abstract mixin class $GeoSearchDtoCopyWith<$Res>  {
  factory $GeoSearchDtoCopyWith(GeoSearchDto value, $Res Function(GeoSearchDto) _then) = _$GeoSearchDtoCopyWithImpl;
@useResult
$Res call({
 List<GeoResultDto> results
});




}
/// @nodoc
class _$GeoSearchDtoCopyWithImpl<$Res>
    implements $GeoSearchDtoCopyWith<$Res> {
  _$GeoSearchDtoCopyWithImpl(this._self, this._then);

  final GeoSearchDto _self;
  final $Res Function(GeoSearchDto) _then;

/// Create a copy of GeoSearchDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? results = null,}) {
  return _then(GeoSearchDto(
results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<GeoResultDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [GeoSearchDto].
extension GeoSearchDtoPatterns on GeoSearchDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GeoSearchDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GeoSearchDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GeoSearchDto value)  $default,){
final _that = this;
switch (_that) {
case _GeoSearchDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GeoSearchDto value)?  $default,){
final _that = this;
switch (_that) {
case _GeoSearchDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<GeoResultDto> results)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GeoSearchDto() when $default != null:
return $default(_that.results);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<GeoResultDto> results)  $default,) {final _that = this;
switch (_that) {
case _GeoSearchDto():
return $default(_that.results);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<GeoResultDto> results)?  $default,) {final _that = this;
switch (_that) {
case _GeoSearchDto() when $default != null:
return $default(_that.results);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GeoSearchDto implements GeoSearchDto {
  const _GeoSearchDto({required  List<GeoResultDto> results}): _results = results;
  factory _GeoSearchDto.fromJson(Map<String, dynamic> json) => _$GeoSearchDtoFromJson(json);

 final  List<GeoResultDto> _results;
@override List<GeoResultDto> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}


/// Create a copy of GeoSearchDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GeoSearchDtoCopyWith<_GeoSearchDto> get copyWith => __$GeoSearchDtoCopyWithImpl<_GeoSearchDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GeoSearchDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GeoSearchDto&&const DeepCollectionEquality().equals(other.results, _results));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_results));
}

@override
String toString() {
    return 'GeoSearchDto(results: $results)';
}


}

/// @nodoc
abstract mixin class _$GeoSearchDtoCopyWith<$Res> implements $GeoSearchDtoCopyWith<$Res> {
  factory _$GeoSearchDtoCopyWith(_GeoSearchDto value, $Res Function(_GeoSearchDto) _then) = __$GeoSearchDtoCopyWithImpl;
@override @useResult
$Res call({
 List<GeoResultDto> results
});




}
/// @nodoc
class __$GeoSearchDtoCopyWithImpl<$Res>
    implements _$GeoSearchDtoCopyWith<$Res> {
  __$GeoSearchDtoCopyWithImpl(this._self, this._then);

  final _GeoSearchDto _self;
  final $Res Function(_GeoSearchDto) _then;

/// Create a copy of GeoSearchDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? results = null,}) {
  return _then(_GeoSearchDto(
results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<GeoResultDto>,
  ));
}


}

// dart format on
