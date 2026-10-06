import 'package:driver_diary/core/format/date_format.dart';
import 'package:driver_diary/core/time/calendar_day.dart';
import 'package:driver_diary/core/time/driver_zone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = CalendarDay(2026, 10, 6);

  test('day labels in Russian', () {
    expect(formatDayLabel(today, today: today), 'Сегодня, 6 октября');
    expect(formatDayLabel(today.addDays(-1), today: today), 'Вчера, 5 октября');
    expect(
      formatDayLabel(CalendarDay(2026, 9, 28), today: today),
      'Пн, 28 сентября',
    );
    expect(
      formatDayLabel(CalendarDay(2025, 12, 31), today: today),
      'Ср, 31 декабря 2025',
    );
  });

  test('time range in the driver zone', () {
    expect(
      formatTimeRange(
        DateTime.utc(2026, 10, 1, 3, 10),
        DateTime.utc(2026, 10, 1, 3, 32),
        DriverZone.kazakhstan,
      ),
      '08:10 – 08:32',
    );
  });

  test('clock is zero padded', () => expect(formatClock(7, 5), '07:05'));
}
