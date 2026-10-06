import 'package:design_kit/src/tokens/dk_colors.dart';
import 'package:design_kit/src/tokens/dk_dimensions.dart';
import 'package:design_kit/src/tokens/dk_typography.dart';
import 'package:flutter/material.dart';

/// Light and dark `ThemeData` built from kit tokens.
///
/// Tokens are attached as `ThemeExtension`s; Material widgets (dialogs, date
/// pickers, snack bars) are themed from the same tokens so they match.
abstract final class DkTheme {
  /// Daylight theme.
  static ThemeData light() => _build(Brightness.light, DkColors.light);

  /// Night theme.
  static ThemeData dark() => _build(Brightness.dark, DkColors.dark);

  static ThemeData _build(Brightness brightness, DkColors c) {
    final text = DkTypography.standard;
    const spacing = DkSpacing.standard;
    const radii = DkRadii.standard;
    const sizes = DkSizes.standard;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.primary,
      onSecondary: c.onPrimary,
      error: c.error,
      onError: c.onError,
      errorContainer: c.errorContainer,
      onErrorContainer: c.onErrorContainer,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerHighest: c.surfaceMuted,
      surfaceContainerHigh: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerLow: c.surface,
      outline: c.outline,
      outlineVariant: c.border,
      inverseSurface: c.textPrimary,
      onInverseSurface: c.surface,
    );

    final textTheme = TextTheme(
      displaySmall: text.moneyHero,
      headlineMedium: text.moneyLarge,
      headlineSmall: text.title,
      titleLarge: text.title,
      titleMedium: text.titleSmall,
      titleSmall: text.bodyStrong,
      bodyLarge: text.body,
      bodyMedium: text.body,
      bodySmall: text.label,
      labelLarge: text.bodyStrong,
      labelMedium: text.label,
      labelSmall: text.label,
    ).apply(bodyColor: c.textPrimary, displayColor: c.textPrimary);

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radii.md),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      fontFamily: 'packages/$dkFontPackage/$dkFontFamily',
      textTheme: textTheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.title.copyWith(color: c.textPrimary),
      ),
      dividerTheme: DividerThemeData(
        color: c.border,
        thickness: sizes.borderWidth,
        space: sizes.borderWidth,
      ),
      iconTheme: IconThemeData(color: c.textPrimary, size: sizes.iconMd),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.textPrimary,
        contentTextStyle: text.body.copyWith(color: c.surface),
        actionTextColor: c.surface,
        shape: controlShape,
        insetPadding: EdgeInsets.all(spacing.md),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        extendedTextStyle: text.bodyStrong,
        extendedSizeConstraints: BoxConstraints.tightFor(
          height: sizes.controlHeight,
        ),
        shape: controlShape,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        titleTextStyle: text.title.copyWith(color: c.textPrimary),
        contentTextStyle: text.body.copyWith(color: c.textPrimary),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.surface,
        headerBackgroundColor: c.surface,
        headerForegroundColor: c.textPrimary,
      ),
      timePickerTheme: TimePickerThemeData(backgroundColor: c.surface),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          textStyle: text.bodyStrong,
          minimumSize: Size(sizes.minTouchTarget, sizes.minTouchTarget),
          shape: controlShape,
        ),
      ),
      extensions: [c, text, spacing, radii, sizes],
    );
  }
}
