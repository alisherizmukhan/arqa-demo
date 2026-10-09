import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/l10n/l10n.dart';
import 'package:driver_diary/core/time/calendar_day.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(initializeDateFormatting);
  final ru = lookupAppLocalizations(const Locale('ru'));
  final kk = lookupAppLocalizations(const Locale('kk'));
  final oct1 = DateTime(2026, 10);
  final today = CalendarDay(2026, 10, 6);

  test('dates in Russian: genitive month, capitalised weekday', () {
    expect(ru.date(oct1), '1 октября 2026');
    expect(ru.dayMonth(DateTime(2026, 9, 30)), '30 сентября');
    expect(ru.weekday(oct1), 'Четверг');
    expect(ru.shortDateTime(DateTime(2026, 10, 9, 22, 34)), '9 окт., 22:34');
    expect(
      ru.fullDateTime(DateTime(2026, 10, 5, 14, 20)),
      '5 октября 2026, 14:20',
    );
  });

  test('dates in Kazakh (a no-break space before «ж.»)', () {
    expect(kk.date(oct1), '2026\u00A0ж. 1 қазан');
    expect(kk.dayMonth(oct1), '1 қазан');
    expect(kk.weekday(oct1), 'Бейсенбі');
    expect(kk.shortDateTime(DateTime(2026, 10, 9, 22, 34)), '9 қаз., 22:34');
  });

  test('relative day labels (§3) in both languages', () {
    expect(ru.relativeDay(today, today), (
      title: 'Сегодня',
      subtitle: '6 октября 2026',
    ));
    expect(ru.relativeDay(today.addDays(-1), today), (
      title: 'Вчера',
      subtitle: '5 октября 2026',
    ));
    expect(ru.relativeDay(CalendarDay(2026, 10, 1), today), (
      title: '1 октября 2026',
      subtitle: 'Четверг',
    ));
    expect(kk.relativeDay(today, today).title, 'Бүгін');
    expect(kk.relativeDay(today.addDays(-1), today).title, 'Кеше');
  });

  test('durations', () {
    expect(ru.duration(const Duration(minutes: 22)), '22 мин');
    expect(ru.duration(const Duration(minutes: 65)), '1 ч 5 мин');
    expect(ru.duration(const Duration(hours: 2)), '2 ч');
    expect(kk.duration(const Duration(minutes: 65)), '1 сағ 5 мин');
  });

  test('trip plurals: ru one/few/many incl. 11–14, kk one/other', () {
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
      expect(ru.tripsCount(n), text);
    }
    expect(kk.tripsCount(1), '1 сапар');
    expect(kk.tripsCount(5), '5 сапар');
  });

  test('money is the same in both languages', () {
    for (final l10n in [ru, kk]) {
      expect(
        l10n.available(DkMoney.format(1815)),
        contains('1\u202F815\u202F₸'),
      );
    }
    expect(ru.moneySpoken('3\u202F315'), '3\u202F315 тенге');
    expect(kk.moneySpoken('3\u202F315'), '3\u202F315 теңге');
  });
}
