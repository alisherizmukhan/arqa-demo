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

  testWidgets('the money detector flags hand-built and narrow amounts', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: DkTheme.light(),
        home: Column(
          children: [
            const Text('1 000₸'), // no separator before ₸
            const Text('-585 ₸'), // hyphen, and a plain (narrow) Text
            DkGroupedText(
              DkMoney.format(-585),
              style: dkTextStyle(
                size: 14,
                lineHeight: 20,
                weight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );

    final problems = moneyProblems(tester);
    expect(problems, contains('no U+202F before ₸ in "1 000₸"'));
    expect(problems, contains('hyphen instead of U+2212 in "-585 ₸"'));
    expect(problems.where((p) => p.contains('narrow')), hasLength(2));
    expect(problems.where((p) => p.contains('−585')), isEmpty);
  });

  // Every amount on screen goes through the shared money formatting: U+202F
  // before ₸ and between digit groups, U+2212 for minus, and the gap widened
  // by DkGroupedText / DkMoneyText (a plain Text draws U+202F too narrow).
  for (final preview in accountsPreviews) {
    testWidgets('${preview.id}: money is formatted and rendered by the kit', (
      tester,
    ) async {
      await _pump(
        tester,
        preview,
        size: const Size(390, 844),
        ratio: 1,
        brightness: Brightness.light,
      );
      expect(moneyProblems(tester), isEmpty);
    });
  }

  // Admin withdrawal rows: the content block (icon, amount, «driver · date»,
  // chip) is the same height in every row, and so is every row with buttons.
  for (final id in [
    '24_admin_withdrawals_pending',
    '25_admin_withdrawals_all',
    '28_admin_marked_paid',
  ]) {
    for (final width in [360.0, 390.0]) {
      testWidgets('$id at ${width.toInt()} dp: rows have equal heights', (
        tester,
      ) async {
        final preview = accountsPreviews.firstWhere((p) => p.id == id);
        await _pump(
          tester,
          preview,
          size: Size(width, 844),
          ratio: 1,
          brightness: Brightness.light,
        );
        final tiles = find.byType(DkWithdrawalTile);
        final content = find.descendant(
          of: tiles,
          matching: find.byType(MergeSemantics),
        );
        final heights = {
          for (final element in content.evaluate())
            tester.getSize(find.byWidget(element.widget)).height,
        };
        expect(heights, hasLength(1), reason: 'content heights: $heights');
        final withButtons = {
          for (final element in tiles.evaluate())
            if ((element.widget as DkWithdrawalTile).actions != null)
              tester.getSize(find.byWidget(element.widget)).height,
        };
        expect(withButtons.length, lessThanOrEqualTo(1));
      });
    }
  }
}

/// Texts with ₸ that break the money rules (empty when all is well).
List<String> moneyProblems(WidgetTester tester) {
  const separator = ' ';
  final problems = <String>[];
  for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
    final text = rich.text.toPlainText();
    // A lone «₸» is the currency suffix of a money field.
    if (!text.contains('₸') || text.trim() == '₸') continue;
    for (var i = text.indexOf('₸'); i >= 0; i = text.indexOf('₸', i + 1)) {
      if (i == 0 || text[i - 1] != separator) {
        problems.add('no U+202F before ₸ in "$text"');
      }
    }
    if (RegExp(r'-\d[\d ]* ₸').hasMatch(text)) {
      problems.add('hyphen instead of U+2212 in "$text"');
    }
    var widened = false;
    rich.text.visitChildren((span) {
      if (span is TextSpan &&
          span.text == separator &&
          (span.style?.letterSpacing ?? 0) > 0) {
        widened = true;
      }
      return !widened;
    });
    if (!widened) problems.add('narrow (not widened) money gap in "$text"');
  }
  return problems;
}
