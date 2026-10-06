import 'package:design_kit/src/tokens/dk_colors.dart';
import 'package:design_kit/src/tokens/dk_dimensions.dart';
import 'package:design_kit/src/tokens/dk_typography.dart';
import 'package:flutter/material.dart';

/// Light and dark `ThemeData` from the kit tokens (DESIGN.md §2).
///
/// Light and dark share one layout; only colors (and shadows, which are off in
/// dark) differ. Material widgets that the kit does not replace (date/time
/// pickers, confirmation dialogs) are themed from the same tokens.
abstract final class DkTheme {
  /// Light theme.
  static ThemeData light() =>
      _build(Brightness.light, DkColors.light, DkElevation.light);

  /// Dark theme.
  static ThemeData dark() =>
      _build(Brightness.dark, DkColors.dark, DkElevation.dark);

  static ThemeData _build(
    Brightness brightness,
    DkColors c,
    DkElevation elevation,
  ) {
    final text = DkTypography.standard;
    const spacing = DkSpacing.standard;
    const radii = DkRadii.standard;
    const sizes = DkSizes.standard;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.onAccent,
      primaryContainer: c.accentSoft,
      onPrimaryContainer: c.accent,
      secondary: c.accent,
      onSecondary: c.onAccent,
      error: c.error,
      onError: c.onAccent,
      errorContainer: c.errorSoft,
      onErrorContainer: c.error,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surface,
      surfaceContainerHighest: c.surfaceMuted,
      outline: c.border,
      outlineVariant: c.divider,
      inverseSurface: c.inverseSurface,
      onInverseSurface: c.onInverse,
      inversePrimary: c.inverseAccent,
      scrim: c.scrim,
      shadow: c.textPrimary,
    );

    final textTheme = TextTheme(
      displaySmall: text.moneyHero,
      headlineSmall: text.titleL,
      titleLarge: text.titleDialog,
      titleMedium: text.titleM,
      titleSmall: text.bodyStrong,
      bodyLarge: text.body,
      bodyMedium: text.body,
      bodySmall: text.caption,
      labelLarge: text.bodyStrong,
      labelMedium: text.label,
      labelSmall: text.captionStrong,
    ).apply(bodyColor: c.textPrimary, displayColor: c.textPrimary);

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radii.lg),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      dividerColor: c.divider,
      fontFamily: 'packages/$dkFontPackage/$dkFontFamily',
      textTheme: textTheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: sizes.appBarHeight,
        titleTextStyle: text.titleM.copyWith(color: c.textPrimary),
      ),
      dividerTheme: DividerThemeData(
        color: c.divider,
        thickness: sizes.fieldBorder,
        space: sizes.fieldBorder,
      ),
      iconTheme: IconThemeData(color: c.textPrimary, size: sizes.iconNav),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        refreshBackgroundColor: c.surface,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.inverseSurface,
        contentTextStyle: text.bodyS.copyWith(color: c.onInverse),
        actionTextColor: c.inverseAccent,
        shape: shape,
        insetPadding: EdgeInsets.all(spacing.screenGutter),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        barrierColor: c.scrim,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.xl),
        ),
        titleTextStyle: text.titleDialog.copyWith(color: c.textPrimary),
        contentTextStyle: text.bodyMd.copyWith(color: c.textSecondary),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.surface,
        headerBackgroundColor: c.surface,
        headerForegroundColor: c.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.xl),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.xl),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accent,
          textStyle: text.bodyStrong,
          minimumSize: Size(sizes.tapTargetMin, sizes.textButtonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radii.md),
          ),
        ),
      ),
      extensions: [c, text, spacing, radii, elevation, sizes],
    );
  }
}
