import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/l10n/strings_ru.dart';
import 'package:driver_diary/core/time/calendar_day.dart';
import 'package:driver_diary/core/time/driver_zone.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/domain/entities/trip_rules.dart';
import 'package:driver_diary/features/trips/presentation/error_messages.dart';
import 'package:meta/meta.dart';

/// A wall-clock time picked in the form.
typedef ClockTime = ({int hour, int minute});

/// The form accepts trips up to 12 h (stricter than the server's 24 h; a
/// presentation rule from DESIGN.md §5.10).
const maxFormTripDuration = Duration(hours: 12);

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

  /// DESIGN.md §5.10: an end time at or before the start time on the clock
  /// means the trip ended the next day (23:50 – 00:20).
  bool get endsNextDay {
    final (s, e) = (start, end);
    return s != null && e != null && _minutes(e) <= _minutes(s);
  }

  /// Wall-clock length of the trip, once both times are picked.
  Duration? get duration {
    final (s, e) = (start, end);
    if (s == null || e == null) return null;
    final minutes = _minutes(e) - _minutes(s) + (endsNextDay ? 24 * 60 : 0);
    return Duration(minutes: minutes);
  }

  /// The day the trip ends on.
  CalendarDay get endDay => endsNextDay ? day.addDays(1) : day;

  /// Parsed amount; null when empty or not a number.
  int? get amount => _tenge(amountText);

  /// Parsed commission; null when empty or not a number.
  int? get commission => _tenge(commissionText);

  /// What the driver keeps from this trip, once both sums are valid.
  int? get net {
    final (a, c) = (amount, commission);
    if (a == null || c == null || validateMoney(a, c).isNotEmpty) return null;
    return a - c;
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
/// business rules as the server (`validateTrip`) plus the form's 12 h limit.
TripFormResult validateTripForm(
  TripFormInput input, {
  required DriverZone zone,
  required String id,
}) {
  final errors = <TripField, String>{};
  final start = input.start;
  final end = input.end;
  if (start == null) errors[TripField.start] = S.errRequired;
  if (end == null) errors[TripField.end] = S.errRequired;
  final amount = _parseTenge(input.amountText, errors, TripField.amount);
  final commission = _parseTenge(
    input.commissionText,
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

  // Each rule runs as soon as its own fields are filled in: the amount on
  // its own, the commission once both sums are known.
  if (amount != null) {
    final money = validateMoney(amount, commission ?? 0);
    report([
      for (final v in money)
        if (commission != null || v.field == TripField.amount) v,
    ]);
  }
  ({DateTime start, DateTime end})? times;
  if (start != null && end != null) {
    times = (
      start: zone.instantAt(input.day, start.hour, start.minute),
      end: zone.instantAt(input.endDay, end.hour, end.minute),
    );
    report(validateTimes(times.start, times.end));
    if (input.duration! > maxFormTripDuration) {
      errors.putIfAbsent(TripField.end, () => S.errEndBeforeStart);
    }
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

int? _parseTenge(String text, Map<TripField, String> errors, TripField field) {
  if (_digits(text).isEmpty) {
    errors[field] = S.errRequired;
    return null;
  }
  final value = _tenge(text);
  if (value == null) errors[field] = 'Введите целое число тенге';
  return value;
}

int? _tenge(String text) {
  final digits = _digits(text);
  return RegExp(r'^\d{1,9}$').hasMatch(digits) ? int.parse(digits) : null;
}

/// Money fields group digits with U+202F while typing.
String _digits(String text) => text.replaceAll(DkMoney.separator, '').trim();
