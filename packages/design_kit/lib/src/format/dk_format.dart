/// Dates, times, durations, plurals and split percentages, DESIGN.md §3.
/// The one place for formatting: the app uses these, it has no own copies.
abstract final class DkFormat {
  static const _monthsGenitive = [
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

  /// `1 октября 2026` (genitive month). Uses the date's y/m/d only.
  static String date(DateTime day) =>
      '${day.day} ${_monthsGenitive[day.month - 1]} ${day.year}';

  /// `1 октября` (no year).
  static String dayMonth(DateTime day) =>
      '${day.day} ${_monthsGenitive[day.month - 1]}';

  /// `Четверг` (capitalised).
  static String weekday(DateTime day) =>
      _weekdays[DateTime.utc(day.year, day.month, day.day).weekday - 1];

  /// Day switcher title/subtitle (§3 "Relative label"):
  /// today → (`Сегодня`, date); yesterday → (`Вчера`, date);
  /// otherwise (date, weekday).
  static ({String title, String subtitle}) relativeDay(
    DateTime day,
    DateTime today,
  ) {
    final d = DateTime.utc(day.year, day.month, day.day);
    final t = DateTime.utc(today.year, today.month, today.day);
    final diff = t.difference(d).inDays;
    return switch (diff) {
      0 => (title: 'Сегодня', subtitle: date(day)),
      1 => (title: 'Вчера', subtitle: date(day)),
      _ => (title: date(day), subtitle: weekday(day)),
    };
  }

  /// `08:05` (24 h).
  static String clock(int hour, int minute) => '${_two(hour)}:${_two(minute)}';

  /// `08:10 – 08:32` (en dash with spaces).
  static String timeRange(String start, String end) => '$start – $end';

  /// `22 мин`, `1 ч 5 мин`, `2 ч`.
  static String duration(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 60) return '$minutes мин';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours ч' : '$hours ч $rest мин';
  }

  /// Russian plural: 1 поездка, 2–4 поездки, 5+ / 11–14 поездок.
  static String plural(int n, String one, String few, String many) {
    final mod100 = n.abs() % 100;
    final mod10 = n.abs() % 10;
    if (mod100 >= 11 && mod100 <= 14) return many;
    if (mod10 == 1) return one;
    if (mod10 >= 2 && mod10 <= 4) return few;
    return many;
  }

  /// `2 поездки`.
  static String trips(int n) =>
      '$n ${plural(n, 'поездка', 'поездки', 'поездок')}';

  /// Cash/card shares in whole percent that sum to 100 (largest remainder).
  /// Null when there is no revenue (the split is hidden then).
  static ({int cash, int card})? splitPercent(int cash, int card) {
    final total = cash + card;
    if (total <= 0) return null;
    final cashExact = cash * 100 / total;
    var cashPct = cashExact.floor();
    var cardPct = (card * 100 / total).floor();
    final missing = 100 - cashPct - cardPct;
    if (missing > 0) {
      final cashRemainder = cashExact - cashExact.floor();
      final cardRemainder = card * 100 / total - cardPct;
      if (cashRemainder >= cardRemainder) {
        cashPct += missing;
      } else {
        cardPct += missing;
      }
    }
    return (cash: cashPct, card: cardPct);
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
