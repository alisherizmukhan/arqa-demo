import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/l10n/strings_ru.dart';
import 'package:driver_diary/core/time/calendar_day.dart';
import 'package:driver_diary/features/trips/domain/entities/daily_summary.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/presentation/providers/trips_providers.dart';
import 'package:driver_diary/features/trips/presentation/screens/add_trip_screen.dart';
import 'package:driver_diary/features/trips/presentation/widgets/day_skeleton.dart';
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
  DkSnackbarHandle? _snack;

  @override
  void dispose() {
    _snack?.close();
    super.dispose();
  }

  _DayView _view(CalendarDay day) {
    final summary = ref.watch(daySummaryProvider);
    final trips = ref.watch(dayTripsProvider);
    // A new day was selected: a skeleton, never the previous day's totals.
    if (summary.isReloading || trips.isReloading) return const _Loading();
    // Pull-to-refresh (and a failed refresh) keep the shown data.
    if ((summary.value, trips.value) case (final s?, final t?)
        when s.day == day) {
      return _Loaded(s, t);
    }
    if (summary.hasError) return _Failed(retrying: summary.isLoading);
    return const _Loading();
  }

  @override
  Widget build(BuildContext context) {
    final day = ref.watch(selectedDayProvider);
    final today = ref.watch(todayProvider);
    final selection = ref.read(selectedDayProvider.notifier);
    final view = _view(day);
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
                    // Kit default = §6 copy («Дневник смен»).
                    const DkWordmark(),
                    SizedBox(height: spacing.s8),
                    DkDaySwitcher(
                      date: _date(day),
                      today: _date(today),
                      onPrev: selection.previous,
                      onNext: selection.next,
                      onPickDate: () => _pickDay(day, today),
                    ),
                  ],
                ),
              ),
              switch (view) {
                _Loaded(:final summary) when summary.tripsCount == 0 => _fill(
                  DkEmptyState(
                    title: S.emptyTitle,
                    message: S.emptyMessage,
                    actionLabel: S.emptyAction,
                    onAction: () => _addTrip(day),
                  ),
                ),
                _Failed(:final retrying) => _fill(
                  DkErrorState(
                    title: S.errorTitle,
                    message: S.errorMessage,
                    isRetrying: retrying,
                    onRetry: () => ref.invalidate(dayTripsProvider),
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
                            highlightedId: ref.watch(highlightedTripProvider),
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
              label: S.addTripFab,
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

  static DateTime _date(CalendarDay day) =>
      DateTime(day.year, day.month, day.day);

  Future<void> _refresh() async {
    try {
      ref.invalidate(dayTripsProvider);
      await ref.read(dayTripsProvider.future);
      _snack?.close();
    } on Object {
      // No data yet: the error state explains. With data: keep it (§5.4).
      final shown = ref.read(daySummaryProvider).value?.day;
      if (!mounted || shown != ref.read(selectedDayProvider)) return;
      // Full width, 12 above the FAB: never over it.
      final fab = _fabKey.currentContext?.size?.height ?? 0;
      _snack = showDkSnackbar(
        context,
        message: S.errorTitle,
        tone: DkSnackTone.error,
        bottom:
            MediaQuery.paddingOf(context).bottom +
            context.dkSpacing.s16 +
            fab +
            context.dkSpacing.s12,
        actionLabel: S.retry,
        onAction: () {
          _snack?.close();
          ref.invalidate(dayTripsProvider);
        },
      );
    }
  }

  Future<void> _pickDay(CalendarDay day, CalendarDay today) async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('ru'),
      initialDate: _date(day),
      firstDate: DateTime(2000),
      lastDate: _date(today),
      helpText: S.pickDateHelp,
    );
    if (picked == null) return;
    ref
        .read(selectedDayProvider.notifier)
        .select(CalendarDay(picked.year, picked.month, picked.day));
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
    ref
        .read(selectedDayProvider.notifier)
        .select(ref.read(driverZoneProvider).dayOf(trip.start));
    // Wait for the reloaded day: the row must be visible for the 2 s
    // highlight, and the FAB (absent while the day was empty) must be laid
    // out before the snackbar is placed beside or above it.
    try {
      await ref.read(daySummaryProvider.future);
    } on Object {
      // The error state shows instead (no FAB to avoid).
    }
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    ref.read(highlightedTripProvider.notifier).flash(trip.id);
    _snack = showDkSnackbar(
      context,
      message: S.saved,
      tone: DkSnackTone.success,
      fabSize: _fabKey.currentContext?.size,
    );
  }
}
