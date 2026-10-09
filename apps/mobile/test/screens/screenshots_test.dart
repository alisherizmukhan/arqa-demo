@Tags(['screenshots'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
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
        _save('$dir/$name.png', png!);
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
          _save('$dir/accounts/$name.png', png!);
          await disposeApp(tester);
        });
      }
    }
  }
}

/// States that look the same on purpose.
bool _sameByDesign(String a, String b) {
  const pairs = {
    // An automatic resend changes nothing on screen: the form stays
    // editable and Save keeps its label (DESIGN.md §5.9, mockup 10).
    {'r5_offline_resending', '10_add_trip_offline'},
  };
  String id(String path) => path.split('/').last.replaceAll('.png', '');
  return pairs.any((p) => p.containsAll({id(a), id(b)}));
}

/// Every image written in this run, by path.
final _written = <String, Uint8List>{};

/// Writes [png] to [path] and fails when another state rendered the very
/// same image: two different states that look identical mean a scenario
/// did not reach its state (a missed tap, a disabled button).
void _save(String path, Uint8List png) {
  for (final MapEntry(key: other, value: bytes) in _written.entries) {
    if (listEquals(bytes, png) && !_sameByDesign(path, other)) {
      fail(
        '$path is identical to $other: the scenario did not reach its state',
      );
    }
  }
  _written[path] = png;
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(png);
}
