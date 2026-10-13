import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/l10n/failure_messages.dart';
import 'package:driver_diary/core/l10n/l10n.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/domain/entities/trip_route.dart';
import 'package:driver_diary/features/trips/presentation/providers/trips_providers.dart';
import 'package:driver_diary/features/trips/presentation/widgets/trip_list.dart';
import 'package:driver_diary/features/trips/presentation/widgets/trip_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the details of [trip] (a trip with places).
Future<void> openTripDetails(BuildContext context, Trip trip) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TripDetailsScreen(tripId: trip.id, initial: trip),
      ),
    );

/// One trip with its route, DESIGN.md §9.4: the map (45 % of the screen),
/// time and amount, route stats, and the two places.
class TripDetailsScreen extends ConsumerStatefulWidget {
  const new({required this.tripId, this.initial, super.key});

  final String tripId;

  /// The trip as the list had it: shown at once while the details load.
  final Trip? initial;

  @override
  ConsumerState<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends ConsumerState<TripDetailsScreen> {
  bool _rebuilding = false;
  DkSnackbarHandle? _snack;

  @override
  void dispose() {
    _snack?.close();
    super.dispose();
  }

  Future<void> _rebuild() async {
    setState(() => _rebuilding = true);
    _snack?.close();
    final result = await ref
        .read(tripsRepositoryProvider)
        .rebuildRoute(widget.tripId, ref.read(driverZoneProvider));
    if (!mounted) return;
    setState(() => _rebuilding = false);
    switch (result) {
      case Ok():
        ref
          ..invalidate(tripDetailsProvider(widget.tripId))
          ..invalidate(dayTripsProvider);
      case Err(:final failure):
        _snack = showDkSnackbar(
          context,
          message: commonFailureMessage(
            context.l10n,
            failure,
            offline: context.l10n.loginOffline,
          ),
          tone: DkSnackTone.error,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final details = ref.watch(tripDetailsProvider(widget.tripId));
    final trip = details.value ?? widget.initial;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DkModalAppBar(
              title: l10n.tripDetailsTitle,
              leadingIcon: DkIcons.previous,
              closeLabel: l10n.back,
              onClose: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: switch ((trip, details)) {
                (final shown?, _) => _Content(
                  trip: shown,
                  rebuilding: _rebuilding,
                  onRebuild: _rebuild,
                ),
                (null, AsyncValue(:final error?)) => Center(
                  child: Padding(
                    padding: EdgeInsets.all(context.dkSpacing.screenGutter),
                    child: DkErrorState(
                      title: l10n.loadFailedTitle,
                      message: error is Failure
                          ? l10n.loadFailedMessage
                          : l10n.errorGeneric,
                      retryLabel: l10n.retry,
                      isRetrying: details.isLoading,
                      onRetry: () =>
                          ref.invalidate(tripDetailsProvider(widget.tripId)),
                    ),
                  ),
                ),
                _ => const _Loading(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const new({
    required this.trip,
    required this.rebuilding,
    required this.onRebuild,
  });

  final Trip trip;
  final bool rebuilding;
  final VoidCallback onRebuild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.dkColors;
    final text = context.dkText;
    final spacing = context.dkSpacing;
    final zone = ref.watch(driverZoneProvider);
    final route = trip.route;
    final line = dkRouteOf(trip);
    final metres = route.hasLine ? route.distanceMetres : null;
    final perKm = metres == null
        ? null
        : DkFormat.perKilometre(trip.amount, metres);
    final perMinute = DkFormat.perMinute(trip.amount, trip.duration);
    String clock(DateTime instant) {
      final local = zone.wallClock(instant);
      return DkFormat.clock(local.hour, local.minute);
    }

    final endsNextDay = zone.dayOf(trip.end) != zone.dayOf(trip.start);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        spacing.screenGutter,
        spacing.s8,
        spacing.screenGutter,
        spacing.s24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        if (trip.hasPlaces) ...[
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.45,
            child: DkMapView(
              semanticsLabel: l10n.routeTitle,
              tiles: ref.watch(mapTilesProvider),
              fit: fitPointsOf([trip]),
              extraAttribution: showsOrsRoute([trip]) ? orsAttribution : null,
              onAttributionTap: () => openMapCredits(context),
              attributionLabel: l10n.mapCredits,
              layers: [
                if (line != null) DkRouteLayer(routes: [line]),
                DkPlaceMarkers(places: markersOf(trip, l10n)),
              ],
            ),
          ),
          if (route.status == RouteStatus.straight) ...[
            SizedBox(height: spacing.s12),
            DkInfoRow(text: l10n.routeStraightInfo),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: DkButton(
                label: l10n.routeRebuild,
                icon: DkIcons.route,
                variant: DkButtonVariant.text,
                isLoading: rebuilding,
                onPressed: rebuilding ? null : onRebuild,
              ),
            ),
          ],
          SizedBox(height: spacing.s16),
        ],
        DkAmountRow(
          gap: spacing.s12,
          start: DkFitLines([
            DkLine.span(
              TextSpan(
                style: text.titleM.copyWith(color: colors.textPrimary),
                children: [
                  TextSpan(
                    text: DkFormat.timeRange(
                      clock(trip.start),
                      clock(trip.end),
                    ),
                  ),
                  if (endsNextDay)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.top,
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(start: spacing.s2),
                        child: Text(
                          '+1',
                          semanticsLabel: l10n.nextDayLabel,
                          style: text.superscript.copyWith(
                            color: colors.accent,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              text: DkFormat.timeRange(clock(trip.start), clock(trip.end)),
              ellipsis: false,
            ),
            DkLine(
              l10n.tripMeta(
                trip.duration,
                l10n.paymentLabel(trip.payment.toKit()),
              ),
              style: text.bodyS.copyWith(color: colors.textSecondary),
            ),
          ]),
          end: DkFitLines(textAlign: TextAlign.end, [
            DkLine(
              DkMoney.format(trip.amount),
              ellipsis: false,
              style: text.moneyM.copyWith(color: colors.textPrimary),
            ),
            DkLine(
              l10n.commissionLine(DkMoney.format(trip.commission)),
              ellipsis: false,
              style: text.caption.copyWith(color: colors.textTertiary),
            ),
          ]),
        ),
        if (trip.hasPlaces) ...[
          SizedBox(height: spacing.s16),
          DkRouteStats(
            stats: [
              (
                label: l10n.routeDistance,
                value: metres == null ? '—' : distanceText(metres, l10n),
              ),
              (
                label: l10n.routePerKm,
                value: perKm == null ? '—' : DkMoney.format(perKm),
              ),
              (
                label: l10n.routePerMinute,
                value: perMinute == null ? '—' : DkMoney.format(perMinute),
              ),
            ],
          ),
          SizedBox(height: spacing.s16),
          DkListGroup(
            children: [
              DkPlaceField(
                kind: DkPlaceKind.start,
                label: l10n.placeFrom,
                markerLabel: l10n.markerStart,
                value: trip.pickup!.displayLabel,
              ),
              DkPlaceField(
                kind: DkPlaceKind.end,
                label: l10n.placeTo,
                markerLabel: l10n.markerEnd,
                value: trip.dropoff!.displayLabel,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.screenGutter,
        vertical: spacing.s8,
      ),
      children: [
        LayoutBuilder(
          builder: (context, constraints) => DkSkeleton.line(
            width: constraints.maxWidth,
            height: MediaQuery.sizeOf(context).height * 0.45,
            radius: context.dkRadii.lg,
          ),
        ),
        SizedBox(height: spacing.s16),
        const DkSkeleton.line(width: 160, height: 20),
        SizedBox(height: spacing.s8),
        const DkSkeleton.line(width: 120, height: 14),
        SizedBox(height: spacing.s16),
        const DkSkeleton.summaryCard(),
      ],
    );
  }
}
