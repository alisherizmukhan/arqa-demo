import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/network/guard.dart';
import 'package:driver_diary/features/withdrawals/data/datasources/withdrawals_remote_data_source.dart';
import 'package:driver_diary/features/withdrawals/domain/entities/withdrawal.dart';
import 'package:driver_diary/features/withdrawals/domain/repositories/withdrawals_repository.dart';

final class WithdrawalsRepositoryImpl implements WithdrawalsRepository {
  const new(this._remote);

  final WithdrawalsRemoteDataSource _remote;

  @override
  Future<Result<Balance>> balance({String? driverId}) => guardRequest(
    () async => (await _remote.balance(driverId: driverId)).toDomain(),
  );

  @override
  Future<Result<List<Withdrawal>>> withdrawals({
    String? driverId,
    WithdrawalStatus? status,
  }) => guardRequest(() async {
    final items = await _remote.withdrawals(
      driverId: driverId,
      status: status?.name,
    );
    return [for (final item in items) item.toDomain()];
  });

  @override
  Future<Result<Withdrawal>> create({
    required String id,
    required int amount,
  }) => guardRequest(
    () async => (await _remote.create(id: id, amount: amount)).toDomain(),
  );

  @override
  Future<Result<Withdrawal>> approve(String id) =>
      guardRequest(() async => (await _remote.approve(id)).toDomain());

  @override
  Future<Result<Withdrawal>> reject(String id, String reason) =>
      guardRequest(() async => (await _remote.reject(id, reason)).toDomain());
}
