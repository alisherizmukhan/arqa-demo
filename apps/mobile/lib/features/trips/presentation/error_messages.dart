import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/l10n/strings_ru.dart';

/// Russian text for a failure shown in a snackbar. Validation codes are
/// shared by the client-side rules and the server's 422 responses.
String failureMessage(Failure failure) => switch (failure) {
  NetworkFailure() => S.offline,
  ServerFailure() when isTransient(failure) =>
    'Сервер временно недоступен. Попробуйте чуть позже.',
  // Other 4xx (400, 401, …): not something a retry fixes.
  ServerFailure() => 'Что-то пошло не так. Попробуйте ещё раз.',
  ConflictFailure() => S.conflictTitle,
  ValidationFailure(:final code) => validationMessage(code),
  UnexpectedFailure() => 'Что-то пошло не так. Попробуйте ещё раз.',
};

/// Whether sending again may succeed: no connection, a timeout, or a 5xx.
/// 4xx answers (400, 401, 409, 422, …) are final and are never resent.
bool isTransient(Failure failure) => switch (failure) {
  NetworkFailure() => true,
  ServerFailure(:final statusCode) => statusCode != null && statusCode >= 500,
  _ => false,
};

/// Russian text for a validation code (`commission_exceeds_amount`, ...).
String validationMessage(String code) => switch (code) {
  'invalid_amount' => S.errAmount,
  'amount_too_large' => 'Слишком большая сумма',
  'invalid_commission' => S.errCommissionNegative,
  'commission_exceeds_amount' => S.errCommissionGtAmount,
  // The form allows at most 12 h, so a too-long trip reads as a wrong end.
  'invalid_time_range' || 'trip_too_long' => S.errEndBeforeStart,
  'datetime_out_of_range' => 'Дата вне допустимого диапазона',
  'naive_datetime' || 'invalid_datetime' => 'Неверное время поездки',
  'invalid_payment' => 'Выберите способ оплаты',
  _ => 'Проверьте данные поездки',
};
