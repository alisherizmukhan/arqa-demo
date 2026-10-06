import 'package:driver_diary/core/time/calendar_day.dart';
import 'package:driver_diary/core/time/driver_zone.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/domain/entities/trip_rules.dart';
import 'package:driver_diary/features/trips/presentation/error_messages.dart';
import 'package:meta/meta.dart';

/// A wall-clock time picked in the form.
typedef ClockTime = ({int hour, int minute});

/// Raw state of the add-trip form. Pure Dart, so it is unit-tested directly.
@immutable
final class TripFormInput {
  const new({
    required this.day,
    this.start,
    this.end,
    this.amountText = '',
    this.commissionText = '',
    this.payment = PaymentMethod.card,
  });

  final CalendarDay day;
  final ClockTime? start;
  final ClockTime? end;
  final String amountText;
  final String commissionText;
  final PaymentMethod payment;

  /// An end time before the start time means the trip ended after midnight
  /// (23:50 – 00:20). Equal times are not "next day": that is an error.
  bool get endsNextDay {
    final (s, e) = (start, end);
    return s != null && e != null && _minutes(e) < _minutes(s);
  }

  static int _minutes(ClockTime t) => t.hour * 60 + t.minute;
}

/// Outcome of validating the form.
sealed class TripFormResult {
  const new();
}

/// All good: [trip] is ready to send.
final class TripFormValid extends TripFormResult {
  const new(this.trip);

  final Trip trip;
}

/// Errors to show under the fields.
final class TripFormInvalid extends TripFormResult {
  const new(this.errors);

  final Map<TripField, String> errors;
}

/// Checks that every field is filled in and parsable, then applies the same
/// business rules as the server (`validateTrip`).
TripFormResult validateTripForm(
  TripFormInput input, {
  required DriverZone zone,
  required String id,
}) {
  final errors = <TripField, String>{};
  final start = input.start;
  final end = input.end;
  if (start == null) errors[TripField.start] = 'Укажите время начала';
  if (end == null) errors[TripField.end] = 'Укажите время окончания';
  final amount = _parseTenge(
    input.amountText,
    'Укажите сумму',
    errors,
    TripField.amount,
  );
  final commission = _parseTenge(
    input.commissionText,
    'Укажите комиссию',
    errors,
    TripField.commission,
  );
  void report(List<TripRuleViolation> violations) {
    for (final violation in violations) {
      errors.putIfAbsent(
        violation.field,
        () => validationMessage(violation.code),
      );
    }
  }

  // Each rule group runs as soon as its own fields are filled in.
  if (amount != null && commission != null) {
    report(validateMoney(amount, commission));
  }
  ({DateTime start, DateTime end})? times;
  if (start != null && end != null) {
    final endDay = input.endsNextDay ? input.day.addDays(1) : input.day;
    times = (
      start: zone.instantAt(input.day, start.hour, start.minute),
      end: zone.instantAt(endDay, end.hour, end.minute),
    );
    report(validateTimes(times.start, times.end));
  }

  if (errors.isNotEmpty || times == null) return TripFormInvalid(errors);
  return TripFormValid(
    Trip(
      id: id,
      start: times.start,
      end: times.end,
      amount: amount!,
      payment: input.payment,
      commission: commission!,
    ),
  );
}

int? _parseTenge(
  String text,
  String emptyMessage,
  Map<TripField, String> errors,
  TripField field,
) {
  // Money fields group digits with U+202F while typing.
  final trimmed = text.replaceAll(' ', '').trim();
  if (trimmed.isEmpty) {
    errors[field] = emptyMessage;
    return null;
  }
  final value = RegExp(r'^\d{1,9}$').hasMatch(trimmed)
      ? int.parse(trimmed)
      : null;
  if (value == null) errors[field] = 'Введите целое число тенге';
  return value;
}
