import 'package:flutter/material.dart';

/// Semantic color tokens. Components read colors only from here.
///
/// Every text/background pair meets WCAG AA (4.5:1) and every control outline
/// meets 3:1 in both themes; see `DESIGN.md` and `test/contrast_test.dart`.
@immutable
class DkColors extends ThemeExtension<DkColors> {
  /// Creates a color set. Prefer [DkColors.light] / [DkColors.dark].
  const new({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.primary,
    required this.onPrimary,
    required this.positive,
    required this.cash,
    required this.card,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.focus,
  });

  /// Daylight theme: high contrast against sun glare.
  static const DkColors light = DkColors(
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF1F5F9),
    border: Color(0xFFE2E8F0),
    outline: Color(0xFF64748B),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    primary: Color(0xFF15803D),
    onPrimary: Color(0xFFFFFFFF),
    positive: Color(0xFF15803D),
    cash: Color(0xFFB45309),
    card: Color(0xFF1D4ED8),
    error: Color(0xFFB91C1C),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    focus: Color(0xFF0F172A),
  );

  /// Night theme: near-black OLED background, low emission.
  static const DkColors dark = DkColors(
    background: Color(0xFF020617),
    surface: Color(0xFF0F172A),
    surfaceMuted: Color(0xFF1E293B),
    border: Color(0xFF334155),
    outline: Color(0xFF64748B),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    primary: Color(0xFF22C55E),
    onPrimary: Color(0xFF052E16),
    positive: Color(0xFF4ADE80),
    cash: Color(0xFFFBBF24),
    card: Color(0xFF60A5FA),
    error: Color(0xFFF87171),
    onError: Color(0xFF450A0A),
    errorContainer: Color(0xFF450A0A),
    onErrorContainer: Color(0xFFFECACA),
    focus: Color(0xFFF8FAFC),
  );

  /// App background behind cards.
  final Color background;

  /// Cards, sheets, inputs.
  final Color surface;

  /// Subtle fills: skeletons, chips, pressed rows.
  final Color surfaceMuted;

  /// Decorative separators (not used as the only boundary of a control).
  final Color border;

  /// Boundaries of interactive controls (>= 3:1 against [surface]).
  final Color outline;

  /// Main text and money figures.
  final Color textPrimary;

  /// Labels and supporting text (still >= 4.5:1).
  final Color textSecondary;

  /// Primary actions.
  final Color primary;

  /// Content on [primary].
  final Color onPrimary;

  /// Earnings / net payout figures.
  final Color positive;

  /// Cash payment accent (always paired with an icon and a label).
  final Color cash;

  /// Card payment accent (always paired with an icon and a label).
  final Color card;

  /// Errors and destructive actions.
  final Color error;

  /// Content on [error].
  final Color onError;

  /// Background of error banners.
  final Color errorContainer;

  /// Text on [errorContainer].
  final Color onErrorContainer;

  /// Keyboard/accessibility focus ring.
  final Color focus;

  @override
  DkColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? border,
    Color? outline,
    Color? textPrimary,
    Color? textSecondary,
    Color? primary,
    Color? onPrimary,
    Color? positive,
    Color? cash,
    Color? card,
    Color? error,
    Color? onError,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? focus,
  }) {
    return DkColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      outline: outline ?? this.outline,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      positive: positive ?? this.positive,
      cash: cash ?? this.cash,
      card: card ?? this.card,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      errorContainer: errorContainer ?? this.errorContainer,
      onErrorContainer: onErrorContainer ?? this.onErrorContainer,
      focus: focus ?? this.focus,
    );
  }

  @override
  DkColors lerp(covariant DkColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return DkColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      border: l(border, other.border),
      outline: l(outline, other.outline),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      primary: l(primary, other.primary),
      onPrimary: l(onPrimary, other.onPrimary),
      positive: l(positive, other.positive),
      cash: l(cash, other.cash),
      card: l(card, other.card),
      error: l(error, other.error),
      onError: l(onError, other.onError),
      errorContainer: l(errorContainer, other.errorContainer),
      onErrorContainer: l(onErrorContainer, other.onErrorContainer),
      focus: l(focus, other.focus),
    );
  }
}
