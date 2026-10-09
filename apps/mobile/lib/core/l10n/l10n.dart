import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/time/calendar_day.dart';
import 'package:driver_diary/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

export 'package:driver_diary/l10n/gen/app_localizations.dart';

/// The app's languages; the first is the fallback.
const appLocales = [Locale('ru'), Locale('kk')];

extension L10nContext on BuildContext {
  /// Texts in the active language.
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Dates, durations and amounts in the active language (DESIGN.md §3).
/// Money is formatted the same way in every language (U+202F, `₸`).
extension AppFormat on AppLocalizations {
  /// ru `1 октября 2026`, kk `2026 ж. 1 қазан`. CLDR puts a narrow U+202F
  /// before «ж.»; a plain `Text` draws it too tight, so it becomes a normal
  /// no-break space.
  String date(DateTime day) => switch (localeName) {
    'ru' => DateFormat('d MMMM y', 'ru').format(day),
    _ => DateFormat.yMMMMd(
      localeName,
    ).format(day).replaceAll('\u202F', '\u00A0'),
  };

  /// ru `1 октября`, kk `1 қазан`.
  String dayMonth(DateTime day) => switch (localeName) {
    'ru' => DateFormat('d MMMM', 'ru').format(day),
    _ => DateFormat.MMMMd(localeName).format(day),
  };

  /// `Четверг`, `Бейсенбі` (capitalised).
  String weekday(DateTime day) =>
      _capitalised(DateFormat.EEEE(localeName).format(day));

  /// `9 окт., 22:34` (admin rows: short month, no year).
  String shortDateTime(DateTime local) => dateTime(
    DateFormat('d MMM', localeName).format(local),
    DkFormat.clock(local.hour, local.minute),
  );

  /// `5 октября 2026, 14:20`.
  String fullDateTime(DateTime local) =>
      dateTime(date(local), DkFormat.clock(local.hour, local.minute));

  /// Day switcher texts (§3): today → (Сегодня, date); yesterday →
  /// (Вчера, date); otherwise (date, weekday).
  ({String title, String subtitle}) relativeDay(
    CalendarDay day,
    CalendarDay today,
  ) {
    final shown = day.toDateTime();
    if (day == today) return (title: this.today, subtitle: date(shown));
    if (day == today.addDays(-1)) {
      return (title: yesterday, subtitle: date(shown));
    }
    return (title: date(shown), subtitle: weekday(shown));
  }

  /// `22 мин`, `1 ч 5 мин`, `2 ч`.
  String duration(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 60) return durationMinutes(minutes);
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? durationHours(hours) : durationHoursMinutes(hours, rest);
  }

  /// `2 поездки · 37 мин`.
  String tripsHeader(int count, Duration total) =>
      '${tripsCount(count)} · ${duration(total)}';

  /// `22 мин · Карта`.
  String tripMeta(Duration length, String payment) =>
      '${duration(length)} · $payment';

  /// The kit's payment labels.
  String paymentLabel(DkPaymentMethod method) => switch (method) {
    DkPaymentMethod.cash => cash,
    DkPaymentMethod.card => card,
  };

  static String _capitalised(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}
