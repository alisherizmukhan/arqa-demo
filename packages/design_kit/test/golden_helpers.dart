import 'package:design_kit/design_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Kit styles reference `packages/design_kit/<family>` (as any app using the
/// kit sees them). Inside the kit's own tests the font manifest registers the
/// bare family names, so load the same files under the package names too.
Future<void> loadKitFonts() async {
  const families = {
    dkFontFamily: [
      'fonts/Manrope-Medium.ttf',
      'fonts/Manrope-SemiBold.ttf',
      'fonts/Manrope-Bold.ttf',
      'fonts/Manrope-ExtraBold.ttf',
    ],
    dkFallbackFontFamily: ['fonts/IBMPlexSans-Variable.ttf'],
  };
  for (final MapEntry(key: family, value: assets) in families.entries) {
    final loader = FontLoader('packages/$dkFontPackage/$family');
    for (final asset in assets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
}

/// [child] on the theme's background, as it appears in the app.
Widget themed(ThemeData theme, Widget child) => Theme(
  data: theme,
  child: Builder(
    builder: (context) => ColoredBox(
      color: context.dkColors.bg,
      child: Padding(
        padding: EdgeInsets.all(context.dkSpacing.s16),
        child: DefaultTextStyle(
          style: context.dkText.body.copyWith(
            color: context.dkColors.textPrimary,
          ),
          child: child,
        ),
      ),
    ),
  ),
);
