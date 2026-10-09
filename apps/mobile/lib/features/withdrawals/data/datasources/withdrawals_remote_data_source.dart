import 'package:dio/dio.dart';
import 'package:driver_diary/core/network/guard.dart';
import 'package:driver_diary/core/network/retry_interceptor.dart';
import 'package:driver_diary/features/withdrawals/data/dto/withdrawal_dtos.dart';

/// HTTP calls for balances and withdrawals. Throws `DioException` /
/// `FormatException`; the repository maps them to failures.
class WithdrawalsRemoteDataSource {
  const new(this._dio);

  final Dio _dio;

  Future<BalanceDto> balance({String? driverId}) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/balance',
      queryParameters: {'driver_id': ?driverId},
    );
    return BalanceDto.fromJson(bodyOf(response));
  }

  Future<List<WithdrawalDto>> withdrawals({
    String? driverId,
    String? status,
  }) async {
    final response = await _dio.get<List<Object?>>(
      '/withdrawals',
      queryParameters: {'driver_id': ?driverId, 'status': ?status},
    );
    final items = response.data ?? (throw const FormatException('no body'));
    return [
      for (final item in items)
        WithdrawalDto.fromJson(item! as Map<String, Object?>),
    ];
  }

  /// Not retried by dio: the screen retries on a visible schedule with the
  /// same id instead.
  Future<WithdrawalDto> create({
    required String id,
    required int amount,
  }) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/withdrawals',
      data: {'id': id, 'amount': amount},
      options: Options(extra: RetryInterceptor.disabled),
    );
    return WithdrawalDto.fromJson(bodyOf(response));
  }

  Future<WithdrawalDto> approve(String id) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/admin/withdrawals/$id/approve',
    );
    return WithdrawalDto.fromJson(bodyOf(response));
  }

  Future<WithdrawalDto> reject(String id, String reason) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/admin/withdrawals/$id/reject',
      data: {'reason': reason},
    );
    return WithdrawalDto.fromJson(bodyOf(response));
  }
}
