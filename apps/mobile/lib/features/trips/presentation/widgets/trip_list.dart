import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/l10n/l10n.dart';
import 'package:driver_diary/core/time/driver_zone.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/presentation/models/trip_order.dart';
import 'package:driver_diary/features/trips/presentation/providers/trips_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    this.driverNames,
    super.key,
  });

  /// Admin, all drivers: the driver's name under each row, by driver id.
  final Map<String, String>? driverNames;

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
    final l10n = context.l10n;
    final total = trips.fold(
      Duration.zero,
      (sum, trip) => sum + trip.end.difference(trip.start),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: context.dkSpacing.s8,
      children: [
        DkListHeader(
          title: l10n.tripsTitle,
          trailing: l10n.tripsHeader(trips.length, total),
          action: DkIconButton(
            icon: DkIcons.sort,
            label: l10n.sortButton(order.label(l10n).toLowerCase()),
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
                meta: l10n.tripMeta(
                  trip.end.difference(trip.start),
                  l10n.paymentLabel(trip.payment.toKit()),
                ),
                driver: driverNames?[trip.driverId],
                amount: DkMoney.format(trip.amount),
                commission: l10n.commissionLine(
                  DkMoney.format(trip.commission),
                ),
                method: trip.payment.toKit(),
                nextDayLabel: l10n.nextDayLabel,
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
  String label(AppLocalizations l10n) => switch (this) {
    TripOrder.timeAscending => l10n.orderTimeAscending,
    TripOrder.timeDescending => l10n.orderTimeDescending,
    TripOrder.amountDescending => l10n.orderAmountDescending,
    TripOrder.amountAscending => l10n.orderAmountAscending,
  };
}

extension PaymentMethodKit on PaymentMethod {
  /// The design kit's counterpart (the kit does not depend on the domain).
  DkPaymentMethod toKit() => switch (this) {
    PaymentMethod.cash => DkPaymentMethod.cash,
    PaymentMethod.card => DkPaymentMethod.card,
  };
}

/// The sort choices (an options sheet); the pick applies to every day.
Future<void> chooseTripOrder(BuildContext context, WidgetRef ref) async {
  final current = ref.read(tripOrderSettingProvider);
  final l10n = context.l10n;
  final picked = await showDkOptionsSheet<TripOrder>(
    context,
    title: l10n.sortTitle,
    options: [
      for (final order in TripOrder.values)
        (value: order, label: order.label(l10n)),
    ],
    selected: current,
  );
  if (picked == null || !context.mounted) return;
  ref.read(tripOrderSettingProvider.notifier).order = picked;
}
