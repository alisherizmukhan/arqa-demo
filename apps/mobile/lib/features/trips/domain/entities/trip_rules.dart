import 'package:driver_diary/features/trips/domain/entities/trip.dart';

/// Fields of a trip that a rule can point at.
enum TripField { start, end, amount, commission, payment }

/// Validation rules, mirroring the server so most mistakes never leave the
/// phone. Codes are the server's error codes, so client-side and server-side
/// errors share one set of messages.
enum TripRuleViolation {
  datetimeOutOfRange('datetime_out_of_range', TripField.start),
  invalidTimeRange('invalid_time_range', TripField.end),
  tripTooLong('trip_too_long', TripField.end),
  invalidAmount('invalid_amount', TripField.amount),
  amountTooLarge('amount_too_large', TripField.amount),
  invalidCommission('invalid_commission', TripField.commission),
  commissionExceedsAmount('commission_exceeds_amount', TripField.commission);

  new(this.code, this.field);

  final String code;
  final TripField field;
}

/// Same limits as the backend (`backend/app/domain/trip.py`).
abstract final class TripLimits {
  static const maxAmount = 10000000;
  static const maxDuration = Duration(hours: 24);
  static final minInstant = DateTime.utc(2000);
  static final maxInstant = DateTime.utc(2100);
}

/// All violations of [trip], at most one per field, in form order.
List<TripRuleViolation> validateTrip(Trip trip) => [
  ...validateTimes(trip.start, trip.end),
  ...validateMoney(trip.amount, trip.commission),
];

/// Time rules alone, so a form can check them before money is entered.
List<TripRuleViolation> validateTimes(DateTime start, DateTime end) {
  bool inRange(DateTime t) =>
      !t.isBefore(TripLimits.minInstant) && t.isBefore(TripLimits.maxInstant);

  if (!inRange(start) || !inRange(end)) {
    return const [TripRuleViolation.datetimeOutOfRange];
  }
  if (!end.isAfter(start)) return const [TripRuleViolation.invalidTimeRange];
  if (end.difference(start) > TripLimits.maxDuration) {
    return const [TripRuleViolation.tripTooLong];
  }
  return const [];
}

/// Money rules alone, so a form can check them before times are picked.
List<TripRuleViolation> validateMoney(int amount, int commission) => [
  if (amount <= 0)
    TripRuleViolation.invalidAmount
  else if (amount > TripLimits.maxAmount)
    TripRuleViolation.amountTooLarge,
  if (commission < 0)
    TripRuleViolation.invalidCommission
  else if (commission > amount)
    TripRuleViolation.commissionExceedsAmount,
];
