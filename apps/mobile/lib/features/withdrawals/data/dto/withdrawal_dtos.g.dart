// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdrawal_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WithdrawalDto _$WithdrawalDtoFromJson(Map<String, dynamic> json) =>
    _WithdrawalDto(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      amount: (json['amount'] as num).toInt(),
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      rejectReason: json['reject_reason'] as String?,
    );

Map<String, dynamic> _$WithdrawalDtoToJson(_WithdrawalDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'driver_id': instance.driverId,
      'amount': instance.amount,
      'status': instance.status,
      'created_at': instance.createdAt,
      'reject_reason': instance.rejectReason,
    };

_BalanceDto _$BalanceDtoFromJson(Map<String, dynamic> json) => _BalanceDto(
  available: (json['available'] as num).toInt(),
  cardTotal: (json['card_total'] as num).toInt(),
  commissionTotal: (json['commission_total'] as num).toInt(),
  withdrawnTotal: (json['withdrawn_total'] as num).toInt(),
);

Map<String, dynamic> _$BalanceDtoToJson(_BalanceDto instance) =>
    <String, dynamic>{
      'available': instance.available,
      'card_total': instance.cardTotal,
      'commission_total': instance.commissionTotal,
      'withdrawn_total': instance.withdrawnTotal,
    };
