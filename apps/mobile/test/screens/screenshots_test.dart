@Tags(['screenshots'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/account_scenarios.dart';
import '../helpers/app_harness.dart';
import '../helpers/scenarios.dart';

/// Renders every mockup state at 390×844 @2x (780×1688, like the PNGs in
/// docs/design) with the real fonts into `$SCREENSHOTS_DIR`, and the §8
/// screens (login, menu, withdraw, admin) in Russian and Kazakh into
/// `$SCREENSHOTS_DIR/accounts`. Skipped unless that variable is set:
///
///     SCREENSHOTS_DIR=build/screens flutter test test/screens/screenshots_test.dart
void main() {
  final dir = Platform.environment['SCREENSHOTS_DIR'];

  setUpAll(loadAppFonts);

  for (final scenario in [...scenarios, ...behaviourScenarios]) {
    for (final brightness in [
      Brightness.light,
      if (darkScenarioIds.contains(scenario.id)) Brightness.dark,
    ]) {
      final name = switch ((scenario.id, brightness)) {
        ('01_day_light', Brightness.dark) => '02_day_dark',
        (final id, Brightness.dark) => '${id}_dark',
        (final id, _) => id,
      };
      testWidgets(name, skip: dir == null, (tester) async {
        useDevice(tester, (
          size: const Size(390, 844),
          textScale: 1,
          brightness: brightness,
          pixelRatio: 2,
        ));
        // flutter_test draws shadows as solid shapes; render them as on a
        // device (restored before the test ends, as the binding checks).
        debugDisableShadows = false;
        await scenario.run(tester);
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(shotKey),
        );
        final png = await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          return data!.buffer.asUint8List();
        });
        debugDisableShadows = true;
        File('$dir/$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png!);
        await disposeApp(tester);
      });
    }
  }

  // §8 screens, ru and kk; dark for one state per screen.
  const darkAccounts = {
    'a01_login',
    'a06_day_header',
    'a07_menu_driver',
    'a10_withdraw',
    'a16_admin_trips_all',
    'a18_admin_withdrawals',
  };
  for (final locale in ['ru', 'kk']) {
    for (final scenario in accountScenarios) {
      for (final brightness in [
        Brightness.light,
        if (darkAccounts.contains(scenario.id)) Brightness.dark,
      ]) {
        final name =
            '${scenario.id}_$locale'
            '${brightness == Brightness.dark ? '_dark' : ''}';
        testWidgets('accounts/$name', skip: dir == null, (tester) async {
          scenarioLocale = locale;
          addTearDown(() => scenarioLocale = 'ru');
          useDevice(tester, (
            size: const Size(390, 844),
            textScale: 1,
            brightness: brightness,
            pixelRatio: 2,
          ));
          debugDisableShadows = false;
          await scenario.run(tester);
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(shotKey),
          );
          final png = await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            image.dispose();
            return data!.buffer.asUint8List();
          });
          debugDisableShadows = true;
          File('$dir/accounts/$name.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png!);
          await disposeApp(tester);
        });
      }
    }
  }
}
