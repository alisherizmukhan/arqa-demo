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
    return DkCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (index, trip) in trips.indexed) ...[
            if (index > 0) const Divider(),
            DkTripTile(
              timeRange: formatTimeRange(trip.start, trip.end, zone),
              amount: trip.amount,
              payment: trip.payment.toKit(),
              details: 'комиссия ${DkMoney.format(trip.commission)}',
            ),
          ],
        ],
      ),
    );
  }
}

extension PaymentMethodKit on PaymentMethod {
  /// The design kit's counterpart (the kit does not depend on the domain).
  DkPaymentKind toKit() => switch (this) {
    PaymentMethod.cash => DkPaymentKind.cash,
    PaymentMethod.card => DkPaymentKind.card,
  };
}
