import 'package:meta/meta.dart';

/// A calendar date in the driver's zone, without time: "2026-10-01".
@immutable
final class CalendarDay implements Comparable<CalendarDay> {
  /// Out-of-range parts are normalized (Oct 32 -> Nov 1), like `DateTime`.
  factory(int year, int month, int day) {
    final normalized = DateTime.utc(year, month, day);
    return CalendarDay._(normalized.year, normalized.month, normalized.day);
  }

  const new _(this.year, this.month, this.day);

  /// Parses `YYYY-MM-DD`.
  factory parse(String iso) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(iso);
    if (match == null) throw FormatException('not a YYYY-MM-DD date', iso);
    return CalendarDay(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
  }

  final int year;
  final int month;
  final int day;

  /// 1 = Monday ... 7 = Sunday.
  int get weekday => DateTime.utc(year, month, day).weekday;

  CalendarDay addDays(int days) => CalendarDay(year, month, day + days);

  bool isBefore(CalendarDay other) => compareTo(other) < 0;

  bool isAfter(CalendarDay other) => compareTo(other) > 0;

  /// `YYYY-MM-DD`, as the API expects.
  String toIso() =>
      '${year.toString().padLeft(4, '0')}-${_two(month)}-${_two(day)}';

  @override
  int compareTo(CalendarDay other) =>
      (year - other.year) * 10000 +
      (month - other.month) * 100 +
      (day - other.day);

  @override
  bool operator ==(Object other) =>
      other is CalendarDay &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}

String _two(int value) => value.toString().padLeft(2, '0');
