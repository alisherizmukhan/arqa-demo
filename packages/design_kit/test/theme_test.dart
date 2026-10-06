import 'package:design_kit/design_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (name, theme) in [
    ('light', DkTheme.light()),
    ('dark', DkTheme.dark()),
  ]) {
    test('$name theme carries every token extension', () {
      expect(theme.extension<DkColors>(), isNotNull);
      expect(theme.extension<DkTypography>(), isNotNull);
      expect(theme.extension<DkSpacing>(), isNotNull);
      expect(theme.extension<DkRadii>(), isNotNull);
      expect(theme.extension<DkSizes>(), isNotNull);
      expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
    });
  }

  test('brightness matches the palette', () {
    expect(DkTheme.light().brightness, Brightness.light);
    expect(DkTheme.dark().brightness, Brightness.dark);
    expect(DkTheme.dark().scaffoldBackgroundColor, DkColors.dark.background);
  });

  test('sizes respect the 48dp touch target', () {
    const sizes = DkSizes.standard;
    expect(sizes.minTouchTarget, greaterThanOrEqualTo(48));
    expect(sizes.controlHeight, greaterThanOrEqualTo(sizes.minTouchTarget));
    expect(sizes.listRowMinHeight, greaterThanOrEqualTo(sizes.minTouchTarget));
  });

  test('no text style is smaller than 14', () {
    final t = DkTypography.standard;
    for (final style in [
      t.moneyHero,
      t.moneyLarge,
      t.moneyMedium,
      t.title,
      t.titleSmall,
      t.body,
      t.bodyStrong,
      t.label,
    ]) {
      expect(style.fontSize, greaterThanOrEqualTo(14));
      expect(style.fontFamily, contains(dkFontFamily));
    }
    expect(t.body.fontSize, 16);
  });

  test('extensions lerp between themes', () {
    final mid = DkColors.light.lerp(DkColors.dark, 0.5);
    expect(mid.surface, isNot(DkColors.light.surface));
    expect(
      DkColors.light.lerp(DkColors.dark, 0).surface,
      DkColors.light.surface,
    );
    expect(DkSpacing.standard.lerp(null, 0.5), DkSpacing.standard);
    expect(
      DkTypography.standard.lerp(DkTypography.standard, 1).body.fontSize,
      16,
    );
  });

  test('copyWith overrides one token', () {
    final c = DkColors.light.copyWith(primary: const Color(0xFF000000));
    expect(c.primary, const Color(0xFF000000));
    expect(c.surface, DkColors.light.surface);
  });

  testWidgets('accessors fail loudly without a kit theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ColoredBox(color: context.dkColors.surface),
        ),
      ),
    );

    final error = tester.takeException();
    expect(error, isA<StateError>());
    expect(error.toString(), contains('DkTheme.light()'));
  });
}
