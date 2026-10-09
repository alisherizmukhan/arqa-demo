import 'package:design_kit/design_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('time and range', () {
    expect(DkFormat.clock(8, 5), '08:05');
    expect(DkFormat.timeRange('08:10', '08:32'), '08:10 – 08:32');
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
