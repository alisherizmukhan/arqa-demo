import 'package:design_kit/src/tokens/dk_typography.dart' show dkLerp;
import 'package:flutter/material.dart';

/// 4/8dp spacing scale.
@immutable
class DkSpacing extends ThemeExtension<DkSpacing> {
  /// Creates a spacing scale. Prefer [DkSpacing.standard].
  const new({
    required this.xxs,
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
  });

  /// 4 · 8 · 12 · 16 · 24 · 32 · 48.
  static const DkSpacing standard = DkSpacing(
    xxs: 4,
    xs: 8,
    sm: 12,
    md: 16,
    lg: 24,
    xl: 32,
    xxl: 48,
  );

  /// 4dp: icon-to-text gaps.
  final double xxs;

  /// 8dp: minimum gap between tap targets.
  final double xs;

  /// 12dp: inside compact rows.
  final double sm;

  /// 16dp: screen gutters, card padding.
  final double md;

  /// 24dp: between sections.
  final double lg;

  /// 32dp: large section breaks.
  final double xl;

  /// 48dp: empty/error state breathing room.
  final double xxl;

  @override
  DkSpacing copyWith({
    double? xxs,
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
  }) {
    return DkSpacing(
      xxs: xxs ?? this.xxs,
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
    );
  }

  @override
  DkSpacing lerp(covariant DkSpacing? other, double t) {
    if (other == null) return this;
    return DkSpacing(
      xxs: dkLerp(xxs, other.xxs, t),
      xs: dkLerp(xs, other.xs, t),
      sm: dkLerp(sm, other.sm, t),
      md: dkLerp(md, other.md, t),
      lg: dkLerp(lg, other.lg, t),
      xl: dkLerp(xl, other.xl, t),
      xxl: dkLerp(xxl, other.xxl, t),
    );
  }
}

/// Corner radii.
@immutable
class DkRadii extends ThemeExtension<DkRadii> {
  /// Creates radii. Prefer [DkRadii.standard].
  const new({
    required this.sm,
    required this.md,
    required this.lg,
    required this.pill,
  });

  /// 8 · 12 · 16 · pill.
  static const DkRadii standard = DkRadii(sm: 8, md: 12, lg: 16, pill: 999);

  /// Skeleton lines, small chips.
  final double sm;

  /// Buttons, inputs.
  final double md;

  /// Cards.
  final double lg;

  /// Fully rounded.
  final double pill;

  @override
  DkRadii copyWith({double? sm, double? md, double? lg, double? pill}) {
    return DkRadii(
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      pill: pill ?? this.pill,
    );
  }

  @override
  DkRadii lerp(covariant DkRadii? other, double t) {
    if (other == null) return this;
    return DkRadii(
      sm: dkLerp(sm, other.sm, t),
      md: dkLerp(md, other.md, t),
      lg: dkLerp(lg, other.lg, t),
      pill: dkLerp(pill, other.pill, t),
    );
  }
}

/// Component sizes: touch targets, control heights, icons.
@immutable
class DkSizes extends ThemeExtension<DkSizes> {
  /// Creates sizes. Prefer [DkSizes.standard].
  const new({
    required this.minTouchTarget,
    required this.controlHeight,
    required this.listRowMinHeight,
    required this.iconSm,
    required this.iconMd,
    required this.iconLg,
    required this.borderWidth,
    required this.focusWidth,
  });

  /// Material's 48dp minimum; buttons and inputs are taller (56dp).
  static const DkSizes standard = DkSizes(
    minTouchTarget: 48,
    controlHeight: 56,
    listRowMinHeight: 64,
    iconSm: 20,
    iconMd: 24,
    iconLg: 48,
    borderWidth: 1,
    focusWidth: 2,
  );

  /// Smallest tappable area (Material 48dp).
  final double minTouchTarget;

  /// Buttons and text fields: easy to hit while not looking closely.
  final double controlHeight;

  /// Trip rows.
  final double listRowMinHeight;

  /// Inline icons.
  final double iconSm;

  /// Default icon size.
  final double iconMd;

  /// Empty/error state illustrations.
  final double iconLg;

  /// Card and divider strokes.
  final double borderWidth;

  /// Focused/error control outline.
  final double focusWidth;

  @override
  DkSizes copyWith({
    double? minTouchTarget,
    double? controlHeight,
    double? listRowMinHeight,
    double? iconSm,
    double? iconMd,
    double? iconLg,
    double? borderWidth,
    double? focusWidth,
  }) {
    return DkSizes(
      minTouchTarget: minTouchTarget ?? this.minTouchTarget,
      controlHeight: controlHeight ?? this.controlHeight,
      listRowMinHeight: listRowMinHeight ?? this.listRowMinHeight,
      iconSm: iconSm ?? this.iconSm,
      iconMd: iconMd ?? this.iconMd,
      iconLg: iconLg ?? this.iconLg,
      borderWidth: borderWidth ?? this.borderWidth,
      focusWidth: focusWidth ?? this.focusWidth,
    );
  }

  @override
  DkSizes lerp(covariant DkSizes? other, double t) {
    if (other == null) return this;
    return DkSizes(
      minTouchTarget: dkLerp(minTouchTarget, other.minTouchTarget, t),
      controlHeight: dkLerp(controlHeight, other.controlHeight, t),
      listRowMinHeight: dkLerp(listRowMinHeight, other.listRowMinHeight, t),
      iconSm: dkLerp(iconSm, other.iconSm, t),
      iconMd: dkLerp(iconMd, other.iconMd, t),
      iconLg: dkLerp(iconLg, other.iconLg, t),
      borderWidth: dkLerp(borderWidth, other.borderWidth, t),
      focusWidth: dkLerp(focusWidth, other.focusWidth, t),
    );
  }
}

/// Motion tokens. Components skip animation when the platform asks for
/// reduced motion (`MediaQuery.disableAnimations`).
abstract final class DkMotion {
  /// Press/state feedback.
  static const Duration fast = Duration(milliseconds: 150);

  /// Content cross-fades.
  static const Duration medium = Duration(milliseconds: 250);

  /// One skeleton pulse cycle.
  static const Duration skeletonPulse = Duration(milliseconds: 1200);

  /// Default easing.
  static const Curve curve = Curves.easeOutCubic;
}
