import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/scenarios.dart';

/// Every mockup state at the mockup size (390×844) and a small phone
/// (360×780), text scale 1.0 and 1.3, with the real fonts: any overflow or
/// other layout exception fails the test, and so does any truncated text or
/// text reaching past the screen edge.
void main() {
  setUpAll(loadAppFonts);

  const sizes = [Size(390, 844), Size(360, 780)];
  const scales = [1.0, 1.3];

  for (final scenario in [
    ...scenarios,
    ...stressScenarios,
    ...behaviourScenarios,
  ]) {
    for (final size in sizes) {
      for (final scale in scales) {
        final name =
            '${scenario.id} at ${size.width.toInt()}×${size.height.toInt()}, '
            'text ×$scale';
        testWidgets('$name lays out without overflow', (tester) async {
          useDevice(tester, (
            size: size,
            textScale: scale,
            brightness: Brightness.light,
            pixelRatio: 1,
          ));
          await scenario.run(tester);
          expect(tester.takeException(), isNull);
          // No clipped text: nothing truncated, nothing past the screen edge.
          var checked = 0;
          for (final text
              in tester.allRenderObjects.whereType<RenderParagraph>()) {
            if (!text.attached || !text.hasSize) continue;
            checked++;
            expect(
              text.didExceedMaxLines,
              isFalse,
              reason: text.text.toPlainText(),
            );
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
