import 'package:design_kit/src/tokens/dk_colors.dart';
import 'package:design_kit/src/tokens/dk_dimensions.dart';
import 'package:design_kit/src/tokens/dk_typography.dart';
import 'package:flutter/material.dart';

/// Token accessors: `context.dkColors.primary`, `context.dkSpacing.md`, ...
extension DkThemeContext on BuildContext {
  /// Color tokens of the current theme.
  DkColors get dkColors => _extension<DkColors>();

  /// Type scale of the current theme.
  DkTypography get dkText => _extension<DkTypography>();

  /// Spacing scale of the current theme.
  DkSpacing get dkSpacing => _extension<DkSpacing>();

  /// Corner radii of the current theme.
  DkRadii get dkRadii => _extension<DkRadii>();

  /// Component sizes of the current theme.
  DkSizes get dkSizes => _extension<DkSizes>();

  T _extension<T extends ThemeExtension<T>>() {
    final value = Theme.of(this).extension<T>();
    if (value == null) {
      throw StateError(
        '$T is missing from the theme. Use DkTheme.light() / DkTheme.dark() '
        'as the MaterialApp theme.',
      );
    }
    return value;
  }
}
