import 'package:driver_diary/core/time/calendar_day.dart';
import 'package:driver_diary/core/time/driver_zone.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:meta/meta.dart';

/// Totals for one local day, in whole tenge.
///
/// Invariants: `net == revenue - commission`, `cash + card == revenue`.
@immutable
final class DailySummary {
  const new({
    required this.day,
    required this.tripsCount,
    required this.revenue,
    required this.commission,
    required this.net,
    required this.cash,
    required this.card,
  });

  final CalendarDay day;
  final int tripsCount;
  final int revenue;
  final int commission;
  final int net;
  final int cash;
  final int card;

  @override
  bool operator ==(Object other) =>
      other is DailySummary &&
      other.day == day &&
      other.tripsCount == tripsCount &&
      other.revenue == revenue &&
      other.commission == commission &&
      other.net == net &&
      other.cash == cash &&
      other.card == card;

  @override
  int get hashCode =>
      Object.hash(day, tripsCount, revenue, commission, net, cash, card);

  @override
  String toString() =>
      'DailySummary($day: $tripsCount trips, revenue $revenue, '
      'commission $commission, net $net, cash $cash, card $card)';
}

/// Sums the trips of [day]. Same rules as the backend's
/// `calculate_daily_summary`: every trip must start on [day] in [zone];
/// anything else is a caller bug and throws instead of being skipped.
DailySummary calculateDailySummary(
  CalendarDay day,
  Iterable<Trip> trips,
  DriverZone zone,
) {
  var count = 0;
  var revenue = 0;
  var commission = 0;
  var cash = 0;
  var card = 0;
  for (final trip in trips) {
    if (zone.dayOf(trip.start) != day) {
      throw ArgumentError.value(trip, 'trips', 'does not start on $day');
    }
    count++;
    revenue += trip.amount;
    commission += trip.commission;
    switch (trip.payment) {
      case PaymentMethod.cash:
        cash += trip.amount;
      case PaymentMethod.card:
        card += trip.amount;
    }
  }
  return DailySummary(
    day: day,
    tripsCount: count,
    revenue: revenue,
    commission: commission,
    net: revenue - commission,
    cash: cash,
    card: card,
  );
}
