import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/l10n/strings_ru.dart';
import 'package:driver_diary/core/time/driver_zone.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/presentation/models/trip_order.dart';
import 'package:flutter/material.dart';

/// «Поездки» header with the sort button, and the day's trips in one card
/// in [order].
class TripList extends StatelessWidget {
  const new({
    required this.trips,
    required this.zone,
    required this.order,
    required this.onSort,
    this.highlightedId,
    this.highlightKey,
    super.key,
  });

  final List<Trip> trips;
  final DriverZone zone;

  /// How [trips] are ordered (they are sorted here).
  final TripOrder order;

  /// Opens the sort choices.
  final VoidCallback onSort;

  /// A just-added trip, shown highlighted.
  final String? highlightedId;

  /// Put on the highlighted row, so the screen can scroll to it.
  final GlobalKey? highlightKey;

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
          action: DkIconButton(
            icon: DkIcons.sort,
            label: S.sortButton(order.label),
            active: order != TripOrder.timeAscending,
            onPressed: onSort,
          ),
        ),
        DkTripList(
          children: [
            for (final trip in order.sort(trips))
              DkTripTile(
                key: trip.id == highlightedId ? highlightKey : null,
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

extension TripOrderLabel on TripOrder {
  /// «Сначала ранние», …
  String get label => switch (this) {
    TripOrder.timeAscending => S.orderTimeAscending,
    TripOrder.timeDescending => S.orderTimeDescending,
    TripOrder.amountDescending => S.orderAmountDescending,
    TripOrder.amountAscending => S.orderAmountAscending,
  };
}

extension PaymentMethodKit on PaymentMethod {
  /// The design kit's counterpart (the kit does not depend on the domain).
  DkPaymentMethod toKit() => switch (this) {
    PaymentMethod.cash => DkPaymentMethod.cash,
    PaymentMethod.card => DkPaymentMethod.card,
  };
}
