import 'package:design_kit/design_kit.dart';
import 'package:flutter_test/flutter_test.dart';

const _nnbsp = ' ';
const _minus = '−';

void main() {
  group('DkMoney.format (U+202F groups, U+2212 minus)', () {
    final cases = <int, String>{
      0: '0$_nnbsp₸',
      585: '585$_nnbsp₸',
      1000: '1${_nnbsp}000$_nnbsp₸',
      3315: '3${_nnbsp}315$_nnbsp₸',
      1250000: '1${_nnbsp}250${_nnbsp}000$_nnbsp₸',
      -585: '${_minus}585$_nnbsp₸',
      -1500: '${_minus}1${_nnbsp}500$_nnbsp₸',
    };
    for (final MapEntry(key: amount, value: expected) in cases.entries) {
      test('$amount', () => expect(DkMoney.format(amount), expected));
    }
  });

  test('never uses U+00A0 or an ASCII space', () {
    final formatted = DkMoney.format(1234567);
    expect(formatted, isNot(contains(' ')));
    expect(formatted, isNot(contains(' ')));
  });

  test('groupDigits / digitsOf / parse', () {
    expect(DkMoney.groupDigits('2400'), '2${_nnbsp}400');
    expect(DkMoney.digitsOf('2${_nnbsp}400 ₸'), '2400');
    expect(DkMoney.parse('12 345 ₸'), 12345);
    expect(DkMoney.parse(''), isNull);
  });
}
