import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/network/guard.dart';
import 'package:driver_diary/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:driver_diary/features/auth/domain/entities/app_user.dart';
import 'package:driver_diary/features/auth/domain/repositories/auth_repository.dart';

final class AuthRepositoryImpl implements AuthRepository {
  const new(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Future<Result<SignedInSession>> login(String login, String password) =>
      guardRequest(() async {
        final dto = await _remote.login(login, password);
        return (token: dto.token, user: dto.user.toDomain());
      });

  @override
  Future<Result<AppUser>> me() =>
      guardRequest(() async => (await _remote.me()).toDomain());

  @override
  Future<Result<void>> logout() => guardRequest(_remote.logout);
}
