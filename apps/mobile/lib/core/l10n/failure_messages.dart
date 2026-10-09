import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/l10n/l10n.dart';

/// Whether sending again may succeed: no connection, a timeout, or a 5xx.
/// 4xx answers (400, 401, 409, 422, …) are final and are never resent.
bool isTransient(Failure failure) => switch (failure) {
  NetworkFailure() => true,
  ServerFailure(:final statusCode) => statusCode != null && statusCode >= 500,
  _ => false,
};

/// Localized text for a failure that has no screen-specific text: by kind
/// and error code, never the server's message. [offline] is the screen's
/// own «Нет связи…» line.
String commonFailureMessage(
  AppLocalizations l10n,
  Failure failure, {
  required String offline,
}) => switch (failure) {
  NetworkFailure() => offline,
  ServerFailure() when isTransient(failure) => l10n.errorServerUnavailable,
  RateLimitedFailure() => l10n.errRateLimited,
  ForbiddenFailure(code: 'account_disabled') => l10n.errAccountBlocked,
  ForbiddenFailure() => l10n.errorForbidden,
  ConflictFailure(code: 'demo_account_protected') => l10n.errDemoProtected,
  ConflictFailure(code: 'withdrawal_already_decided') => l10n.errAlreadyDecided,
  // Other 4xx (400, 401, 404, …): not something a retry fixes.
  _ => l10n.errorGeneric,
};
