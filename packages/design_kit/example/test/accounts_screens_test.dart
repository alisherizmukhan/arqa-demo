// Renders every DESIGN.md §8 screen state (example/lib/accounts_preview.dart)
// with the real fonts, light and dark. Always: no exception and no overflow,
// also at 360 dp and text scale 1.3. With SCREENSHOTS_DIR set, also writes
// 390×844 @2x PNGs (<id>_light.png, <id>_dark.png):
//
//     SCREENSHOTS_DIR=build/accounts flutter test test/accounts_screens_test.dart

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_kit/design_kit.dart';
import 'package:design_kit_example/accounts_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const ValueKey<String> _shotKey = ValueKey('shot');

Future<void> _loadFonts() async {
  final manifest = jsonDecode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family'] as String);
    for (final font in (entry['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

Future<void> _pump(
  WidgetTester tester,
  AccountsPreview preview, {
  required Size size,
  required double ratio,
  required Brightness brightness,
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = size * ratio
    ..devicePixelRatio = ratio
    ..padding = FakeViewPadding(top: 54 * ratio, bottom: 34 * ratio)
    ..viewPadding = FakeViewPadding(top: 54 * ratio, bottom: 34 * ratio);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _shotKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: brightness == Brightness.light
            ? DkTheme.light()
            : DkTheme.dark(),
        home: Builder(builder: preview.build),
      ),
    ),
  );
  // Skeletons pulse forever: pump a fixed time, never pumpAndSettle.
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  final dir = Platform.environment['SCREENSHOTS_DIR'];

  setUpAll(_loadFonts);

  test('every §8 screen has a preview', () {
    final ids = accountsPreviews.map((p) => p.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    for (final prefix in [
      'login',
      'menu',
      'withdraw',
      'admin',
      'session',
      'day_header',
    ]) {
      expect(ids.any((id) => id.contains(prefix)), isTrue, reason: prefix);
    }
  });

  for (final preview in accountsPreviews) {
    for (final brightness in Brightness.values) {
      testWidgets('${preview.id} ${brightness.name}', (tester) async {
        debugDisableShadows = false;
        await _pump(
          tester,
          preview,
          size: const Size(390, 844),
          ratio: 2,
          brightness: brightness,
        );
        expect(tester.takeException(), isNull);
        if (dir != null) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(_shotKey),
          );
          final png = await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            image.dispose();
            return data!.buffer.asUint8List();
          });
          File('$dir/${preview.id}_${brightness.name}.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png!);
        }
        debugDisableShadows = true;
      });
    }

    testWidgets('${preview.id} at 360 dp, text x1.3: no overflow', (
      tester,
    ) async {
      await _pump(
        tester,
        preview,
        size: const Size(360, 780),
        ratio: 1,
        brightness: Brightness.light,
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
