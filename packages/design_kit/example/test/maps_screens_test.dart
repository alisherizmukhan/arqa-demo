// Renders every DESIGN.md §9 screen state (example/lib/maps_preview.dart) in
// Russian and Kazakh, light and dark, with the real fonts and locally drawn
// tiles (no network). Always: no exception and no overflow, also at 360 dp
// and text scale 1.3; amounts formatted by the kit. With SCREENSHOTS_DIR set,
// also writes 390×844 @2x PNGs (<id>_<lang>_<brightness>.png):
//
//     SCREENSHOTS_DIR=build/maps flutter test test/maps_screens_test.dart

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_kit/design_kit.dart';
import 'package:design_kit_example/maps_copy.dart';
import 'package:design_kit_example/maps_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'accounts_screens_test.dart' show moneyProblems;

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
  MapsPreview preview,
  MapsCopy copy, {
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
        home: Builder(builder: (_) => preview.build(copy)),
      ),
    ),
  );
  // The map lays out its camera on the first frame; skeletons pulse
  // forever: pump a fixed time, never pumpAndSettle.
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  final dir = Platform.environment['SCREENSHOTS_DIR'];
  final copies = [ruCopy, kkCopy];

  setUpAll(_loadFonts);

  test('every §9 screen has a preview', () {
    final ids = mapsPreviews.map((p) => p.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    for (final prefix in [
      'add_trip',
      'picker',
      'day_trips',
      'details',
      'day_map',
      'kit',
    ]) {
      expect(ids.any((id) => id.contains(prefix)), isTrue, reason: prefix);
    }
  });

  for (final preview in mapsPreviews) {
    for (final copy in copies) {
      for (final brightness in Brightness.values) {
        testWidgets('${preview.id} ${copy.code} ${brightness.name}', (
          tester,
        ) async {
          debugDisableShadows = false;
          await _pump(
            tester,
            preview,
            copy,
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
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              image.dispose();
              return data!.buffer.asUint8List();
            });
            File('$dir/${preview.id}_${copy.code}_${brightness.name}.png')
              ..createSync(recursive: true)
              ..writeAsBytesSync(png!);
          }
          debugDisableShadows = true;
        });
      }

      testWidgets(
        '${preview.id} ${copy.code} at 360 dp, text x1.3: no overflow',
        (tester) async {
          await _pump(
            tester,
            preview,
            copy,
            size: const Size(360, 780),
            ratio: 1,
            brightness: Brightness.light,
            textScale: 1.3,
          );
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('${preview.id} ${copy.code}: money is formatted by the kit', (
        tester,
      ) async {
        await _pump(
          tester,
          preview,
          copy,
          size: const Size(390, 844),
          ratio: 1,
          brightness: Brightness.light,
        );
        expect(moneyProblems(tester), isEmpty);
      });
    }
  }
}
