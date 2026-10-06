import 'package:driver_diary/core/time/calendar_day.dart';
import 'package:driver_diary/core/time/driver_zone.dart';

// Russian date/time labels. Hand-rolled instead of `intl` so formatting needs
// no async locale initialisation and is trivially unit-testable.
// Money is formatted by the design kit (`DkMoney.format` -> `3 315 ₸`).

const _monthsGenitive = [
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

const _weekdaysShort = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

/// `Сегодня, 6 октября` / `Вчера, 5 октября` / `Пн, 28 сентября`
/// (the year is added when it differs from [today]'s).
String formatDayLabel(CalendarDay day, {required CalendarDay today}) {
  final date = formatDayMonth(day, withYear: day.year != today.year);
  if (day == today) return 'Сегодня, $date';
  if (day == today.addDays(-1)) return 'Вчера, $date';
  return '${_weekdaysShort[day.weekday - 1]}, $date';
}

/// `6 октября` or `6 октября 2026`.
String formatDayMonth(CalendarDay day, {bool withYear = false}) {
  final base = '${day.day} ${_monthsGenitive[day.month - 1]}';
  return withYear ? '$base ${day.year}' : base;
}

/// `08:05`.
String formatClock(int hour, int minute) => '${_two(hour)}:${_two(minute)}';

/// `08:10` for [instant] in the driver's [zone].
String formatTime(DateTime instant, DriverZone zone) {
  final local = zone.wallClock(instant);
  return formatClock(local.hour, local.minute);
}

/// `08:10 – 08:32`.
String formatTimeRange(DateTime start, DateTime end, DriverZone zone) =>
    '${formatTime(start, zone)} – ${formatTime(end, zone)}';

String _two(int value) => value.toString().padLeft(2, '0');
