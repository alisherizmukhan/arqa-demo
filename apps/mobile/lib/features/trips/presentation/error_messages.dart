import 'package:driver_diary/core/error/failure.dart';

/// Russian text for a failure. Validation codes are shared by the client-side
/// rules and the server's 422 responses.
String failureMessage(Failure failure) => switch (failure) {
  NetworkFailure() =>
    'Нет связи с сервером. Проверьте интернет и попробуйте ещё раз.',
  ServerFailure() => 'Сервер временно недоступен. Попробуйте чуть позже.',
  ConflictFailure() =>
    'Эта поездка уже сохранена с другими данными. '
        'Нажмите «Сохранить» ещё раз, чтобы добавить её как новую.',
  ValidationFailure(:final code) => validationMessage(code),
  UnexpectedFailure() => 'Что-то пошло не так. Попробуйте ещё раз.',
};

/// Russian text for a validation code (`commission_exceeds_amount`, ...).
String validationMessage(String code) => switch (code) {
  'invalid_amount' => 'Сумма должна быть больше нуля',
  'amount_too_large' => 'Слишком большая сумма',
  'invalid_commission' => 'Комиссия не может быть отрицательной',
  'commission_exceeds_amount' => 'Комиссия не может быть больше суммы',
  'invalid_time_range' => 'Окончание должно быть позже начала',
  'trip_too_long' => 'Поездка не может длиться больше суток',
  'datetime_out_of_range' => 'Дата вне допустимого диапазона',
  'naive_datetime' || 'invalid_datetime' => 'Неверное время поездки',
  'invalid_payment' => 'Выберите способ оплаты',
  _ => 'Проверьте данные поездки',
};
