import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/features/auth/domain/entities/app_user.dart';

/// A new session: the opaque token and its account.
typedef SignedInSession = ({String token, AppUser user});

abstract interface class AuthRepository {
  /// Signs in. Wrong login or password → `UnauthorizedFailure`
  /// (`invalid_credentials`); a blocked account → `ForbiddenFailure`
  /// (`account_disabled`); too many attempts → `RateLimitedFailure`.
  Future<Result<SignedInSession>> login(String login, String password);

  /// The account of the token currently in use.
  Future<Result<AppUser>> me();

  /// Ends the current session on the server. Failures are ignored by the
  /// caller: the token is forgotten locally anyway.
  Future<Result<void>> logout();
}
