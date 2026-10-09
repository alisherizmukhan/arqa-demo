import 'package:driver_diary/core/config/app_config.dart';
import 'package:driver_diary/core/time/calendar_day.dart';
import 'package:driver_diary/core/time/driver_zone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarDay', () {
    test('normalizes overflowing parts', () {
      expect(CalendarDay(2026, 10, 32), CalendarDay(2026, 11, 1));
      expect(CalendarDay(2026, 1, 0), CalendarDay(2025, 12, 31));
    });

    test('adds days across months and years', () {
      expect(CalendarDay(2026, 12, 31).addDays(1), CalendarDay(2027, 1, 1));
      expect(CalendarDay(2026, 3, 1).addDays(-1), CalendarDay(2026, 2, 28));
    });

    test('ISO round trip and ordering', () {
      final day = CalendarDay.parse('2026-10-01');
      expect(day.toIso(), '2026-10-01');
      expect(day.isBefore(CalendarDay(2026, 10, 2)), isTrue);
      expect(day.isAfter(CalendarDay(2025, 12, 31)), isTrue);
      expect(day.weekday, DateTime.thursday);
    });

    test('rejects malformed dates', () {
      expect(() => CalendarDay.parse('01.10.2026'), throwsFormatException);
    });
  });

  group('DriverZone', () {
    const kz = DriverZone.kazakhstan;

    test('parses and prints offsets', () {
      expect(DriverZone.parse('+05:00'), kz);
      expect(DriverZone.parse('-03:30').isoOffset, '-03:30');
      expect(DriverZone.parse('Z').isoOffset, '+00:00');
      expect(() => DriverZone.parse('Asia/Almaty'), throwsFormatException);
    });

    test('day boundaries follow the driver offset, not the phone', () {
      // 18:59:59Z = 23:59:59 in +05:00 (same day); 19:00Z = next day 00:00.
      expect(
        kz.dayOf(DateTime.utc(2026, 10, 1, 18, 59, 59)),
        CalendarDay(2026, 10, 1),
      );
      expect(kz.dayOf(DateTime.utc(2026, 10, 1, 19)), CalendarDay(2026, 10, 2));
      expect(kz.dayOf(DateTime.utc(2026, 9, 30, 19)), CalendarDay(2026, 10, 1));
    });

    test('instantAt is the inverse of the wall clock', () {
      final instant = kz.instantAt(CalendarDay(2026, 10, 1), 8, 10);
      expect(instant, DateTime.utc(2026, 10, 1, 3, 10));
      expect(kz.wallClock(instant).hour, 8);
    });

    test('formats ISO 8601 with the offset, as the API expects', () {
      expect(
        kz.formatIso(DateTime.utc(2026, 10, 1, 3, 10)),
        '2026-10-01T08:10:00+05:00',
      );
      expect(
        kz.formatIso(DateTime.utc(2026, 9, 30, 19)),
        '2026-10-01T00:00:00+05:00',
      );
    });
  });

  group('AppConfig.zoneFrom', () {
    test('no DRIVER_TZ: the named Kazakhstan default (+05:00)', () {
      expect(AppConfig.zoneFrom(''), DriverZone.kazakhstan);
      expect(AppConfig.zoneFrom('').isoOffset, '+05:00');
    });

    test('DRIVER_TZ given: parsed', () {
      expect(AppConfig.zoneFrom('+03:00'), DriverZone.parse('+03:00'));
    });
  });
}
