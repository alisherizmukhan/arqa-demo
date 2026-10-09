import 'package:dio/dio.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/network/guard.dart';
import 'package:driver_diary/features/admin/domain/admin.dart';
import 'package:driver_diary/features/auth/data/dto/auth_dtos.dart';

/// `/admin/users` calls (`AdminUserOut` is `UserOut` + `is_active`).
final class AdminRepositoryImpl implements AdminRepository {
  const new(this._dio);

  final Dio _dio;

  static Account _account(Object? json) {
    final map = json! as Map<String, Object?>;
    return Account(
      user: UserDto.fromJson(map).toDomain(),
      isActive: map['is_active']! as bool,
    );
  }

  @override
  Future<Result<List<Account>>> accounts() => guardRequest(() async {
    final response = await _dio.get<List<Object?>>('/admin/users');
    final items = response.data ?? (throw const FormatException('no body'));
    return [for (final item in items) _account(item)];
  });

  @override
  Future<Result<Account>> setActive(String userId, {required bool active}) =>
      guardRequest(() async {
        final response = await _dio.patch<Map<String, Object?>>(
          '/admin/users/$userId',
          data: {'is_active': active},
        );
        return _account(bodyOf(response));
      });

  @override
  Future<Result<int>> revokeSessions(String userId) => guardRequest(() async {
    final response = await _dio.post<Map<String, Object?>>(
      '/admin/users/$userId/revoke-sessions',
    );
    return bodyOf(response)['revoked']! as int;
  });
}
