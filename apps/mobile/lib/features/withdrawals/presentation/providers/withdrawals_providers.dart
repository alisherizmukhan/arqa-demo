import 'dart:async';

import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/l10n/failure_messages.dart';
import 'package:driver_diary/core/providers.dart';
import 'package:driver_diary/features/auth/presentation/providers/session_providers.dart';
import 'package:driver_diary/features/withdrawals/data/datasources/withdrawals_remote_data_source.dart';
import 'package:driver_diary/features/withdrawals/data/repositories/withdrawals_repository_impl.dart';
import 'package:driver_diary/features/withdrawals/domain/entities/withdrawal.dart';
import 'package:driver_diary/features/withdrawals/domain/repositories/withdrawals_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'withdrawals_providers.g.dart';

@Riverpod(keepAlive: true)
WithdrawalsRepository withdrawalsRepository(Ref ref) =>
    WithdrawalsRepositoryImpl(
      WithdrawalsRemoteDataSource(ref.watch(dioProvider)),
    );

/// The balance: the signed-in driver's, or (admin) [driverId]'s.
@riverpod
Future<Balance> balance(Ref ref, {String? driverId}) async {
  ref.watch(currentUserIdProvider);
  final result = await ref
      .watch(withdrawalsRepositoryProvider)
      .balance(driverId: driverId);
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
}

/// Withdrawals, newest first: the driver's own, or (admin) everyone's,
/// optionally only [status].
@riverpod
Future<List<Withdrawal>> withdrawals(
  Ref ref, {
  WithdrawalStatus? status,
}) async {
  ref.watch(currentUserIdProvider);
  final result = await ref
      .watch(withdrawalsRepositoryProvider)
      .withdrawals(status: status);
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
}

/// The id of a just-created withdrawal, highlighted for ~2 s (§8.4).
@Riverpod(keepAlive: true)
class HighlightedWithdrawal extends _$HighlightedWithdrawal {
  Timer? _timer;

  @override
  String? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  void flash(String id) {
    _timer?.cancel();
    state = id;
    _timer = Timer(DkMotion.highlight, () => state = null);
  }
}

/// Sending a withdrawal. Lives as long as the withdraw screen.
@riverpod
class WithdrawController extends _$WithdrawController {
  @override
  FutureOr<Withdrawal?> build() => null;

  /// Sends [amount] under [id] (the screen keeps the id across retries, so
  /// the server answers 200 with the stored request instead of a second
  /// one). [quietly] (automatic resends) keeps the state out of loading.
  Future<Result<Withdrawal>> send({
    required String id,
    required int amount,
    bool quietly = false,
  }) async {
    if (!quietly) state = const AsyncLoading();
    final result = await ref
        .read(withdrawalsRepositoryProvider)
        .create(id: id, amount: amount);
    if (!ref.mounted) return result;
    switch (result) {
      case Ok(:final value):
        ref
          ..invalidate(balanceProvider)
          ..invalidate(withdrawalsProvider);
        state = AsyncData(value);
      case Err(:final failure):
        if (!isTransient(failure)) ref.invalidate(balanceProvider);
        state = AsyncError(failure, StackTrace.current);
    }
    return result;
  }
}
