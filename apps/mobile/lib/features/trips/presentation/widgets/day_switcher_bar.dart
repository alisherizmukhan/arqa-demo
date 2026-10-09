import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/l10n/l10n.dart';
import 'package:driver_diary/core/time/calendar_day.dart';
import 'package:driver_diary/features/trips/presentation/providers/trips_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The day switcher for [selectedDayProvider] (Day screen and the admin's
/// trips tab): ‹ day › in the active language, the date picker in the
/// middle, next disabled on today.
class DaySwitcherBar extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final day = ref.watch(selectedDayProvider);
    final today = ref.watch(todayProvider);
    final selection = ref.read(selectedDayProvider.notifier);
    final label = l10n.relativeDay(day, today);
    return DkDaySwitcher(
      title: label.title,
      subtitle: label.subtitle,
      prevLabel: l10n.prevDay,
      nextLabel: l10n.nextDay,
      pickLabel: l10n.pickDate(l10n.date(day.toDateTime())),
      onPrev: selection.previous,
      onNext: day.isBefore(today) ? selection.next : null,
      onPickDate: () => pickDay(context, ref),
    );
  }

  /// The date wheel (DkPickerSheet) for the selected day, up to today.
  static Future<void> pickDay(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final day = ref.read(selectedDayProvider);
    final today = ref.read(todayProvider);
    final picked = await showDkDatePicker(
      context,
      initialDate: day.toDateTime(),
      firstDate: DateTime(2000),
      lastDate: today.toDateTime(),
      title: l10n.pickDateHelp,
      doneLabel: l10n.pickerDone,
      todayLabel: l10n.today,
    );
    if (picked == null) return;
    ref
        .read(selectedDayProvider.notifier)
        .select(CalendarDay(picked.year, picked.month, picked.day));
  }
}
