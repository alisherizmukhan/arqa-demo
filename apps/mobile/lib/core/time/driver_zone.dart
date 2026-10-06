import 'package:driver_diary/core/time/calendar_day.dart';
import 'package:meta/meta.dart';

/// The driver's fixed UTC offset (Kazakhstan: +05:00, no DST).
///
/// Dart's `DateTime` is either UTC or device-local, so instants are kept in
/// UTC and converted with this offset explicitly. That keeps day boundaries
/// right even if the phone's own time zone differs from the driver's.
@immutable
final class DriverZone {
  const new(this.offset);

  /// Parses `+05:00`, `-03:30` or `Z`.
  factory parse(String value) {
    if (value == 'Z') return const DriverZone(Duration.zero);
    final match = RegExp(r'^([+-])(\d{2}):(\d{2})$').firstMatch(value);
    if (match == null) throw FormatException('not a UTC offset', value);
    final offset = Duration(
      hours: int.parse(match[2]!),
      minutes: int.parse(match[3]!),
    );
    return DriverZone(match[1] == '-' ? -offset : offset);
  }

  static const kazakhstan = DriverZone(Duration(hours: 5));

  final Duration offset;

  /// `+05:00`: the `tz` query parameter of the API.
  String get isoOffset {
    final minutes = offset.inMinutes.abs();
    final sign = offset.isNegative ? '-' : '+';
    return '$sign${_two(minutes ~/ 60)}:${_two(minutes % 60)}';
  }

  /// Local wall-clock fields of [instant] (read `.hour`, `.minute`, ...).
  DateTime wallClock(DateTime instant) => instant.toUtc().add(offset);

  /// The local calendar day of [instant]. A trip belongs to the day it starts.
  CalendarDay dayOf(DateTime instant) {
    final local = wallClock(instant);
    return CalendarDay(local.year, local.month, local.day);
  }

  /// The instant at local [hour]:[minute] on [day].
  DateTime instantAt(CalendarDay day, int hour, int minute) =>
      DateTime.utc(day.year, day.month, day.day, hour, minute).subtract(offset);

  /// ISO 8601 with this offset: `2026-10-01T08:10:00+05:00`.
  String formatIso(DateTime instant) {
    final l = wallClock(instant);
    final date = CalendarDay(l.year, l.month, l.day).toIso();
    return '${date}T${_two(l.hour)}:${_two(l.minute)}:${_two(l.second)}'
        '$isoOffset';
  }

  @override
  bool operator ==(Object other) =>
      other is DriverZone && other.offset == offset;

  @override
  int get hashCode => offset.hashCode;

  @override
  String toString() => isoOffset;
}

String _two(int value) => value.toString().padLeft(2, '0');
