import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/l10n/strings_ru.dart';
import 'package:driver_diary/core/time/driver_zone.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:flutter/material.dart';

/// «Поездки» header and the day's trips in one card, in start order.
class TripList extends StatelessWidget {
  const new({
    required this.trips,
    required this.zone,
    this.highlightedId,
    super.key,
  });

  final List<Trip> trips;
  final DriverZone zone;

  /// A just-added trip, shown highlighted.
  final String? highlightedId;

  @override
  Widget build(BuildContext context) {
    final total = trips.fold(
      Duration.zero,
      (sum, trip) => sum + trip.end.difference(trip.start),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: context.dkSpacing.s8,
      children: [
        DkListHeader(
          title: S.tripsTitle,
          trailing: S.tripsHeader(trips.length, total),
        ),
        DkTripList(
          children: [
            for (final trip in trips)
              DkTripTile(
                timeRange: DkFormat.timeRange(
                  _clock(trip.start),
                  _clock(trip.end),
                ),
                endsNextDay: zone.dayOf(trip.end) != zone.dayOf(trip.start),
                meta: S.tripMeta(
                  trip.end.difference(trip.start),
                  trip.payment.toKit().label,
                ),
                amount: DkMoney.format(trip.amount),
                commission: S.commissionLine(trip.commission),
                method: trip.payment.toKit(),
                highlighted: trip.id == highlightedId,
              ),
          ],
        ),
      ],
    );
  }

  String _clock(DateTime instant) {
    final local = zone.wallClock(instant);
    return DkFormat.clock(local.hour, local.minute);
  }
}

extension PaymentMethodKit on PaymentMethod {
  /// The design kit's counterpart (the kit does not depend on the domain).
  DkPaymentMethod toKit() => switch (this) {
    PaymentMethod.cash => DkPaymentMethod.cash,
    PaymentMethod.card => DkPaymentMethod.card,
  };
}
