import 'package:design_kit/design_kit.dart';
import 'package:flutter/material.dart';

/// Russian texts for the showcase. The kit has no texts of its own (the app
/// formats them with its localizations); the showcase is Russian only.
abstract final class Ru {
  static const _months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  static const _weekdays = [
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота',
    'Воскресенье',
  ];

  /// `1 октября 2026`.
  static String date(DateTime day) =>
      '${day.day} ${_months[day.month - 1]} ${day.year}';

  /// `1 октября`.
  static String dayMonth(DateTime day) =>
      '${day.day} ${_months[day.month - 1]}';

  /// `Четверг`.
  static String weekday(DateTime day) =>
      _weekdays[DateTime.utc(day.year, day.month, day.day).weekday - 1];

  /// `22 мин`, `1 ч 5 мин`, `2 ч`.
  static String duration(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 60) return '$minutes мин';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours ч' : '$hours ч $rest мин';
  }

  /// `2 поездки`.
  static String trips(int n) {
    final mod100 = n % 100;
    final mod10 = n % 10;
    final word = mod100 >= 11 && mod100 <= 14
        ? 'поездок'
        : mod10 == 1
        ? 'поездка'
        : mod10 >= 2 && mod10 <= 4
        ? 'поездки'
        : 'поездок';
    return '$n $word';
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Day switcher texts: Сегодня / Вчера / date (DESIGN.md §3).
  static ({String title, String subtitle}) relativeDay(
    DateTime day,
    DateTime today,
  ) {
    if (_sameDay(day, today)) return (title: 'Сегодня', subtitle: date(day));
    if (_sameDay(day, today.subtract(const Duration(days: 1)))) {
      return (title: 'Вчера', subtitle: date(day));
    }
    return (title: date(day), subtitle: weekday(day));
  }
}

/// Russian payment labels.
extension RuPaymentLabel on DkPaymentMethod {
  /// «Наличные» / «Карта».
  String get label => switch (this) {
    DkPaymentMethod.cash => 'Наличные',
    DkPaymentMethod.card => 'Карта',
  };
}

/// [DkDaySwitcher] with Russian texts; next is disabled on [today].
class RuDaySwitcher extends StatelessWidget {
  /// Creates the switcher.
  const new({
    required this.date,
    required this.today,
    required this.onPrev,
    required this.onPickDate,
    this.onNext,
    super.key,
  });

  /// The shown day.
  final DateTime date;

  /// Today.
  final DateTime today;

  /// One day back.
  final VoidCallback onPrev;

  /// One day forward.
  final VoidCallback? onNext;

  /// Opens the date picker.
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final label = Ru.relativeDay(date, today);
    return DkDaySwitcher(
      title: label.title,
      subtitle: label.subtitle,
      prevLabel: 'Предыдущий день',
      nextLabel: 'Следующий день',
      pickLabel: 'Выбрать дату, ${Ru.date(date)}',
      onPrev: onPrev,
      onNext: date.isBefore(today) && !Ru._sameDay(date, today) ? onNext : null,
      onPickDate: onPickDate,
    );
  }
}
