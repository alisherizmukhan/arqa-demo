import 'package:design_kit/src/tokens/dk_typography.dart' show dkLerp;
import 'package:flutter/material.dart';

/// Spacing, DESIGN.md §2.3: 8-pt grid with 4-pt half steps.
@immutable
class DkSpacing extends ThemeExtension<DkSpacing> {
  /// Creates a spacing scale. Prefer [DkSpacing.standard].
  const new({
    required this.s2,
    required this.s4,
    required this.s6,
    required this.s8,
    required this.s10,
    required this.s12,
    required this.s14,
    required this.s16,
    required this.s20,
    required this.s24,
    required this.s32,
    required this.s40,
    required this.s48,
    required this.s64,
    required this.screenGutter,
  });

  /// The scale from DESIGN.md.
  static const DkSpacing standard = DkSpacing(
    s2: 2,
    s4: 4,
    s6: 6,
    s8: 8,
    s10: 10,
    s12: 12,
    s14: 14,
    s16: 16,
    s20: 20,
    s24: 24,
    s32: 32,
    s40: 40,
    s48: 48,
    s64: 64,
    screenGutter: 16,
  );

  /// 2.
  final double s2;

  /// 4.
  final double s4;

  /// 6.
  final double s6;

  /// 8.
  final double s8;

  /// 10.
  final double s10;

  /// 12.
  final double s12;

  /// 14.
  final double s14;

  /// 16.
  final double s16;

  /// 20.
  final double s20;

  /// 24.
  final double s24;

  /// 32.
  final double s32;

  /// 40.
  final double s40;

  /// 48.
  final double s48;

  /// 64.
  final double s64;

  /// Side padding of every screen (16).
  final double screenGutter;

  @override
  DkSpacing copyWith({
    double? s2,
    double? s4,
    double? s6,
    double? s8,
    double? s10,
    double? s12,
    double? s14,
    double? s16,
    double? s20,
    double? s24,
    double? s32,
    double? s40,
    double? s48,
    double? s64,
    double? screenGutter,
  }) {
    return DkSpacing(
      s2: s2 ?? this.s2,
      s4: s4 ?? this.s4,
      s6: s6 ?? this.s6,
      s8: s8 ?? this.s8,
      s10: s10 ?? this.s10,
      s12: s12 ?? this.s12,
      s14: s14 ?? this.s14,
      s16: s16 ?? this.s16,
      s20: s20 ?? this.s20,
      s24: s24 ?? this.s24,
      s32: s32 ?? this.s32,
      s40: s40 ?? this.s40,
      s48: s48 ?? this.s48,
      s64: s64 ?? this.s64,
      screenGutter: screenGutter ?? this.screenGutter,
    );
  }

  @override
  DkSpacing lerp(covariant DkSpacing? other, double t) {
    if (other == null) return this;
    double l(double a, double b) => dkLerp(a, b, t);
    return DkSpacing(
      s2: l(s2, other.s2),
      s4: l(s4, other.s4),
      s6: l(s6, other.s6),
      s8: l(s8, other.s8),
      s10: l(s10, other.s10),
      s12: l(s12, other.s12),
      s14: l(s14, other.s14),
      s16: l(s16, other.s16),
      s20: l(s20, other.s20),
      s24: l(s24, other.s24),
      s32: l(s32, other.s32),
      s40: l(s40, other.s40),
      s48: l(s48, other.s48),
      s64: l(s64, other.s64),
      screenGutter: l(screenGutter, other.screenGutter),
    );
  }
}

/// Corner radii, DESIGN.md §2.4.
@immutable
class DkRadii extends ThemeExtension<DkRadii> {
  /// Creates radii. Prefer [DkRadii.standard].
  const new({
    required this.xs,
    required this.sm,
    required this.segment,
    required this.md,
    required this.segmentTrack,
    required this.lg,
    required this.xl,
    required this.pill,
  });

  /// The radii from DESIGN.md.
  static const DkRadii standard = DkRadii(
    xs: 4,
    sm: 8,
    segment: 10,
    md: 12,
    segmentTrack: 14,
    lg: 16,
    xl: 24,
    pill: 999,
  );

  /// 4: split-bar segments, wordmark dot.
  final double xs;

  /// 8: skeleton lines, badge.
  final double sm;

  /// 10: segmented-control thumb.
  final double segment;

  /// 12: text fields, icon tiles (40), icon buttons.
  final double md;

  /// 14: segmented-control track.
  final double segmentTrack;

  /// 16: cards, day switcher, buttons, snackbar, dialog icon tile.
  final double lg;

  /// 24: summary card, dialog, empty/error icon tile (80).
  final double xl;

  /// 999: FAB.
  final double pill;

  @override
  DkRadii copyWith({
    double? xs,
    double? sm,
    double? segment,
    double? md,
    double? segmentTrack,
    double? lg,
    double? xl,
    double? pill,
  }) {
    return DkRadii(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      segment: segment ?? this.segment,
      md: md ?? this.md,
      segmentTrack: segmentTrack ?? this.segmentTrack,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      pill: pill ?? this.pill,
    );
  }

  @override
  DkRadii lerp(covariant DkRadii? other, double t) {
    if (other == null) return this;
    double l(double a, double b) => dkLerp(a, b, t);
    return DkRadii(
      xs: l(xs, other.xs),
      sm: l(sm, other.sm),
      segment: l(segment, other.segment),
      md: l(md, other.md),
      segmentTrack: l(segmentTrack, other.segmentTrack),
      lg: l(lg, other.lg),
      xl: l(xl, other.xl),
      pill: l(pill, other.pill),
    );
  }
}

/// Shadows, DESIGN.md §2.5. Light only: in dark every list is empty and depth
/// comes from the surface colors.
@immutable
class DkElevation extends ThemeExtension<DkElevation> {
  /// Creates shadows. Prefer [DkElevation.light] / [DkElevation.dark].
  const new({
    required this.e1,
    required this.e1Hero,
    required this.e2Fab,
    required this.e3,
    required this.thumb,
  });

  /// Light theme shadows (`BoxShadow(offset: (0, y), blurRadius, color)`).
  static const DkElevation light = DkElevation(
    e1: [
      BoxShadow(
        offset: Offset(0, 1),
        blurRadius: 2,
        color: Color.fromRGBO(15, 20, 25, 0.06),
      ),
    ],
    e1Hero: [
      BoxShadow(
        offset: Offset(0, 1),
        blurRadius: 2,
        color: Color.fromRGBO(15, 20, 25, 0.06),
      ),
      BoxShadow(
        offset: Offset(0, 2),
        blurRadius: 8,
        color: Color.fromRGBO(15, 20, 25, 0.04),
      ),
    ],
    e2Fab: [
      BoxShadow(
        offset: Offset(0, 6),
        blurRadius: 16,
        color: Color.fromRGBO(36, 80, 216, 0.28),
      ),
    ],
    e3: [
      BoxShadow(
        offset: Offset(0, 8),
        blurRadius: 24,
        color: Color.fromRGBO(15, 20, 25, 0.24),
      ),
    ],
    thumb: [
      BoxShadow(
        offset: Offset(0, 1),
        blurRadius: 3,
        color: Color.fromRGBO(15, 20, 25, 0.12),
      ),
    ],
  );

  /// Dark theme: no shadows.
  static const DkElevation dark = DkElevation(
    e1: [],
    e1Hero: [],
    e2Fab: [],
    e3: [],
    thumb: [],
  );

  /// Day switcher, payment card, trip list card.
  final List<BoxShadow> e1;

  /// Summary card.
  final List<BoxShadow> e1Hero;

  /// FAB.
  final List<BoxShadow> e2Fab;

  /// Snackbar, dialog.
  final List<BoxShadow> e3;

  /// Selected segment.
  final List<BoxShadow> thumb;

  @override
  DkElevation copyWith({
    List<BoxShadow>? e1,
    List<BoxShadow>? e1Hero,
    List<BoxShadow>? e2Fab,
    List<BoxShadow>? e3,
    List<BoxShadow>? thumb,
  }) {
    return DkElevation(
      e1: e1 ?? this.e1,
      e1Hero: e1Hero ?? this.e1Hero,
      e2Fab: e2Fab ?? this.e2Fab,
      e3: e3 ?? this.e3,
      thumb: thumb ?? this.thumb,
    );
  }

  @override
  DkElevation lerp(covariant DkElevation? other, double t) {
    if (other == null) return this;
    // Interpolated shadows fade towards zero but stay in the list; at the end
    // of a theme animation use the target lists exactly (dark: none).
    if (t >= 1) return other;
    List<BoxShadow> l(List<BoxShadow> a, List<BoxShadow> b) =>
        BoxShadow.lerpList(a, b, t) ?? const [];
    return DkElevation(
      e1: l(e1, other.e1),
      e1Hero: l(e1Hero, other.e1Hero),
      e2Fab: l(e2Fab, other.e2Fab),
      e3: l(e3, other.e3),
      thumb: l(thumb, other.thumb),
    );
  }
}

/// Component sizes, DESIGN.md §2.6. Heights are **minimums**: components grow
/// with the system text scale instead of clipping (approved deviation).
@immutable
class DkSizes extends ThemeExtension<DkSizes> {
  /// Creates sizes. Prefer [DkSizes.standard].
  const new({
    required this.tapTargetMin,
    required this.buttonHeight,
    required this.textButtonHeight,
    required this.fieldHeight,
    required this.segmentedHeight,
    required this.daySwitcherHeight,
    required this.tripTileMinHeight,
    required this.headerHeight,
    required this.appBarHeight,
    required this.wordmarkDot,
    required this.iconTile,
    required this.iconTileIcon,
    required this.stateIconTile,
    required this.stateIcon,
    required this.dialogIconTile,
    required this.dialogIcon,
    required this.splitBarHeight,
    required this.splitBarGap,
    required this.iconNav,
    required this.iconAction,
    required this.iconField,
    required this.iconInline,
    required this.fieldBorder,
    required this.fieldBorderFocused,
    required this.focusRing,
    required this.spinnerStroke,
  });

  /// The sizes from DESIGN.md §2.6 (+ screen sizes from §4/§5).
  static const DkSizes standard = DkSizes(
    tapTargetMin: 48,
    buttonHeight: 56,
    textButtonHeight: 48,
    fieldHeight: 56,
    segmentedHeight: 56,
    daySwitcherHeight: 56,
    tripTileMinHeight: 72,
    headerHeight: 48,
    appBarHeight: 56,
    wordmarkDot: 12,
    iconTile: 40,
    iconTileIcon: 22,
    stateIconTile: 80,
    stateIcon: 36,
    dialogIconTile: 56,
    dialogIcon: 28,
    splitBarHeight: 8,
    splitBarGap: 3,
    iconNav: 24,
    iconAction: 22,
    iconField: 20,
    iconInline: 16,
    fieldBorder: 1,
    fieldBorderFocused: 2,
    focusRing: 4,
    spinnerStroke: 2.6,
  );

  /// Smallest tappable area (48).
  final double tapTargetMin;

  /// Primary/secondary button and FAB (min 56).
  final double buttonHeight;

  /// Text button (min 48).
  final double textButtonHeight;

  /// Text field (min 56).
  final double fieldHeight;

  /// Segmented control (min 56).
  final double segmentedHeight;

  /// Day switcher (min 56).
  final double daySwitcherHeight;

  /// Trip row (min 72).
  final double tripTileMinHeight;

  /// Wordmark row on the Day screen (min 48), DESIGN.md §5.1.
  final double headerHeight;

  /// Add-trip app bar (min 56), DESIGN.md §5.6.
  final double appBarHeight;

  /// Accent square of the wordmark (12), DESIGN.md §5.1.
  final double wordmarkDot;

  /// Icon tile (40, radius md).
  final double iconTile;

  /// Icon inside an icon tile (22).
  final double iconTileIcon;

  /// Empty/error state tile (80, radius xl).
  final double stateIconTile;

  /// Icon inside the state tile (36).
  final double stateIcon;

  /// Dialog icon tile (56, radius lg).
  final double dialogIconTile;

  /// Icon inside the dialog tile (28).
  final double dialogIcon;

  /// DkSplitBar height (8).
  final double splitBarHeight;

  /// Gap between DkSplitBar segments (3).
  final double splitBarGap;

  /// Navigation icons (24).
  final double iconNav;

  /// Tiles, FAB, buttons (22).
  final double iconAction;

  /// Fields, segments (20); also the button spinner.
  final double iconField;

  /// Inline error, chevron-down (16).
  final double iconInline;

  /// Default field border (1).
  final double fieldBorder;

  /// Focused/error field border (2).
  final double fieldBorderFocused;

  /// Focus ring outside the border (4, accentSoft).
  final double focusRing;

  /// Button spinner stroke (2.6).
  final double spinnerStroke;

  @override
  DkSizes copyWith({
    double? tapTargetMin,
    double? buttonHeight,
    double? textButtonHeight,
    double? fieldHeight,
    double? segmentedHeight,
    double? daySwitcherHeight,
    double? tripTileMinHeight,
    double? headerHeight,
    double? appBarHeight,
    double? wordmarkDot,
    double? iconTile,
    double? iconTileIcon,
    double? stateIconTile,
    double? stateIcon,
    double? dialogIconTile,
    double? dialogIcon,
    double? splitBarHeight,
    double? splitBarGap,
    double? iconNav,
    double? iconAction,
    double? iconField,
    double? iconInline,
    double? fieldBorder,
    double? fieldBorderFocused,
    double? focusRing,
    double? spinnerStroke,
  }) {
    return DkSizes(
      tapTargetMin: tapTargetMin ?? this.tapTargetMin,
      buttonHeight: buttonHeight ?? this.buttonHeight,
      textButtonHeight: textButtonHeight ?? this.textButtonHeight,
      fieldHeight: fieldHeight ?? this.fieldHeight,
      segmentedHeight: segmentedHeight ?? this.segmentedHeight,
      daySwitcherHeight: daySwitcherHeight ?? this.daySwitcherHeight,
      tripTileMinHeight: tripTileMinHeight ?? this.tripTileMinHeight,
      headerHeight: headerHeight ?? this.headerHeight,
      appBarHeight: appBarHeight ?? this.appBarHeight,
      wordmarkDot: wordmarkDot ?? this.wordmarkDot,
      iconTile: iconTile ?? this.iconTile,
      iconTileIcon: iconTileIcon ?? this.iconTileIcon,
      stateIconTile: stateIconTile ?? this.stateIconTile,
      stateIcon: stateIcon ?? this.stateIcon,
      dialogIconTile: dialogIconTile ?? this.dialogIconTile,
      dialogIcon: dialogIcon ?? this.dialogIcon,
      splitBarHeight: splitBarHeight ?? this.splitBarHeight,
      splitBarGap: splitBarGap ?? this.splitBarGap,
      iconNav: iconNav ?? this.iconNav,
      iconAction: iconAction ?? this.iconAction,
      iconField: iconField ?? this.iconField,
      iconInline: iconInline ?? this.iconInline,
      fieldBorder: fieldBorder ?? this.fieldBorder,
      fieldBorderFocused: fieldBorderFocused ?? this.fieldBorderFocused,
      focusRing: focusRing ?? this.focusRing,
      spinnerStroke: spinnerStroke ?? this.spinnerStroke,
    );
  }

  @override
  DkSizes lerp(covariant DkSizes? other, double t) {
    if (other == null) return this;
    double l(double a, double b) => dkLerp(a, b, t);
    return DkSizes(
      tapTargetMin: l(tapTargetMin, other.tapTargetMin),
      buttonHeight: l(buttonHeight, other.buttonHeight),
      textButtonHeight: l(textButtonHeight, other.textButtonHeight),
      fieldHeight: l(fieldHeight, other.fieldHeight),
      segmentedHeight: l(segmentedHeight, other.segmentedHeight),
      daySwitcherHeight: l(daySwitcherHeight, other.daySwitcherHeight),
      tripTileMinHeight: l(tripTileMinHeight, other.tripTileMinHeight),
      headerHeight: l(headerHeight, other.headerHeight),
      appBarHeight: l(appBarHeight, other.appBarHeight),
      wordmarkDot: l(wordmarkDot, other.wordmarkDot),
      iconTile: l(iconTile, other.iconTile),
      iconTileIcon: l(iconTileIcon, other.iconTileIcon),
      stateIconTile: l(stateIconTile, other.stateIconTile),
      stateIcon: l(stateIcon, other.stateIcon),
      dialogIconTile: l(dialogIconTile, other.dialogIconTile),
      dialogIcon: l(dialogIcon, other.dialogIcon),
      splitBarHeight: l(splitBarHeight, other.splitBarHeight),
      splitBarGap: l(splitBarGap, other.splitBarGap),
      iconNav: l(iconNav, other.iconNav),
      iconAction: l(iconAction, other.iconAction),
      iconField: l(iconField, other.iconField),
      iconInline: l(iconInline, other.iconInline),
      fieldBorder: l(fieldBorder, other.fieldBorder),
      fieldBorderFocused: l(fieldBorderFocused, other.fieldBorderFocused),
      focusRing: l(focusRing, other.focusRing),
      spinnerStroke: l(spinnerStroke, other.spinnerStroke),
    );
  }
}

/// Motion, DESIGN.md §4. Components skip animation when the platform asks for
/// reduced motion (`MediaQuery.disableAnimations`).
abstract final class DkMotion {
  /// Segmented thumb slide (200 ms, ease-out).
  static const Duration segment = Duration(milliseconds: 200);

  /// Segmented thumb curve.
  static const Curve segmentCurve = Curves.easeOut;

  /// One skeleton pulse cycle, 1 → 0.55 → 1 (1.4 s, ease-in-out).
  static const Duration skeletonPulse = Duration(milliseconds: 1400);

  /// Skeleton pulse curve.
  static const Curve skeletonCurve = Curves.easeInOut;

  /// Lowest skeleton opacity.
  static const double skeletonMinOpacity = 0.55;

  /// How long a newly added trip stays highlighted (~2 s).
  static const Duration highlight = Duration(seconds: 2);

  /// Success snackbar auto-dismiss (3 s).
  static const Duration successSnack = Duration(seconds: 3);
}
