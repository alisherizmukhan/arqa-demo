import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/format/date_format.dart';
import 'package:driver_diary/core/time/driver_zone.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:flutter/material.dart';

/// The day's trips in one card, in start order.
class TripList extends StatelessWidget {
  const new({required this.trips, required this.zone, super.key});

  final List<Trip> trips;
  final DriverZone zone;

  @override
  Widget build(BuildContext context) {
    return DkTripList(
      children: [
        for (final trip in trips)
          DkTripTile(
            timeRange: formatTimeRange(trip.start, trip.end, zone),
            endsNextDay: zone.dayOf(trip.end) != zone.dayOf(trip.start),
            meta:
                '${DkFormat.duration(trip.end.difference(trip.start))} · '
                '${trip.payment.toKit().label}',
            amount: DkMoney.format(trip.amount),
            commission: 'комиссия ${DkMoney.format(trip.commission)}',
            method: trip.payment.toKit(),
          ),
      ],
    );
  }
}

extension PaymentMethodKit on PaymentMethod {
  /// The design kit's counterpart (the kit does not depend on the domain).
  DkPaymentMethod toKit() => switch (this) {
    PaymentMethod.cash => DkPaymentMethod.cash,
    PaymentMethod.card => DkPaymentMethod.card,
  };
}
