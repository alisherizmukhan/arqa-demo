import 'package:design_kit/design_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/scenarios.dart';

/// Layout rules agreed for stage R4 (docs/DECISIONS.md), measured with the
/// real fonts.
void main() {
  setUpAll(loadAppFonts);

  Scenario scenario(String id) => scenarios.firstWhere((s) => s.id == id);

  Future<void> run(
    WidgetTester tester,
    String id, {
    required Size size,
    double textScale = 1,
  }) async {
    useDevice(tester, (
      size: size,
      textScale: textScale,
      brightness: Brightness.light,
      pixelRatio: 1,
    ));
    await scenario(id).run(tester);
    expect(tester.takeException(), isNull);
  }

  /// Number of laid-out lines of the [text] widget.
  int lines(WidgetTester tester, String text) => tester
      .renderObject<RenderParagraph>(find.text(text))
      .getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: text.length),
      )
      .map((box) => box.top.round())
      .toSet()
      .length;

  group('«+1 день» in the end field', () {
    testWidgets('360 dp, text 1.0: no clock icon, badge on the time line', (
      tester,
    ) async {
      await run(tester, '11_add_trip_midnight', size: const Size(360, 780));

      // Only the start field keeps its clock.
      expect(find.byIcon(DkIcons.time), findsOneWidget);
      final time = tester.getRect(find.text('00:20'));
      final badge = tester.getRect(find.text('+1 день'));
      expect(badge.center.dy, closeTo(time.center.dy, 1));
      expect(lines(tester, '00:20'), 1);
      expect(lines(tester, '+1 день'), 1);
      await disposeApp(tester);
    });

    testWidgets('360 dp, text 1.3: the field may grow; nothing wraps', (
      tester,
    ) async {
      await run(
        tester,
        '11_add_trip_midnight',
        size: const Size(360, 780),
        textScale: 1.3,
      );

      expect(lines(tester, '00:20'), 1);
      expect(lines(tester, '+1 день'), 1);
      await disposeApp(tester);
    });
  });

  group('success snackbar and the FAB', () {
    for (final (size, scale, beside) in [
      (const Size(390, 844), 1.0, true),
      (const Size(360, 780), 1.0, false),
      (const Size(390, 844), 1.3, false),
    ]) {
      testWidgets('${size.width.toInt()} dp, text $scale: '
          '${beside ? 'beside' : 'full width above'}, never overlapping', (
        tester,
      ) async {
        await run(tester, '06_day_trip_added', size: size, textScale: scale);

        final snack = tester.getRect(find.byType(DkSnackbarView));
        final fab = tester.getRect(find.byType(DkFab));
        expect(snack.overlaps(fab), isFalse);
        if (beside) {
          expect(snack.right, lessThanOrEqualTo(fab.left - 12));
          expect(snack.bottom, closeTo(fab.bottom, 0.5));
        } else {
          expect(snack.bottom, lessThanOrEqualTo(fab.top - 12));
          expect(snack.left, 16);
          expect(snack.right, size.width - 16);
        }
        await disposeApp(tester);
      });
    }
  });

  testWidgets('409 dialog at 390: both labels on one line', (tester) async {
    await run(tester, '12_add_trip_conflict_409', size: const Size(390, 844));

    expect(lines(tester, 'Сохранить как новую поездку'), 1);
    expect(lines(tester, 'Оставить сохранённую'), 1);
    await disposeApp(tester);
  });

  // At 360 dp the label gets 216 dp (dialog 312 − 2·24 padding − 2·24 button
  // padding) and needs ~240: two centred lines, the button grows.
  for (final scale in [1.0, 1.3]) {
    testWidgets('409 dialog at 360, text $scale: the long label wraps centred, '
        'the button grows, no ellipsis', (tester) async {
      await run(
        tester,
        '12_add_trip_conflict_409',
        size: const Size(360, 780),
        textScale: scale,
      );

      const text = 'Сохранить как новую поездку';
      final label = find.text(text);
      final paragraph = tester.renderObject<RenderParagraph>(label);
      expect(lines(tester, text), 2);
      expect(paragraph.textAlign, TextAlign.center);
      expect(paragraph.maxLines, isNull, reason: 'no ellipsis');
      expect(paragraph.didExceedMaxLines, isFalse);
      final button = find.ancestor(of: label, matching: find.byType(DkButton));
      final labelBox = tester.getRect(label);
      final buttonBox = tester.getRect(button);
      expect(buttonBox.top, lessThan(labelBox.top));
      expect(buttonBox.bottom, greaterThan(labelBox.bottom));
      if (scale == 1.0) expect(lines(tester, 'Оставить сохранённую'), 1);
      await disposeApp(tester);
    });
  }
}
