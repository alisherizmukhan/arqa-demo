import 'package:design_kit/design_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (name, theme, colors, elevation) in [
    ('light', DkTheme.light(), DkColors.light, DkElevation.light),
    ('dark', DkTheme.dark(), DkColors.dark, DkElevation.dark),
  ]) {
    test('$name theme carries every token extension', () {
      expect(theme.extension<DkColors>(), colors);
      expect(theme.extension<DkTypography>(), isNotNull);
      expect(theme.extension<DkSpacing>(), DkSpacing.standard);
      expect(theme.extension<DkRadii>(), DkRadii.standard);
      expect(theme.extension<DkElevation>(), elevation);
      expect(theme.extension<DkSizes>(), DkSizes.standard);
    });

    test('$name theme maps tokens onto Material', () {
      expect(theme.scaffoldBackgroundColor, colors.bg);
      expect(theme.colorScheme.primary, colors.accent);
      expect(theme.colorScheme.onPrimary, colors.onAccent);
      expect(theme.colorScheme.surface, colors.surface);
      expect(theme.colorScheme.error, colors.error);
      expect(theme.dialogTheme.barrierColor, colors.scrim);
      expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
    });
  }

  test('brightness matches the palette', () {
    expect(DkTheme.light().brightness, Brightness.light);
    expect(DkTheme.dark().brightness, Brightness.dark);
  });

  test('extensions lerp and copy', () {
    final mid = DkColors.light.lerp(DkColors.dark, 0.5);
    expect(mid.surface, isNot(DkColors.light.surface));
    expect(DkColors.light.lerp(DkColors.dark, 0).all, DkColors.light.all);
    expect(DkSpacing.standard.lerp(null, 0.5), DkSpacing.standard);
    expect(DkRadii.standard.lerp(DkRadii.standard, 1).xl, 24);
    expect(DkSizes.standard.lerp(DkSizes.standard, 1).fieldHeight, 56);
    expect(
      DkTypography.standard.lerp(DkTypography.standard, 1).body.fontSize,
      16,
    );
    // Shadows fade out when switching to dark.
    expect(DkElevation.light.lerp(DkElevation.dark, 1).e1, isEmpty);

    final c = DkColors.light.copyWith(accent: const Color(0xFF000000));
    expect(c.accent, const Color(0xFF000000));
    expect(c.surface, DkColors.light.surface);
    expect(DkSizes.standard.copyWith(iconTile: 1).iconTile, 1);
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
