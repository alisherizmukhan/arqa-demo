// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'withdrawal_dtos.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WithdrawalDto {

 String get id;@JsonKey(name: 'driver_id') String get driverId; int get amount; String get status;@JsonKey(name: 'created_at') String get createdAt;@JsonKey(name: 'reject_reason') String? get rejectReason;
/// Create a copy of WithdrawalDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WithdrawalDtoCopyWith<WithdrawalDto> get copyWith => _$WithdrawalDtoCopyWithImpl<WithdrawalDto>(this as WithdrawalDto, _$identity);

  /// Serializes this WithdrawalDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WithdrawalDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WithdrawalDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.driverId, _this.driverId) || other.driverId == _this.driverId)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.rejectReason, _this.rejectReason) || other.rejectReason == _this.rejectReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WithdrawalDto;
  return Object.hash(runtimeType,_this.id,_this.driverId,_this.amount,_this.status,_this.createdAt,_this.rejectReason);
}

@override
String toString() {
  final _this = this as WithdrawalDto;
  return 'WithdrawalDto(id: ${_this.id}, driverId: ${_this.driverId}, amount: ${_this.amount}, status: ${_this.status}, createdAt: ${_this.createdAt}, rejectReason: ${_this.rejectReason})';
}


}

/// @nodoc
abstract mixin class $WithdrawalDtoCopyWith<$Res>  {
  factory $WithdrawalDtoCopyWith(WithdrawalDto value, $Res Function(WithdrawalDto) _then) = _$WithdrawalDtoCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'driver_id') String driverId, int amount, String status,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'reject_reason') String? rejectReason
});




}
/// @nodoc
class _$WithdrawalDtoCopyWithImpl<$Res>
    implements $WithdrawalDtoCopyWith<$Res> {
  _$WithdrawalDtoCopyWithImpl(this._self, this._then);

  final WithdrawalDto _self;
  final $Res Function(WithdrawalDto) _then;

/// Create a copy of WithdrawalDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? driverId = null,Object? amount = null,Object? status = null,Object? createdAt = null,Object? rejectReason = freezed,}) {
  return _then(WithdrawalDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,rejectReason: freezed == rejectReason ? _self.rejectReason : rejectReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WithdrawalDto].
extension WithdrawalDtoPatterns on WithdrawalDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WithdrawalDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WithdrawalDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WithdrawalDto value)  $default,){
final _that = this;
switch (_that) {
case _WithdrawalDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WithdrawalDto value)?  $default,){
final _that = this;
switch (_that) {
case _WithdrawalDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'driver_id')  String driverId,  int amount,  String status, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'reject_reason')  String? rejectReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WithdrawalDto() when $default != null:
return $default(_that.id,_that.driverId,_that.amount,_that.status,_that.createdAt,_that.rejectReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'driver_id')  String driverId,  int amount,  String status, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'reject_reason')  String? rejectReason)  $default,) {final _that = this;
switch (_that) {
case _WithdrawalDto():
return $default(_that.id,_that.driverId,_that.amount,_that.status,_that.createdAt,_that.rejectReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'driver_id')  String driverId,  int amount,  String status, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'reject_reason')  String? rejectReason)?  $default,) {final _that = this;
switch (_that) {
case _WithdrawalDto() when $default != null:
return $default(_that.id,_that.driverId,_that.amount,_that.status,_that.createdAt,_that.rejectReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WithdrawalDto extends WithdrawalDto {
  const _WithdrawalDto({required this.id, @JsonKey(name: 'driver_id') required this.driverId, required this.amount, required this.status, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'reject_reason') this.rejectReason}): super._();
  factory _WithdrawalDto.fromJson(Map<String, dynamic> json) => _$WithdrawalDtoFromJson(json);

@override final  String id;
@override@JsonKey(name: 'driver_id') final  String driverId;
@override final  int amount;
@override final  String status;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override@JsonKey(name: 'reject_reason') final  String? rejectReason;

/// Create a copy of WithdrawalDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WithdrawalDtoCopyWith<_WithdrawalDto> get copyWith => __$WithdrawalDtoCopyWithImpl<_WithdrawalDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WithdrawalDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WithdrawalDto&&(identical(other.id, id) || other.id == id)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.rejectReason, rejectReason) || other.rejectReason == rejectReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,driverId,amount,status,createdAt,rejectReason);
}

@override
String toString() {
    return 'WithdrawalDto(id: $id, driverId: $driverId, amount: $amount, status: $status, createdAt: $createdAt, rejectReason: $rejectReason)';
}


}

/// @nodoc
abstract mixin class _$WithdrawalDtoCopyWith<$Res> implements $WithdrawalDtoCopyWith<$Res> {
  factory _$WithdrawalDtoCopyWith(_WithdrawalDto value, $Res Function(_WithdrawalDto) _then) = __$WithdrawalDtoCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'driver_id') String driverId, int amount, String status,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'reject_reason') String? rejectReason
});




}
/// @nodoc
class __$WithdrawalDtoCopyWithImpl<$Res>
    implements _$WithdrawalDtoCopyWith<$Res> {
  __$WithdrawalDtoCopyWithImpl(this._self, this._then);

  final _WithdrawalDto _self;
  final $Res Function(_WithdrawalDto) _then;

/// Create a copy of WithdrawalDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? driverId = null,Object? amount = null,Object? status = null,Object? createdAt = null,Object? rejectReason = freezed,}) {
  return _then(_WithdrawalDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,rejectReason: freezed == rejectReason ? _self.rejectReason : rejectReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$BalanceDto {

 int get available;@JsonKey(name: 'card_total') int get cardTotal;@JsonKey(name: 'commission_total') int get commissionTotal;@JsonKey(name: 'withdrawn_total') int get withdrawnTotal;
/// Create a copy of BalanceDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BalanceDtoCopyWith<BalanceDto> get copyWith => _$BalanceDtoCopyWithImpl<BalanceDto>(this as BalanceDto, _$identity);

  /// Serializes this BalanceDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BalanceDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BalanceDto&&(identical(other.available, _this.available) || other.available == _this.available)&&(identical(other.cardTotal, _this.cardTotal) || other.cardTotal == _this.cardTotal)&&(identical(other.commissionTotal, _this.commissionTotal) || other.commissionTotal == _this.commissionTotal)&&(identical(other.withdrawnTotal, _this.withdrawnTotal) || other.withdrawnTotal == _this.withdrawnTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BalanceDto;
  return Object.hash(runtimeType,_this.available,_this.cardTotal,_this.commissionTotal,_this.withdrawnTotal);
}

@override
String toString() {
  final _this = this as BalanceDto;
  return 'BalanceDto(available: ${_this.available}, cardTotal: ${_this.cardTotal}, commissionTotal: ${_this.commissionTotal}, withdrawnTotal: ${_this.withdrawnTotal})';
}


}

/// @nodoc
abstract mixin class $BalanceDtoCopyWith<$Res>  {
  factory $BalanceDtoCopyWith(BalanceDto value, $Res Function(BalanceDto) _then) = _$BalanceDtoCopyWithImpl;
@useResult
$Res call({
 int available,@JsonKey(name: 'card_total') int cardTotal,@JsonKey(name: 'commission_total') int commissionTotal,@JsonKey(name: 'withdrawn_total') int withdrawnTotal
});




}
/// @nodoc
class _$BalanceDtoCopyWithImpl<$Res>
    implements $BalanceDtoCopyWith<$Res> {
  _$BalanceDtoCopyWithImpl(this._self, this._then);

  final BalanceDto _self;
  final $Res Function(BalanceDto) _then;

/// Create a copy of BalanceDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? available = null,Object? cardTotal = null,Object? commissionTotal = null,Object? withdrawnTotal = null,}) {
  return _then(BalanceDto(
available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as int,cardTotal: null == cardTotal ? _self.cardTotal : cardTotal // ignore: cast_nullable_to_non_nullable
as int,commissionTotal: null == commissionTotal ? _self.commissionTotal : commissionTotal // ignore: cast_nullable_to_non_nullable
as int,withdrawnTotal: null == withdrawnTotal ? _self.withdrawnTotal : withdrawnTotal // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BalanceDto].
extension BalanceDtoPatterns on BalanceDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BalanceDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BalanceDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BalanceDto value)  $default,){
final _that = this;
switch (_that) {
case _BalanceDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BalanceDto value)?  $default,){
final _that = this;
switch (_that) {
case _BalanceDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int available, @JsonKey(name: 'card_total')  int cardTotal, @JsonKey(name: 'commission_total')  int commissionTotal, @JsonKey(name: 'withdrawn_total')  int withdrawnTotal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BalanceDto() when $default != null:
return $default(_that.available,_that.cardTotal,_that.commissionTotal,_that.withdrawnTotal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int available, @JsonKey(name: 'card_total')  int cardTotal, @JsonKey(name: 'commission_total')  int commissionTotal, @JsonKey(name: 'withdrawn_total')  int withdrawnTotal)  $default,) {final _that = this;
switch (_that) {
case _BalanceDto():
return $default(_that.available,_that.cardTotal,_that.commissionTotal,_that.withdrawnTotal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int available, @JsonKey(name: 'card_total')  int cardTotal, @JsonKey(name: 'commission_total')  int commissionTotal, @JsonKey(name: 'withdrawn_total')  int withdrawnTotal)?  $default,) {final _that = this;
switch (_that) {
case _BalanceDto() when $default != null:
return $default(_that.available,_that.cardTotal,_that.commissionTotal,_that.withdrawnTotal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BalanceDto extends BalanceDto {
  const _BalanceDto({required this.available, @JsonKey(name: 'card_total') required this.cardTotal, @JsonKey(name: 'commission_total') required this.commissionTotal, @JsonKey(name: 'withdrawn_total') required this.withdrawnTotal}): super._();
  factory _BalanceDto.fromJson(Map<String, dynamic> json) => _$BalanceDtoFromJson(json);

@override final  int available;
@override@JsonKey(name: 'card_total') final  int cardTotal;
@override@JsonKey(name: 'commission_total') final  int commissionTotal;
@override@JsonKey(name: 'withdrawn_total') final  int withdrawnTotal;

/// Create a copy of BalanceDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BalanceDtoCopyWith<_BalanceDto> get copyWith => __$BalanceDtoCopyWithImpl<_BalanceDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BalanceDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BalanceDto&&(identical(other.available, available) || other.available == available)&&(identical(other.cardTotal, cardTotal) || other.cardTotal == cardTotal)&&(identical(other.commissionTotal, commissionTotal) || other.commissionTotal == commissionTotal)&&(identical(other.withdrawnTotal, withdrawnTotal) || other.withdrawnTotal == withdrawnTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,available,cardTotal,commissionTotal,withdrawnTotal);
}

@override
String toString() {
    return 'BalanceDto(available: $available, cardTotal: $cardTotal, commissionTotal: $commissionTotal, withdrawnTotal: $withdrawnTotal)';
}


}

/// @nodoc
abstract mixin class _$BalanceDtoCopyWith<$Res> implements $BalanceDtoCopyWith<$Res> {
  factory _$BalanceDtoCopyWith(_BalanceDto value, $Res Function(_BalanceDto) _then) = __$BalanceDtoCopyWithImpl;
@override @useResult
$Res call({
 int available,@JsonKey(name: 'card_total') int cardTotal,@JsonKey(name: 'commission_total') int commissionTotal,@JsonKey(name: 'withdrawn_total') int withdrawnTotal
});




}
/// @nodoc
class __$BalanceDtoCopyWithImpl<$Res>
    implements _$BalanceDtoCopyWith<$Res> {
  __$BalanceDtoCopyWithImpl(this._self, this._then);

  final _BalanceDto _self;
  final $Res Function(_BalanceDto) _then;

/// Create a copy of BalanceDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? available = null,Object? cardTotal = null,Object? commissionTotal = null,Object? withdrawnTotal = null,}) {
  return _then(_BalanceDto(
available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as int,cardTotal: null == cardTotal ? _self.cardTotal : cardTotal // ignore: cast_nullable_to_non_nullable
as int,commissionTotal: null == commissionTotal ? _self.commissionTotal : commissionTotal // ignore: cast_nullable_to_non_nullable
as int,withdrawnTotal: null == withdrawnTotal ? _self.withdrawnTotal : withdrawnTotal // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
