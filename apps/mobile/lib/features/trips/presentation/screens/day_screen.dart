import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/time/calendar_day.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/presentation/error_messages.dart';
import 'package:driver_diary/features/trips/presentation/providers/trips_providers.dart';
import 'package:driver_diary/features/trips/presentation/screens/add_trip_screen.dart';
import 'package:driver_diary/features/trips/presentation/widgets/day_skeleton.dart';
import 'package:driver_diary/features/trips/presentation/widgets/summary_card.dart';
import 'package:driver_diary/features/trips/presentation/widgets/trip_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One day: switcher, summary, trips, and the "add trip" action.
class DayScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(selectedDayProvider);
    final today = ref.watch(todayProvider);
    final selection = ref.read(selectedDayProvider.notifier);
    final spacing = context.dkSpacing;

    return Scaffold(
      appBar: AppBar(title: const Text('Дневник смены')),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.s8),
              child: DkDaySwitcher(
                date: DateTime(day.year, day.month, day.day),
                today: DateTime(today.year, today.month, today.day),
                onPrev: selection.previous,
                onNext: selection.next,
                onPickDate: () => _pickDay(context, ref, day, today),
              ),
            ),
            const Expanded(child: _DayContent()),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.s16,
            spacing.s8,
            spacing.s16,
            spacing.s16,
          ),
          child: DkButton(
            label: 'Добавить поездку',
            icon: DkIcons.add,
            expand: true,
            onPressed: () => _addTrip(context, ref, day),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDay(
    BuildContext context,
    WidgetRef ref,
    CalendarDay day,
    CalendarDay today,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(day.year, day.month, day.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(today.year, today.month, today.day),
      helpText: 'Выберите день',
    );
    if (picked == null) return;
    ref
        .read(selectedDayProvider.notifier)
        .select(CalendarDay(picked.year, picked.month, picked.day));
  }

  Future<void> _addTrip(
    BuildContext context,
    WidgetRef ref,
    CalendarDay day,
  ) async {
    final trip = await Navigator.of(context).push<Trip>(
      MaterialPageRoute(builder: (_) => AddTripScreen(initialDay: day)),
    );
    if (trip == null || !context.mounted) return;
    // Show the day the trip belongs to (the form may have picked another).
    ref
        .read(selectedDayProvider.notifier)
        .select(ref.read(driverZoneProvider).dayOf(trip.start));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Поездка сохранена · ${DkMoney.format(trip.amount)}'),
      ),
    );
  }
}

class _DayContent extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(dayTripsProvider);
    final summary = ref.watch(daySummaryProvider);
    final zone = ref.watch(driverZoneProvider);
    final spacing = context.dkSpacing;

    // A new day was selected: show a skeleton, not the previous day's data.
    final showSkeleton =
        trips.isReloading || (!trips.hasValue && !trips.hasError);

    final Widget content;
    if (showSkeleton) {
      content = const DaySkeleton();
    } else if (trips.error case final Object error) {
      content = DkErrorState(
        title: 'Не удалось загрузить данные',
        message: error is Failure ? failureMessage(error) : null,
        onRetry: () => ref.invalidate(dayTripsProvider),
      );
    } else {
      final list = trips.requireValue;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing.s24,
        children: [
          if (summary.value case final value?) SummaryCard(summary: value),
          if (list.isEmpty)
            const DkEmptyState(
              title: 'Поездок нет',
              message: 'За этот день ещё нет поездок.',
            )
          else
            TripList(trips: list, zone: zone),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Errors are shown by the error state; the indicator just stops.
        await ref
            .refresh(dayTripsProvider.future)
            .then<void>((_) {}, onError: (_) {});
      },
      child: ListView(
        // Pull-to-refresh must work in the empty and error states too.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(spacing.s16),
        children: [content],
      ),
    );
  }
}
