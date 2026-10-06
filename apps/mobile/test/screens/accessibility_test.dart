import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/scenarios.dart';

/// Every mockup state, light and dark: tap targets ≥ 48 dp, every tappable
/// thing labelled, text contrast (Flutter's accessibility guidelines).
void main() {
  for (final scenario in [...scenarios, ...behaviourScenarios]) {
    for (final brightness in Brightness.values) {
      testWidgets('${scenario.id} (${brightness.name}) meets the a11y '
          'guidelines', (tester) async {
        final handle = tester.ensureSemantics();
        useDevice(tester, (
          size: const Size(390, 844),
          textScale: 1,
          brightness: brightness,
          pixelRatio: 1,
        ));
        await scenario.run(tester);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await disposeApp(tester);
        handle.dispose();
      });
    }
  }

  testWidgets('spoken names from DESIGN.md §4', (tester) async {
    final handle = tester.ensureSemantics();
    useDevice(tester, phone390);
    await scenarios.first.run(tester); // the Day screen on 1 October

    expect(find.bySemanticsLabel('Предыдущий день'), findsOneWidget);
    expect(find.bySemanticsLabel('Следующий день'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('^Выбрать дату, 1 октября 2026')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Наличные 38%, карта 62%'), findsOneWidget);
    await disposeApp(tester);
    handle.dispose();
  });
}
