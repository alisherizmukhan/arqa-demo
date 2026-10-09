import 'dart:async';

import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/providers.dart';
import 'package:driver_diary/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:driver_diary/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:driver_diary/features/auth/data/token_store.dart';
import 'package:driver_diary/features/auth/domain/entities/app_user.dart';
import 'package:driver_diary/features/auth/domain/repositories/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    AuthRepositoryImpl(AuthRemoteDataSource(ref.watch(dioProvider)));

@Riverpod(keepAlive: true)
TokenStore tokenStore(Ref ref) => const SecureTokenStore();

/// Who is using the app.
sealed class SessionState {
  const new();
}

/// The login screen. [ended]: the server ended the session (401), so the
/// screen says «Сессия завершена. Войдите снова.».
final class SignedOut extends SessionState {
  const new({this.ended = false});

  final bool ended;
}

final class SignedIn extends SessionState {
  const new(this.user);

  final AppUser user;
}

/// The session. On start: a saved token is checked with `GET /auth/me`
/// (no token → signed out). An error other than 401 (offline) leaves the
/// state in error, and the app offers «Повторить». No logout by time.
@Riverpod(keepAlive: true)
class Session extends _$Session {
  @override
  Future<SessionState> build() async {
    final gate = ref.watch(authGateProvider);
    final subscription = gate.expired.listen((_) => unawaited(expire()));
    ref.onDispose(subscription.cancel);

    final store = ref.watch(tokenStoreProvider);
    final token = await store.read();
    if (token == null) return const SignedOut();
    gate.token = token;
    switch (await ref.read(authRepositoryProvider).me()) {
      case Ok(:final value):
        return SignedIn(value);
      case Err(failure: UnauthorizedFailure()):
        // Revoked while the app was closed: like any other 401.
        gate.token = null;
        await store.clear();
        return const SignedOut(ended: true);
      case Err(:final failure):
        throw failure;
    }
  }

  /// Signs in and keeps the token. Failures are returned for the form.
  Future<Result<AppUser>> signIn(String login, String password) async {
    final result = await ref
        .read(authRepositoryProvider)
        .login(login, password);
    switch (result) {
      case Ok(value: (:final token, :final user)):
        ref.read(authGateProvider).token = token;
        await ref.read(tokenStoreProvider).write(token);
        state = AsyncData(SignedIn(user));
        return Ok(user);
      case Err(:final failure):
        return Err(failure);
    }
  }

  /// «Выйти»: ends the session on the server if it can, and forgets the
  /// token either way (offline too: no retry later).
  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).logout();
    await _forget(ended: false);
  }

  /// A request got a 401: back to login with «Сессия завершена».
  Future<void> expire() async {
    if (state.value is! SignedIn) return;
    await _forget(ended: true);
  }

  Future<void> _forget({required bool ended}) async {
    ref.read(authGateProvider).token = null;
    state = AsyncData(SignedOut(ended: ended));
    await ref.read(tokenStoreProvider).clear();
  }
}

/// The signed-in account, or null.
@Riverpod(keepAlive: true)
AppUser? currentUser(Ref ref) => switch (ref.watch(sessionProvider).value) {
  SignedIn(:final user) => user,
  _ => null,
};

/// The signed-in account's id. Data providers watch it, so cached data never
/// outlives the session it was loaded for.
@Riverpod(keepAlive: true)
String? currentUserId(Ref ref) => ref.watch(currentUserProvider)?.id;
