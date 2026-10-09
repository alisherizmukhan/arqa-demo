import 'dart:async';

import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/l10n/l10n.dart';
import 'package:driver_diary/core/time/calendar_day.dart';
import 'package:driver_diary/features/menu/presentation/screens/menu_screen.dart';
import 'package:driver_diary/features/trips/domain/entities/daily_summary.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/presentation/providers/trips_providers.dart';
import 'package:driver_diary/features/trips/presentation/screens/add_trip_screen.dart';
import 'package:driver_diary/features/trips/presentation/widgets/day_skeleton.dart';
import 'package:driver_diary/features/trips/presentation/widgets/day_switcher_bar.dart';
import 'package:driver_diary/features/trips/presentation/widgets/summary_card.dart';
import 'package:driver_diary/features/trips/presentation/widgets/trip_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the Day screen shows below the day switcher (DESIGN.md §5.1–5.4).
sealed class _DayView {
  const new();
}

final class _Loading extends _DayView {
  const new();
}

final class _Failed extends _DayView {
  const new({required this.retrying});

  final bool retrying;
}

final class _Loaded extends _DayView {
  const new(this.summary, this.trips);

  final DailySummary summary;
  final List<Trip> trips;
}

/// One day: wordmark, switcher, summary, trips, and the «+ Поездка» FAB.
class DayScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends ConsumerState<DayScreen> {
  final GlobalKey _fabKey = GlobalKey();

  /// On the highlighted (just-added) trip row: scrolled into view.
  final GlobalKey _newTripKey = GlobalKey();
  DkSnackbarHandle? _snack;

  @override
  void dispose() {
    _snack?.close();
    super.dispose();
  }

  _DayView _view(CalendarDay day) {
    // One provider per day: a cached day shows at once; another day's
    // totals can never be shown for this one.
    final summary = ref.watch(daySummaryProvider(day));
    final trips = ref.watch(dayTripsProvider(day));
    // Pull-to-refresh (and a failed refresh) keep the shown data.
    if ((summary.value, trips.value) case (final s?, final t?)) {
      return _Loaded(s, t);
    }
    if (summary.hasError) return _Failed(retrying: summary.isLoading);
    return const _Loading();
  }

  /// Loads the days next to [day] in the background, so stepping to them
  /// shows data without a skeleton (they stay cached, [dayCacheTtl]).
  void _prefetchNeighbours(CalendarDay day, CalendarDay today) {
    for (final neighbour in [day.addDays(-1), day.addDays(1)]) {
      if (neighbour.isAfter(today)) continue;
      ref.listen(dayTripsProvider(neighbour), (_, _) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final day = ref.watch(selectedDayProvider);
    final today = ref.watch(todayProvider);
    final selection = ref.read(selectedDayProvider.notifier);
    final view = _view(day);
    _prefetchNeighbours(day, today);
    final spacing = context.dkSpacing;
    final gutter = spacing.screenGutter;
    final showFab = switch (view) {
      _Loading() => true,
      _Loaded(:final summary) => summary.tripsCount > 0,
      _Failed() => false,
    };
    // The last row clears the FAB: 16 + FAB + 16.
    final bottomClearance =
        MediaQuery.paddingOf(context).bottom +
        spacing.s16 +
        context.dkSizes.buttonHeight +
        spacing.s16;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            // Pull-to-refresh must work in the empty and error states too.
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                sliver: SliverList.list(
                  children: [
                    DkWordmark(
                      title: l10n.appTitle,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (day != today)
                            DkTodayButton(
                              label: l10n.today,
                              onPressed: selection.today,
                            ),
                          // §8.2: the only change to this screen.
                          DkIconButton(
                            icon: DkIcons.menu,
                            label: l10n.menu,
                            onPressed: () => openMenu(context),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: spacing.s8),
                    const DaySwitcherBar(),
                  ],
                ),
              ),
              switch (view) {
                _Loaded(:final summary) when summary.tripsCount == 0 => _fill(
                  DkEmptyState(
                    title: l10n.emptyTitle,
                    message: l10n.emptyMessage,
                    actionLabel: l10n.emptyAction,
                    onAction: () => _addTrip(day),
                  ),
                ),
                _Failed(:final retrying) => _fill(
                  DkErrorState(
                    title: l10n.errorTitle,
                    message: l10n.errorMessage,
                    retryLabel: l10n.retry,
                    isRetrying: retrying,
                    onRetry: () => ref.invalidate(dayTripsProvider(day)),
                  ),
                ),
                _ => SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    spacing.s16,
                    gutter,
                    bottomClearance,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: switch (view) {
                      _Loaded(:final summary, :final trips) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: spacing.s16,
                        children: [
                          SummaryCard(summary: summary),
                          TripList(
                            trips: trips,
                            zone: ref.watch(driverZoneProvider),
                            order: ref.watch(tripOrderSettingProvider),
                            onSort: () => chooseTripOrder(context, ref),
                            highlightedId: ref.watch(highlightedTripProvider),
                            highlightKey: _newTripKey,
                          ),
                        ],
                      ),
                      _ => const DaySkeleton(),
                    },
                  ),
                ),
              },
            ],
          ),
        ),
      ),
      floatingActionButton: showFab
          ? DkFab(
              key: _fabKey,
              label: l10n.addTripFab,
              icon: DkIcons.add,
              onPressed: () => _addTrip(day),
            )
          : null,
    );
  }

  /// An empty/error state filling the rest of the screen, centred within
  /// the safe area and the screen gutters (as in mockups 03 and 05).
  Widget _fill(Widget state) => SliverFillRemaining(
    hasScrollBody: false,
    child: Padding(
      padding: EdgeInsets.only(
        left: context.dkSpacing.screenGutter,
        right: context.dkSpacing.screenGutter,
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
      child: state,
    ),
  );

  Future<void> _refresh() async {
    final day = ref.read(selectedDayProvider);
    try {
      ref.invalidate(dayTripsProvider(day));
      await ref.read(dayTripsProvider(day).future);
      _snack?.close();
    } on Object {
      // No data yet: the error state explains. With data: keep it (§5.4).
      if (!mounted || day != ref.read(selectedDayProvider)) return;
      if (!ref.read(daySummaryProvider(day)).hasValue) return;
      // Full width, 12 above the FAB: never over it.
      final fab = _fabKey.currentContext?.size?.height ?? 0;
      _snack = showDkSnackbar(
        context,
        message: context.l10n.errorTitle,
        tone: DkSnackTone.error,
        bottom:
            MediaQuery.paddingOf(context).bottom +
            context.dkSpacing.s16 +
            fab +
            context.dkSpacing.s12,
        actionLabel: context.l10n.retry,
        onAction: () {
          _snack?.close();
          ref.invalidate(dayTripsProvider(day));
        },
      );
    }
  }

  /// Scrolls the just-added trip to the middle of the screen, so it is seen
  /// even in a long list (and clear of the FAB and the snackbar).
  Future<void> _revealNewTrip() async {
    final animate = !MediaQuery.disableAnimationsOf(context);
    await WidgetsBinding.instance.endOfFrame;
    final row = _newTripKey.currentContext;
    if (row == null || !row.mounted) return;
    await Scrollable.ensureVisible(
      row,
      alignment: 0.5,
      duration: animate ? DkMotion.reveal : Duration.zero,
      curve: Curves.easeOut,
    );
  }

  Future<void> _addTrip(CalendarDay day) async {
    _snack?.close();
    final trip = await Navigator.of(context).push<Trip>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddTripScreen(day: day),
      ),
    );
    if (trip == null || !mounted) return;
    // §5.5: show the day the trip starts on, with the new row highlighted.
    final tripDay = ref.read(driverZoneProvider).dayOf(trip.start);
    ref.read(selectedDayProvider.notifier).select(tripDay);
    // Wait for the reloaded day: the row must be visible for the 2 s
    // highlight, and the FAB (absent while the day was empty) must be laid
    // out before the snackbar is placed beside or above it.
    try {
      await ref.read(daySummaryProvider(tripDay).future);
    } on Object {
      // The error state shows instead (no FAB to avoid).
    }
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    ref.read(highlightedTripProvider.notifier).flash(trip.id);
    _snack = showDkSnackbar(
      context,
      message: context.l10n.saved,
      tone: DkSnackTone.success,
      fabSize: _fabKey.currentContext?.size,
    );
    unawaited(_revealNewTrip());
  }
}
