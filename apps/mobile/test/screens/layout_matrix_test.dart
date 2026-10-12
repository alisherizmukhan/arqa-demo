import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/account_scenarios.dart';
import '../helpers/app_harness.dart';
import '../helpers/scenarios.dart';

/// Every mockup state at the mockup size (390×844) and a small phone
/// (360×780), text scale 1.0 and 1.3, in Russian and Kazakh, with the real
/// fonts: any overflow or other layout exception fails the test, and so does
/// any truncated text or text reaching past the screen edge.
void main() {
  setUpAll(loadAppFonts);

  const sizes = [Size(390, 844), Size(360, 780)];
  const scales = [1.0, 1.3];

  final stressIds = {for (final s in stressScenarios) s.id};

  for (final locale in ['ru', 'kk']) {
    for (final scenario in [
      ...scenarios,
      ...stressScenarios,
      ...behaviourScenarios,
      ...accountScenarios,
    ]) {
      for (final size in sizes) {
        for (final scale in scales) {
          final name =
              '${scenario.id} [$locale] at '
              '${size.width.toInt()}×${size.height.toInt()}, text ×$scale';
          testWidgets('$name lays out without overflow', (tester) async {
            scenarioLocale = locale;
            addTearDown(() => scenarioLocale = 'ru');
            useDevice(tester, (
              size: size,
              textScale: scale,
              brightness: Brightness.light,
              pixelRatio: 1,
            ));
            await scenario.run(tester);
            expect(tester.takeException(), isNull);
            // No text past the screen edge; cut text only where §10 allows.
            var checked = 0;
            for (final text
                in tester.allRenderObjects.whereType<RenderParagraph>()) {
              if (!text.attached || !text.hasSize) continue;
              checked++;
              // DESIGN.md §10: at text ×1.0 nothing is cut (except next to
              // the stress amounts, where the text gives way by rule 7);
              // above it labels may end in «…»; an amount is never cut.
              final plain = text.text.toPlainText();
              if (plain.contains('₸') ||
                  (scale == 1.0 && !stressIds.contains(scenario.id))) {
                expect(text.didExceedMaxLines, isFalse, reason: plain);
              }
              // A horizontal scroll row (filter chips, §8.0) runs past the
              // edge by design; its texts are still checked for truncation.
              if (_inHorizontalScroll(tester, text)) continue;
              final box = MatrixUtils.transformRect(
                text.getTransformTo(null),
                Offset.zero & text.size,
              );
              expect(
                box.left,
                greaterThanOrEqualTo(-0.5),
                reason: text.text.toPlainText(),
              );
              expect(
                box.right,
                lessThanOrEqualTo(size.width + 0.5),
                reason: text.text.toPlainText(),
              );
            }
            expect(checked, greaterThan(5), reason: 'texts were inspected');
            await disposeApp(tester);
          });
        }
      }
    }
  }
}

bool _inHorizontalScroll(WidgetTester tester, RenderObject object) {
  final rows = {
    for (final element
        in find
            .byWidgetPredicate(
              (w) =>
                  w is Scrollable &&
                  axisDirectionToAxis(w.axisDirection) == Axis.horizontal,
            )
            .evaluate())
      element.renderObject,
  };
  for (var node = object.parent; node != null; node = node.parent) {
    if (rows.contains(node)) return true;
  }
  return false;
}
