import 'package:design_kit/design_kit.dart';
import 'package:flutter_test/flutter_test.dart';

const _nbsp = ' ';

void main() {
  group('DkMoney.format', () {
    final cases = <int, String>{
      0: '0$_nbsp₸',
      7: '7$_nbsp₸',
      999: '999$_nbsp₸',
      1000: '1${_nbsp}000$_nbsp₸',
      3315: '3${_nbsp}315$_nbsp₸',
      3900: '3${_nbsp}900$_nbsp₸',
      100000: '100${_nbsp}000$_nbsp₸',
      1250000: '1${_nbsp}250${_nbsp}000$_nbsp₸',
      -585: '−585$_nbsp₸',
      -1500: '−1${_nbsp}500$_nbsp₸',
    };
    for (final MapEntry(key: amount, value: expected) in cases.entries) {
      test('$amount', () => expect(DkMoney.format(amount), expected));
    }
  });

  test('reads as "3 315 ₸" with ordinary spaces', () {
    expect(DkMoney.format(3315).replaceAll(_nbsp, ' '), '3 315 ₸');
  });

  test('formatNumber omits the currency', () {
    expect(DkMoney.formatNumber(3315), '3${_nbsp}315');
  });
}
