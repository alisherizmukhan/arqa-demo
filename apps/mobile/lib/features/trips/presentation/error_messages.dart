import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/l10n/failure_messages.dart';
import 'package:driver_diary/core/l10n/l10n.dart';

export 'package:driver_diary/core/l10n/failure_messages.dart' show isTransient;

/// Form-only validation codes (the others are shared with the server).
abstract final class TripFormCode {
  static const required = 'required';
  static const notInteger = 'not_integer';
}

/// Text for a failure shown in the add-trip form's snackbar.
String failureMessage(AppLocalizations l10n, Failure failure) =>
    switch (failure) {
      ConflictFailure(code: 'trip_conflict') => l10n.conflictTitle,
      ValidationFailure(:final code) => validationMessage(l10n, code),
      _ => commonFailureMessage(l10n, failure, offline: l10n.tripOffline),
    };

/// Text for a validation code, shared by the client-side rules and the
/// server's 422 responses (`commission_exceeds_amount`, ...).
String validationMessage(AppLocalizations l10n, String code) => switch (code) {
  TripFormCode.required => l10n.errRequired,
  TripFormCode.notInteger => l10n.errNotInteger,
  'invalid_amount' => l10n.errAmount,
  'amount_too_large' => l10n.errAmountTooLarge,
  'invalid_commission' => l10n.errCommissionNegative,
  'commission_exceeds_amount' => l10n.errCommissionGtAmount,
  // The form allows at most 12 h, so a too-long trip reads as a wrong end.
  'invalid_time_range' || 'trip_too_long' => l10n.errEndBeforeStart,
  'datetime_out_of_range' => l10n.errDateOutOfRange,
  'naive_datetime' || 'invalid_datetime' => l10n.errInvalidTime,
  'invalid_payment' => l10n.errInvalidPayment,
  _ => l10n.errTripGeneric,
};
