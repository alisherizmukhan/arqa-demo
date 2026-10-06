import 'package:design_kit/design_kit.dart';
import 'package:flutter_test/flutter_test.dart';

/// A day in October / September 2026.
DateTime oct(int day) => DateTime(2026, 10, day);
DateTime sep(int day) => DateTime(2026, 9, day);

void main() {
  final today = oct(6);

  test('dates in Russian, genitive month, capitalised weekday', () {
    expect(DkFormat.date(oct(1)), '1 октября 2026');
    expect(DkFormat.dayMonth(sep(30)), '30 сентября');
    expect(DkFormat.weekday(oct(1)), 'Четверг');
  });

  test('relative day labels (§3)', () {
    expect(DkFormat.relativeDay(today, today), (
      title: 'Сегодня',
      subtitle: '6 октября 2026',
    ));
    expect(DkFormat.relativeDay(oct(5), today), (
      title: 'Вчера',
      subtitle: '5 октября 2026',
    ));
    expect(DkFormat.relativeDay(oct(1), today), (
      title: '1 октября 2026',
      subtitle: 'Четверг',
    ));
  });

  test('time and range', () {
    expect(DkFormat.clock(8, 5), '08:05');
    expect(DkFormat.timeRange('08:10', '08:32'), '08:10 – 08:32');
  });

  test('duration', () {
    expect(DkFormat.duration(const Duration(minutes: 22)), '22 мин');
    expect(DkFormat.duration(const Duration(minutes: 65)), '1 ч 5 мин');
    expect(DkFormat.duration(const Duration(hours: 2)), '2 ч');
  });

  test('trip plural incl. 11–14', () {
    final cases = {
      1: '1 поездка',
      2: '2 поездки',
      4: '4 поездки',
      5: '5 поездок',
      11: '11 поездок',
      14: '14 поездок',
      21: '21 поездка',
      22: '22 поездки',
      111: '111 поездок',
    };
    for (final MapEntry(key: n, value: text) in cases.entries) {
      expect(DkFormat.trips(n), text);
    }
  });

  test('split percentages sum to 100 (largest remainder)', () {
    expect(DkFormat.splitPercent(1500, 2400), (cash: 38, card: 62));
    expect(DkFormat.splitPercent(3000, 2000), (cash: 60, card: 40));
    expect(DkFormat.splitPercent(1, 2), (cash: 33, card: 67));
    expect(DkFormat.splitPercent(0, 500), (cash: 0, card: 100));
    expect(DkFormat.splitPercent(0, 0), isNull);
    for (var cash = 0; cash <= 300; cash += 7) {
      final p = DkFormat.splitPercent(cash, 301 - cash)!;
      expect(p.cash + p.card, 100);
    }
  });
}
