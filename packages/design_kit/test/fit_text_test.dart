import 'package:design_kit/design_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Each render object of type [T] once (`allRenderObjects` repeats a render
/// object for every element above it).
List<T> _each<T>(WidgetTester tester) =>
    tester.allRenderObjects.whereType<T>().toSet().toList();

/// [child] in a box of [width] × [height] (unbounded height when null).
Widget _box(Widget child, {double width = 200, double? height}) => MaterialApp(
  theme: DkTheme.light(),
  home: Scaffold(
    body: Center(
      child: SizedBox(width: width, height: height, child: child),
    ),
  ),
);

void main() {
  const style = TextStyle(fontSize: 20, height: 1);

  testWidgets('a label that fits is drawn at full size, on one line', (
    tester,
  ) async {
    await tester.pumpWidget(_box(const DkFitText('ok', style: style)));

    final fit = _each<RenderDkFitLines>(tester).single;
    expect(fit.scale, 1.0);
    expect(fit.cut, isFalse);
    expect(fit.size.height, 20);
  });

  testWidgets('a slightly long label shrinks (not below 85 %), no ellipsis', (
    tester,
  ) async {
    // Ahem: every glyph is 1 em wide, so 11 glyphs at 20 = 220 > 200.
    await tester.pumpWidget(_box(const DkFitText('abcdefghijk', style: style)));
    final fit = _each<RenderDkFitLines>(tester).single;
    expect(fit.scale, closeTo(200 / 220, 0.001));
    expect(fit.cut, isFalse);
    expect(fit.size.width, lessThanOrEqualTo(200));
  });

  testWidgets('a long label stops at 85 % and ends in an ellipsis, with a '
      'tooltip carrying the full text', (tester) async {
    const long = 'abcdefghijklmnopqrstuvwxyz';
    await tester.pumpWidget(_box(const DkFitText(long, style: style)));
    await tester.pump();

    final fit = _each<RenderDkFitLines>(tester).single;
    expect(fit.scale, dkMinFitScale);
    expect(fit.cut, isTrue);
    // The box keeps the natural height: a long label is as tall as a short.
    expect(fit.size.height, 20);
    expect(find.byType(Tooltip), findsOneWidget);
    expect(tester.widget<Tooltip>(find.byType(Tooltip)).message, long);
  });

  testWidgets(
    'a line that may not be cut stops at 85 % and keeps every digit',
    (tester) async {
      await tester.pumpWidget(
        _box(
          const DkFitLines([
            DkLine('1234567890123', style: style, ellipsis: false),
          ]),
        ),
      );
      final fit = _each<RenderDkFitLines>(tester).single;
      expect(fit.scale, dkMinFitScale);
      expect(fit.cut, isFalse);
      // It reports what it needs: 85 % of its full width.
      expect(
        fit.getMinIntrinsicWidth(double.infinity),
        closeTo(260 * 0.85, 0.01),
      );
    },
  );

  testWidgets('two lines in a fixed height shrink together to fit it', (
    tester,
  ) async {
    await tester.pumpWidget(
      _box(
        const DkFitLines([
          DkLine('ab', style: style),
          DkLine('cd', style: style),
        ]),
        height: 36,
      ),
    );
    final fit = _each<RenderDkFitLines>(tester).single;
    expect(fit.scale, closeTo(0.9, 0.001));
    expect(fit.size.height, 36);
  });

  testWidgets('semantics carry the full text even when it is cut', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    const long = 'abcdefghijklmnopqrstuvwxyz';
    await tester.pumpWidget(_box(const DkFitText(long, style: style)));
    expect(find.bySemanticsLabel(long), findsOneWidget);
    handle.dispose();
  });

  group('DkAdaptivePair', () {
    Widget pair(String a, String b, double width) => _box(
      DkAdaptivePair(
        gap: 8,
        first: DkFitLines([DkLine(a, style: style, ellipsis: false)]),
        second: DkFitLines([DkLine(b, style: style, ellipsis: false)]),
      ),
      width: width,
    );

    testWidgets('side by side while both fit at 85 % in half the width', (
      tester,
    ) async {
      await tester.pumpWidget(pair('abcd', 'efgh', 208)); // half = 100
      final render = _each<RenderDkAdaptivePair>(tester).single;
      expect(render.stacked, isFalse);
      expect(render.size.height, 20);
    });

    testWidgets('stacked at full width when one does not', (tester) async {
      // 7 glyphs × 20 × 0.85 = 119 > 100.
      await tester.pumpWidget(pair('abcdefg', 'ef', 208));
      final render = _each<RenderDkAdaptivePair>(tester).single;
      expect(render.stacked, isTrue);
      expect(render.size.height, 20 + 8 + 20);
      final fits = _each<RenderDkFitLines>(tester);
      expect(fits.every((f) => !f.cut), isTrue);
    });
  });

  group('DkAmountRow', () {
    Widget row(String start, String amount, double width) => _box(
      DkAmountRow(
        gap: 8,
        start: DkFitLines([DkLine(start, style: style)]),
        end: DkFitLines([DkLine(amount, style: style, ellipsis: false)]),
      ),
      width: width,
    );

    testWidgets('the text column gives way first', (tester) async {
      await tester.pumpWidget(row('abcdefghijklmnop', '1234', 200));
      final render = _each<RenderDkAmountRow>(tester).single;
      final fits = _each<RenderDkFitLines>(tester).toList();
      expect(render.stacked, isFalse);
      expect(fits[0].cut, isTrue, reason: 'the text ends in «…»');
      expect(fits[1].scale, 1.0, reason: 'the amount keeps its size');
    });

    testWidgets('an amount that cannot fit at 85 % moves to its own line', (
      tester,
    ) async {
      // A text column that may not be cut either (a time range).
      await tester.pumpWidget(
        _box(
          DkAmountRow(
            gap: 8,
            start: const DkFitLines([
              DkLine('08:10 – 08:32', style: style, ellipsis: false),
            ]),
            end: const DkFitLines([
              DkLine('29999970', style: style, ellipsis: false),
            ]),
          ),
          width: 300,
        ),
      );
      final render = _each<RenderDkAmountRow>(tester).single;
      final fits = _each<RenderDkFitLines>(tester);
      expect(render.stacked, isTrue);
      expect(fits.every((f) => !f.cut), isTrue);
      expect(render.size.height, greaterThan(40));
    });
  });

  group('short form', () {
    Widget line(double width) => _box(
      const DkFitLines([
        DkLine('abcdefgh 38', short: 'abcdefgh', style: style),
      ]),
      width: width,
    );

    testWidgets('the full text while it fits at 85 %', (tester) async {
      // 11 glyphs × 20 = 220; 220 × 0.85 = 187 ≤ 200.
      await tester.pumpWidget(line(200));
      // Both forms are built; only the chosen one is drawn and hit.
      expect(find.text('abcdefgh 38').hitTestable(), findsOneWidget);
      expect(find.text('abcdefgh').hitTestable(), findsNothing);
      final fit = _each<RenderDkFitLines>(tester).single;
      expect(fit.scale, closeTo(200 / 220, 0.001));
    });

    testWidgets('the short form, at full size, when it does not', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      // 187 > 170: the short form (8 × 20 = 160) fits without shrinking.
      await tester.pumpWidget(line(170));
      final fit = _each<RenderDkFitLines>(tester).single;
      expect(fit.scale, 1.0);
      expect(fit.cut, isFalse);
      expect(
        find.bySemanticsLabel('abcdefgh 38'),
        findsOneWidget,
        reason: 'screen readers keep the full text',
      );
      handle.dispose();
    });
  });
}
