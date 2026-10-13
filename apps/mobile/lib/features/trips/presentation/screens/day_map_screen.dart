import 'dart:async';

import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/l10n/l10n.dart';
import 'package:driver_diary/core/time/calendar_day.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/presentation/providers/trips_providers.dart';
import 'package:driver_diary/features/trips/presentation/screens/trip_details_screen.dart';
import 'package:driver_diary/features/trips/presentation/widgets/trip_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the map of [day]: the signed-in driver's trips, or (admin) all
/// drivers' or one driver's ([driverId]); [filter] names the admin's
/// choice («Все водители», «Водитель 2»).
Future<void> openDayMap(
  BuildContext context, {
  required CalendarDay day,
  String? driverId,
  String? filter,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => DayMapScreen(day: day, driverId: driverId, filter: filter),
  ),
);

/// Every route of a day on one map, DESIGN.md §9.5. Under the map, the
/// legend is the list of the day's trips (time · amount, A → B): a screen
/// reader gets each trip there, and each row opens its details, like a tap
/// on its route.
class DayMapScreen extends ConsumerWidget {
  const new({required this.day, this.driverId, this.filter, super.key});

  final CalendarDay day;
  final String? driverId;
  final String? filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final trips = [
      for (final trip
          in ref.watch(dayTripsProvider(day, driverId: driverId)).value ??
              const <Trip>[])
        if (trip.hasPlaces) trip,
    ];
    final routes = [for (final t in trips) ?dkRouteOf(t)];
    final fit = fitPointsOf(trips);
    final byId = {for (final t in trips) t.id: t};
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DkModalAppBar(
              title: l10n.dayMap,
              leadingIcon: DkIcons.previous,
              closeLabel: l10n.back,
              onClose: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: fit.isEmpty
                  ? const SizedBox.shrink()
                  : DkMapView(
                      tiles: ref.watch(mapTilesProvider),
                      fit: fit,
                      center: fit.first,
                      rounded: false,
                      extraAttribution: showsOrsRoute(trips)
                          ? orsAttribution
                          : null,
                      onAttributionTap: () => openMapCredits(context),
                      attributionLabel: l10n.mapCredits,
                      semanticsLabel: l10n.dayMap,
                      layers: [
                        DkRouteLayer(
                          routes: routes,
                          onTap: (id) {
                            if (byId[id] case final trip?) {
                              unawaited(openTripDetails(context, trip));
                            }
                          },
                        ),
                        DkPlaceMarkers(
                          places: [
                            for (final t in trips) ...markersOf(t, l10n),
                          ],
                        ),
                      ],
                    ),
            ),
            _Legend(day: day, trips: trips, filter: filter),
          ],
        ),
      ),
    );
  }
}

/// «N маршрутов» and the date (with the admin's filter), then the trips.
class _Legend extends ConsumerWidget {
  const new({required this.day, required this.trips, this.filter});

  final CalendarDay day;
  final List<Trip> trips;
  final String? filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.dkColors;
    final text = context.dkText;
    final spacing = context.dkSpacing;
    final zone = ref.watch(driverZoneProvider);
    final date = l10n.date(day.toDateTime());
    String clock(DateTime instant) {
      final local = zone.wallClock(instant);
      return DkFormat.clock(local.hour, local.minute);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: context.dkElevation.e3,
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          // The map keeps most of the screen; a long day scrolls here.
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.4,
          ),
          child: ListView(
            shrinkWrap: true,
            // Rows have their own 16 side padding (DkListRow).
            padding: EdgeInsets.only(top: spacing.s16, bottom: spacing.s8),
            children: [
              Semantics(
                header: true,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing.s16),
                  child: DkFitLines([
                    DkLine(
                      l10n.routesCount(trips.length),
                      style: text.titleM.copyWith(color: colors.textPrimary),
                    ),
                    DkLine(
                      filter == null ? date : '$filter · $date',
                      style: text.caption.copyWith(color: colors.textTertiary),
                    ),
                  ]),
                ),
              ),
              SizedBox(height: spacing.s8),
              for (final trip in trips)
                DkListRow(
                  title: l10n.dayMapTrip(
                    DkFormat.timeRange(clock(trip.start), clock(trip.end)),
                    DkMoney.format(trip.amount),
                  ),
                  subtitle: routeLine(trip, l10n),
                  onTap: () => openTripDetails(context, trip),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
