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

 String get id; String get start; String get end; int get amount; String get payment; int get commission;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.start, _this.start) || other.start == _this.start)&&(identical(other.end, _this.end) || other.end == _this.end)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.payment, _this.payment) || other.payment == _this.payment)&&(identical(other.commission, _this.commission) || other.commission == _this.commission));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TripDto;
  return Object.hash(runtimeType,_this.id,_this.start,_this.end,_this.amount,_this.payment,_this.commission);
}

@override
String toString() {
  final _this = this as TripDto;
  return 'TripDto(id: ${_this.id}, start: ${_this.start}, end: ${_this.end}, amount: ${_this.amount}, payment: ${_this.payment}, commission: ${_this.commission})';
}


}

/// @nodoc
abstract mixin class $TripDtoCopyWith<$Res>  {
  factory $TripDtoCopyWith(TripDto value, $Res Function(TripDto) _then) = _$TripDtoCopyWithImpl;
@useResult
$Res call({
 String id, String start, String end, int amount, String payment, int commission
});




}
/// @nodoc
class _$TripDtoCopyWithImpl<$Res>
    implements $TripDtoCopyWith<$Res> {
  _$TripDtoCopyWithImpl(this._self, this._then);

  final TripDto _self;
  final $Res Function(TripDto) _then;

/// Create a copy of TripDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? start = null,Object? end = null,Object? amount = null,Object? payment = null,Object? commission = null,}) {
  return _then(TripDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as String,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,payment: null == payment ? _self.payment : payment // ignore: cast_nullable_to_non_nullable
as String,commission: null == commission ? _self.commission : commission // ignore: cast_nullable_to_non_nullable
as int,
  ));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String start,  String end,  int amount,  String payment,  int commission)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripDto() when $default != null:
return $default(_that.id,_that.start,_that.end,_that.amount,_that.payment,_that.commission);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String start,  String end,  int amount,  String payment,  int commission)  $default,) {final _that = this;
switch (_that) {
case _TripDto():
return $default(_that.id,_that.start,_that.end,_that.amount,_that.payment,_that.commission);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String start,  String end,  int amount,  String payment,  int commission)?  $default,) {final _that = this;
switch (_that) {
case _TripDto() when $default != null:
return $default(_that.id,_that.start,_that.end,_that.amount,_that.payment,_that.commission);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripDto extends TripDto {
  const _TripDto({required this.id, required this.start, required this.end, required this.amount, required this.payment, required this.commission}): super._();
  factory _TripDto.fromJson(Map<String, dynamic> json) => _$TripDtoFromJson(json);

@override final  String id;
@override final  String start;
@override final  String end;
@override final  int amount;
@override final  String payment;
@override final  int commission;

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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripDto&&(identical(other.id, id) || other.id == id)&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.payment, payment) || other.payment == payment)&&(identical(other.commission, commission) || other.commission == commission));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,start,end,amount,payment,commission);
}

@override
String toString() {
    return 'TripDto(id: $id, start: $start, end: $end, amount: $amount, payment: $payment, commission: $commission)';
}


}

/// @nodoc
abstract mixin class _$TripDtoCopyWith<$Res> implements $TripDtoCopyWith<$Res> {
  factory _$TripDtoCopyWith(_TripDto value, $Res Function(_TripDto) _then) = __$TripDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String start, String end, int amount, String payment, int commission
});




}
/// @nodoc
class __$TripDtoCopyWithImpl<$Res>
    implements _$TripDtoCopyWith<$Res> {
  __$TripDtoCopyWithImpl(this._self, this._then);

  final _TripDto _self;
  final $Res Function(_TripDto) _then;

/// Create a copy of TripDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? start = null,Object? end = null,Object? amount = null,Object? payment = null,Object? commission = null,}) {
  return _then(_TripDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as String,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,payment: null == payment ? _self.payment : payment // ignore: cast_nullable_to_non_nullable
as String,commission: null == commission ? _self.commission : commission // ignore: cast_nullable_to_non_nullable
as int,
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

 String get id; String get start; String get end; int get amount; String get payment; int get commission;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateTripRequestDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.start, _this.start) || other.start == _this.start)&&(identical(other.end, _this.end) || other.end == _this.end)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.payment, _this.payment) || other.payment == _this.payment)&&(identical(other.commission, _this.commission) || other.commission == _this.commission));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CreateTripRequestDto;
  return Object.hash(runtimeType,_this.id,_this.start,_this.end,_this.amount,_this.payment,_this.commission);
}

@override
String toString() {
  final _this = this as CreateTripRequestDto;
  return 'CreateTripRequestDto(id: ${_this.id}, start: ${_this.start}, end: ${_this.end}, amount: ${_this.amount}, payment: ${_this.payment}, commission: ${_this.commission})';
}


}

/// @nodoc
abstract mixin class $CreateTripRequestDtoCopyWith<$Res>  {
  factory $CreateTripRequestDtoCopyWith(CreateTripRequestDto value, $Res Function(CreateTripRequestDto) _then) = _$CreateTripRequestDtoCopyWithImpl;
@useResult
$Res call({
 String id, String start, String end, int amount, String payment, int commission
});




}
/// @nodoc
class _$CreateTripRequestDtoCopyWithImpl<$Res>
    implements $CreateTripRequestDtoCopyWith<$Res> {
  _$CreateTripRequestDtoCopyWithImpl(this._self, this._then);

  final CreateTripRequestDto _self;
  final $Res Function(CreateTripRequestDto) _then;

/// Create a copy of CreateTripRequestDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? start = null,Object? end = null,Object? amount = null,Object? payment = null,Object? commission = null,}) {
  return _then(CreateTripRequestDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as String,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,payment: null == payment ? _self.payment : payment // ignore: cast_nullable_to_non_nullable
as String,commission: null == commission ? _self.commission : commission // ignore: cast_nullable_to_non_nullable
as int,
  ));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String start,  String end,  int amount,  String payment,  int commission)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateTripRequestDto() when $default != null:
return $default(_that.id,_that.start,_that.end,_that.amount,_that.payment,_that.commission);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String start,  String end,  int amount,  String payment,  int commission)  $default,) {final _that = this;
switch (_that) {
case _CreateTripRequestDto():
return $default(_that.id,_that.start,_that.end,_that.amount,_that.payment,_that.commission);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String start,  String end,  int amount,  String payment,  int commission)?  $default,) {final _that = this;
switch (_that) {
case _CreateTripRequestDto() when $default != null:
return $default(_that.id,_that.start,_that.end,_that.amount,_that.payment,_that.commission);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateTripRequestDto implements CreateTripRequestDto {
  const _CreateTripRequestDto({required this.id, required this.start, required this.end, required this.amount, required this.payment, required this.commission});
  factory _CreateTripRequestDto.fromJson(Map<String, dynamic> json) => _$CreateTripRequestDtoFromJson(json);

@override final  String id;
@override final  String start;
@override final  String end;
@override final  int amount;
@override final  String payment;
@override final  int commission;

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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateTripRequestDto&&(identical(other.id, id) || other.id == id)&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.payment, payment) || other.payment == payment)&&(identical(other.commission, commission) || other.commission == commission));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,start,end,amount,payment,commission);
}

@override
String toString() {
    return 'CreateTripRequestDto(id: $id, start: $start, end: $end, amount: $amount, payment: $payment, commission: $commission)';
}


}

/// @nodoc
abstract mixin class _$CreateTripRequestDtoCopyWith<$Res> implements $CreateTripRequestDtoCopyWith<$Res> {
  factory _$CreateTripRequestDtoCopyWith(_CreateTripRequestDto value, $Res Function(_CreateTripRequestDto) _then) = __$CreateTripRequestDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String start, String end, int amount, String payment, int commission
});




}
/// @nodoc
class __$CreateTripRequestDtoCopyWithImpl<$Res>
    implements _$CreateTripRequestDtoCopyWith<$Res> {
  __$CreateTripRequestDtoCopyWithImpl(this._self, this._then);

  final _CreateTripRequestDto _self;
  final $Res Function(_CreateTripRequestDto) _then;

/// Create a copy of CreateTripRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? start = null,Object? end = null,Object? amount = null,Object? payment = null,Object? commission = null,}) {
  return _then(_CreateTripRequestDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as String,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,payment: null == payment ? _self.payment : payment // ignore: cast_nullable_to_non_nullable
as String,commission: null == commission ? _self.commission : commission // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
