import 'package:meta/meta.dart';

/// Where a payout request is.
enum WithdrawalStatus { pending, paid, rejected }

/// A payout request. Money is whole tenge; times are UTC instants.
@immutable
final class Withdrawal {
  const new({
    required this.id,
    required this.driverId,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.rejectReason,
  });

  /// Client-generated UUID v4; doubles as the idempotency key.
  final String id;
  final String driverId;
  final int amount;
  final WithdrawalStatus status;
  final DateTime createdAt;

  /// The admin's reason, for a rejected request.
  final String? rejectReason;

  @override
  bool operator ==(Object other) =>
      other is Withdrawal &&
      other.id == id &&
      other.driverId == driverId &&
      other.amount == amount &&
      other.status == status &&
      other.createdAt.isAtSameMomentAs(createdAt) &&
      other.rejectReason == rejectReason;

  @override
  int get hashCode => Object.hash(
    id,
    driverId,
    amount,
    status,
    createdAt.toUtc(),
    rejectReason,
  );

  @override
  String toString() => 'Withdrawal($id, $amount, ${status.name})';
}

/// What the park owes a driver (DECISIONS.md, stage 3): card payments go to
/// the park, cash stays with the driver, the commission is owed on every
/// trip, and pending or paid withdrawals are already taken out.
@immutable
final class Balance {
  const new({
    required this.available,
    required this.cardTotal,
    required this.commissionTotal,
    required this.withdrawnTotal,
  });

  /// `cardTotal − commissionTotal − withdrawnTotal`; ≤ 0 means nothing can
  /// be withdrawn.
  final int available;
  final int cardTotal;
  final int commissionTotal;
  final int withdrawnTotal;

  @override
  bool operator ==(Object other) =>
      other is Balance &&
      other.available == available &&
      other.cardTotal == cardTotal &&
      other.commissionTotal == commissionTotal &&
      other.withdrawnTotal == withdrawnTotal;

  @override
  int get hashCode =>
      Object.hash(available, cardTotal, commissionTotal, withdrawnTotal);
}

/// Why an amount cannot be withdrawn, checked before sending (the server
/// checks again under a lock).
enum WithdrawAmountError {
  /// Empty, or 0.
  notPositive,

  /// More than the available balance.
  insufficient,
}

/// Null when [amount] can be requested from [balance].
WithdrawAmountError? validateWithdrawAmount(int? amount, Balance balance) {
  if (amount == null || amount <= 0) return WithdrawAmountError.notPositive;
  if (amount > balance.available) return WithdrawAmountError.insufficient;
  return null;
}
