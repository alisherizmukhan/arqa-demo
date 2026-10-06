import 'package:flutter/material.dart';

/// Color tokens, DESIGN.md §2.1. Components read colors only from here.
@immutable
class DkColors extends ThemeExtension<DkColors> {
  /// Creates a color set. Prefer [DkColors.light] / [DkColors.dark].
  const new({
    required this.bg,
    required this.surface,
    required this.surfaceMuted,
    required this.segmentTrack,
    required this.segmentThumb,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.iconDisabled,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.success,
    required this.successSoft,
    required this.error,
    required this.errorSoft,
    required this.inverseSurface,
    required this.onInverse,
    required this.inverseAccent,
    required this.inverseError,
    required this.inverseSuccess,
    required this.skeleton,
    required this.splitNeutral,
    required this.disabledFill,
    required this.scrim,
  });

  /// Light theme.
  static const DkColors light = DkColors(
    bg: Color(0xFFF4F5F7),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEEF0F3),
    segmentTrack: Color(0xFFE9ECF0),
    segmentThumb: Color(0xFFFFFFFF),
    border: Color(0xFFD5DAE1),
    divider: Color(0xFFE6E9EE),
    textPrimary: Color(0xFF0F1419),
    textSecondary: Color(0xFF4A5260),
    textTertiary: Color(0xFF5F6673),
    textDisabled: Color(0xFF8A919C),
    iconDisabled: Color(0xFFC3C8D0),
    accent: Color(0xFF2450D8),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFE8EEFC),
    success: Color(0xFF127A4B),
    successSoft: Color(0xFFE3F4EB),
    error: Color(0xFFC2261F),
    errorSoft: Color(0xFFFCE9E8),
    inverseSurface: Color(0xFF1A1F26),
    onInverse: Color(0xFFF2F4F7),
    inverseAccent: Color(0xFF9DB4FF),
    inverseError: Color(0xFFFF8A80),
    inverseSuccess: Color(0xFF6FD3A0),
    skeleton: Color(0xFFE3E6EB),
    splitNeutral: Color(0xFF9AA3AF),
    disabledFill: Color(0xFFE1E4E9),
    scrim: Color(0x7A0F1419),
  );

  /// Dark theme.
  static const DkColors dark = DkColors(
    bg: Color(0xFF0B0D10),
    surface: Color(0xFF16191E),
    surfaceMuted: Color(0xFF22262D),
    segmentTrack: Color(0xFF22262D),
    segmentThumb: Color(0xFF343A43),
    border: Color(0xFF343A43),
    divider: Color(0xFF262B33),
    textPrimary: Color(0xFFF2F4F7),
    textSecondary: Color(0xFFB4BAC4),
    textTertiary: Color(0xFF8B93A0),
    textDisabled: Color(0xFF5B6370),
    iconDisabled: Color(0xFF3F4550),
    accent: Color(0xFF7B9BFF),
    onAccent: Color(0xFF0B0D10),
    accentSoft: Color(0xFF1C2645),
    success: Color(0xFF4CC38A),
    successSoft: Color(0xFF12301F),
    error: Color(0xFFFF6B61),
    errorSoft: Color(0xFF3A1716),
    inverseSurface: Color(0xFFF2F4F7),
    onInverse: Color(0xFF0F1419),
    inverseAccent: Color(0xFF2450D8),
    inverseError: Color(0xFFC2261F),
    inverseSuccess: Color(0xFF127A4B),
    skeleton: Color(0xFF262B33),
    splitNeutral: Color(0xFF5B6370),
    disabledFill: Color(0xFF2A2F37),
    scrim: Color(0xA3000000),
  );

  /// Screen background, bottom bar.
  final Color bg;

  /// Cards, fields, day switcher, dialog.
  final Color surface;

  /// Icon tiles, disabled fields.
  final Color surfaceMuted;

  /// Segmented control track.
  final Color segmentTrack;

  /// Selected segment.
  final Color segmentThumb;

  /// Field border (default).
  final Color border;

  /// List dividers, card divider, bottom-bar top border.
  final Color divider;

  /// Main text, amounts.
  final Color textPrimary;

  /// Field labels, trip meta line, body.
  final Color textSecondary;

  /// Helpers, «комиссия …», metric labels, weekday. ≥ 4.5:1 on [surface].
  final Color textTertiary;

  /// Disabled button text.
  final Color textDisabled;

  /// Disabled «next day» chevron.
  final Color iconDisabled;

  /// Primary button, FAB, «На руки», focus, card segment.
  final Color accent;

  /// Text/icon on [accent].
  final Color onAccent;

  /// Focus ring, empty-state tile, «+1 день» badge, new-row highlight.
  final Color accentSoft;

  /// Reserved.
  final Color success;

  /// Reserved.
  final Color successSoft;

  /// Field errors, error icons.
  final Color error;

  /// Error-state / dialog icon tile.
  final Color errorSoft;

  /// Snackbar.
  final Color inverseSurface;

  /// Snackbar text.
  final Color onInverse;

  /// Snackbar action.
  final Color inverseAccent;

  /// «Нет связи» icon in the snackbar.
  final Color inverseError;

  /// «Поездка добавлена» icon.
  final Color inverseSuccess;

  /// DkSkeleton.
  final Color skeleton;

  /// Cash segment of DkSplitBar.
  final Color splitNeutral;

  /// Disabled button background.
  final Color disabledFill;

  /// Behind DkDialog.
  final Color scrim;

  /// Every token by its DESIGN.md name, for tests and the showcase.
  Map<String, Color> get all => {
    'bg': bg,
    'surface': surface,
    'surfaceMuted': surfaceMuted,
    'segmentTrack': segmentTrack,
    'segmentThumb': segmentThumb,
    'border': border,
    'divider': divider,
    'textPrimary': textPrimary,
    'textSecondary': textSecondary,
    'textTertiary': textTertiary,
    'textDisabled': textDisabled,
    'iconDisabled': iconDisabled,
    'accent': accent,
    'onAccent': onAccent,
    'accentSoft': accentSoft,
    'success': success,
    'successSoft': successSoft,
    'error': error,
    'errorSoft': errorSoft,
    'inverseSurface': inverseSurface,
    'onInverse': onInverse,
    'inverseAccent': inverseAccent,
    'inverseError': inverseError,
    'inverseSuccess': inverseSuccess,
    'skeleton': skeleton,
    'splitNeutral': splitNeutral,
    'disabledFill': disabledFill,
    'scrim': scrim,
  };

  @override
  DkColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceMuted,
    Color? segmentTrack,
    Color? segmentThumb,
    Color? border,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? iconDisabled,
    Color? accent,
    Color? onAccent,
    Color? accentSoft,
    Color? success,
    Color? successSoft,
    Color? error,
    Color? errorSoft,
    Color? inverseSurface,
    Color? onInverse,
    Color? inverseAccent,
    Color? inverseError,
    Color? inverseSuccess,
    Color? skeleton,
    Color? splitNeutral,
    Color? disabledFill,
    Color? scrim,
  }) {
    return DkColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      segmentTrack: segmentTrack ?? this.segmentTrack,
      segmentThumb: segmentThumb ?? this.segmentThumb,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      iconDisabled: iconDisabled ?? this.iconDisabled,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentSoft: accentSoft ?? this.accentSoft,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      error: error ?? this.error,
      errorSoft: errorSoft ?? this.errorSoft,
      inverseSurface: inverseSurface ?? this.inverseSurface,
      onInverse: onInverse ?? this.onInverse,
      inverseAccent: inverseAccent ?? this.inverseAccent,
      inverseError: inverseError ?? this.inverseError,
      inverseSuccess: inverseSuccess ?? this.inverseSuccess,
      skeleton: skeleton ?? this.skeleton,
      splitNeutral: splitNeutral ?? this.splitNeutral,
      disabledFill: disabledFill ?? this.disabledFill,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  DkColors lerp(covariant DkColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return DkColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      segmentTrack: l(segmentTrack, other.segmentTrack),
      segmentThumb: l(segmentThumb, other.segmentThumb),
      border: l(border, other.border),
      divider: l(divider, other.divider),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      textDisabled: l(textDisabled, other.textDisabled),
      iconDisabled: l(iconDisabled, other.iconDisabled),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      accentSoft: l(accentSoft, other.accentSoft),
      success: l(success, other.success),
      successSoft: l(successSoft, other.successSoft),
      error: l(error, other.error),
      errorSoft: l(errorSoft, other.errorSoft),
      inverseSurface: l(inverseSurface, other.inverseSurface),
      onInverse: l(onInverse, other.onInverse),
      inverseAccent: l(inverseAccent, other.inverseAccent),
      inverseError: l(inverseError, other.inverseError),
      inverseSuccess: l(inverseSuccess, other.inverseSuccess),
      skeleton: l(skeleton, other.skeleton),
      splitNeutral: l(splitNeutral, other.splitNeutral),
      disabledFill: l(disabledFill, other.disabledFill),
      scrim: l(scrim, other.scrim),
    );
  }
}
