import 'package:driver_diary/features/withdrawals/domain/entities/withdrawal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'withdrawal_dtos.freezed.dart';
part 'withdrawal_dtos.g.dart';

/// A withdrawal as the API returns it (`WithdrawalOut`).
@freezed
abstract class WithdrawalDto with _$WithdrawalDto {
  const factory({
    required String id,
    @JsonKey(name: 'driver_id') required String driverId,
    required int amount,
    required String status,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'reject_reason') String? rejectReason,
  }) = _WithdrawalDto;

  const new _();

  factory fromJson(Map<String, Object?> json) => _$WithdrawalDtoFromJson(json);

  /// Throws [FormatException] on an unknown status or a bad timestamp.
  Withdrawal toDomain() => Withdrawal(
    id: id,
    driverId: driverId,
    amount: amount,
    status: parseStatus(status),
    createdAt: DateTime.parse(createdAt).toUtc(),
    rejectReason: rejectReason,
  );

  static WithdrawalStatus parseStatus(String value) => switch (value) {
    'pending' => WithdrawalStatus.pending,
    'paid' => WithdrawalStatus.paid,
    'rejected' => WithdrawalStatus.rejected,
    _ => throw FormatException('unknown withdrawal status', value),
  };
}

/// `GET /balance` response.
@freezed
abstract class BalanceDto with _$BalanceDto {
  const factory({
    required int available,
    @JsonKey(name: 'card_total') required int cardTotal,
    @JsonKey(name: 'commission_total') required int commissionTotal,
    @JsonKey(name: 'withdrawn_total') required int withdrawnTotal,
  }) = _BalanceDto;

  const new _();

  factory fromJson(Map<String, Object?> json) => _$BalanceDtoFromJson(json);

  Balance toDomain() => Balance(
    available: available,
    cardTotal: cardTotal,
    commissionTotal: commissionTotal,
    withdrawnTotal: withdrawnTotal,
  );
}
