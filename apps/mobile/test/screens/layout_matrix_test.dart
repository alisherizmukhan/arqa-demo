import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/scenarios.dart';

/// Every mockup state at the mockup size (390×844) and a small phone
/// (360×780), text scale 1.0 and 1.3, with the real fonts: any overflow or
/// other layout exception fails the test.
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
          await disposeApp(tester);
        });
      }
    }
  }
}
