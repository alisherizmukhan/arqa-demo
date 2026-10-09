import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/features/withdrawals/domain/entities/withdrawal.dart';

abstract interface class WithdrawalsRepository {
  /// The signed-in driver's balance, or (admin) one driver's / all drivers'.
  Future<Result<Balance>> balance({String? driverId});

  /// Newest first: the driver's own, or (admin) all / one driver's,
  /// optionally only [status].
  Future<Result<List<Withdrawal>>> withdrawals({
    String? driverId,
    WithdrawalStatus? status,
  });

  /// Creates a request idempotently by [id]: the same id and amount again is
  /// not a duplicate (200), so a retry after a network error is safe; the
  /// same id with another amount → `ConflictFailure` (`withdrawal_conflict`);
  /// more than available → `ValidationFailure` (`insufficient_funds`).
  Future<Result<Withdrawal>> create({required String id, required int amount});

  /// Admin: marks [id] paid. Repeating it is safe.
  Future<Result<Withdrawal>> approve(String id);

  /// Admin: rejects [id] with [reason] (shown to the driver); the money is
  /// available again.
  Future<Result<Withdrawal>> reject(String id, String reason);
}
