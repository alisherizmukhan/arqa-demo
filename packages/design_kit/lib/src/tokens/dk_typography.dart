import 'dart:ui' show FontFeature, FontVariation, lerpDouble;

import 'package:flutter/material.dart';

/// Main font (DESIGN.md §2.2), bundled as static 500/600/700/800 instances.
const String dkFontFamily = 'Manrope';

/// Glyph fallback for the two characters Manrope lacks: `₸` (U+20B8) and the
/// narrow no-break space (U+202F). Bundled, so it never depends on the device.
const String dkFallbackFontFamily = 'IBMPlexSans';

/// Package that owns both fonts.
const String dkFontPackage = 'design_kit';

/// Builds a kit text style: Manrope, tabular figures, `height` from the line
/// height. `fontVariations` sets the weight of the (variable) fallback font so
/// a fallback `₸` matches the weight of the surrounding text.
TextStyle dkTextStyle({
  required double size,
  required double lineHeight,
  required FontWeight weight,
  double letterSpacing = 0,
}) {
  return TextStyle(
    fontFamily: dkFontFamily,
    package: dkFontPackage,
    fontFamilyFallback: const [dkFallbackFontFamily],
    fontSize: size,
    height: lineHeight / size,
    fontWeight: weight,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
    letterSpacing: letterSpacing,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

/// Type scale, DESIGN.md §2.2. Colors are applied by components.
@immutable
class DkTypography extends ThemeExtension<DkTypography> {
  /// Creates a type scale. Prefer [DkTypography.standard].
  const new({
    required this.moneyHero,
    required this.moneyHeroSuffix,
    required this.titleL,
    required this.moneyL,
    required this.wordmark,
    required this.titleDialog,
    required this.fieldTime,
    required this.titleM,
    required this.moneyM,
    required this.bodyStrong,
    required this.body,
    required this.bodyMd,
    required this.bodyS,
    required this.label,
    required this.captionStrong,
    required this.caption,
    required this.badge,
    required this.superscript,
  });

  /// The scale from DESIGN.md §2.2 (−0.02em at 44 px = −0.88 px, etc.).
  static final DkTypography standard = DkTypography(
    moneyHero: dkTextStyle(
      size: 44,
      lineHeight: 48,
      weight: FontWeight.w800,
      letterSpacing: -0.88,
    ),
    moneyHeroSuffix: dkTextStyle(
      size: 32,
      lineHeight: 48,
      weight: FontWeight.w700,
      letterSpacing: -0.64,
    ),
    titleL: dkTextStyle(
      size: 22,
      lineHeight: 28,
      weight: FontWeight.w800,
      letterSpacing: -0.22,
    ),
    moneyL: dkTextStyle(size: 22, lineHeight: 28, weight: FontWeight.w700),
    wordmark: dkTextStyle(
      size: 20,
      lineHeight: 28,
      weight: FontWeight.w800,
      letterSpacing: -0.4,
    ),
    titleDialog: dkTextStyle(
      size: 20,
      lineHeight: 28,
      weight: FontWeight.w800,
      letterSpacing: -0.2,
    ),
    fieldTime: dkTextStyle(size: 18, lineHeight: 24, weight: FontWeight.w700),
    titleM: dkTextStyle(size: 17, lineHeight: 24, weight: FontWeight.w700),
    moneyM: dkTextStyle(size: 17, lineHeight: 24, weight: FontWeight.w700),
    bodyStrong: dkTextStyle(size: 16, lineHeight: 24, weight: FontWeight.w700),
    body: dkTextStyle(size: 16, lineHeight: 24, weight: FontWeight.w500),
    bodyMd: dkTextStyle(size: 15, lineHeight: 22, weight: FontWeight.w500),
    bodyS: dkTextStyle(size: 14, lineHeight: 20, weight: FontWeight.w500),
    label: dkTextStyle(size: 14, lineHeight: 20, weight: FontWeight.w600),
    captionStrong: dkTextStyle(
      size: 13,
      lineHeight: 16,
      weight: FontWeight.w600,
    ),
    caption: dkTextStyle(size: 13, lineHeight: 16, weight: FontWeight.w500),
    badge: dkTextStyle(size: 12, lineHeight: 24, weight: FontWeight.w700),
    superscript: dkTextStyle(size: 11, lineHeight: 14, weight: FontWeight.w800),
  );

  /// «На руки» amount (color accent). 44/48 · 800 · −0.88.
  final TextStyle moneyHero;

  /// «₸» after the hero amount. 32/48 · 700 · −0.64.
  final TextStyle moneyHeroSuffix;

  /// Empty/Error state title. 22/28 · 800 · −0.22.
  final TextStyle titleL;

  /// Amount/commission inside text fields. 22/28 · 700.
  final TextStyle moneyL;

  /// «Дневник смен». 20/28 · 800 · −0.4.
  final TextStyle wordmark;

  /// Dialog title. 20/28 · 800 · −0.2.
  final TextStyle titleDialog;

  /// Time inside time fields. 18/24 · 700.
  final TextStyle fieldTime;

  /// Day label, section title «Поездки», form app-bar title. 17/24 · 700.
  final TextStyle titleM;

  /// Summary metric values, payment tile values. 17/24 · 700.
  final TextStyle moneyM;

  /// Trip time range, trip amount, button labels. 16/24 · 700.
  final TextStyle bodyStrong;

  /// Empty/Error message. 16/24 · 500.
  final TextStyle body;

  /// Dialog message. 15/22 · 500.
  final TextStyle bodyMd;

  /// Trip meta («22 мин · Карта»), snackbar text. 14/20 · 500.
  final TextStyle bodyS;

  /// Field labels, «На руки» label. 14/20 · 600.
  final TextStyle label;

  /// Metric labels, error text, list header count. 13/16 · 600.
  final TextStyle captionStrong;

  /// Helpers, «комиссия 360 ₸», weekday, app-bar subtitle. 13/16 · 500.
  final TextStyle caption;

  /// «+1 день» badge. 12/24 · 700.
  final TextStyle badge;

  /// «+1» after the end time in a trip row (color accent). 11/14 · 800.
  final TextStyle superscript;

  /// Every style, for tests and the showcase.
  Map<String, TextStyle> get all => {
    'moneyHero': moneyHero,
    'moneyHeroSuffix': moneyHeroSuffix,
    'titleL': titleL,
    'moneyL': moneyL,
    'wordmark': wordmark,
    'titleDialog': titleDialog,
    'fieldTime': fieldTime,
    'titleM': titleM,
    'moneyM': moneyM,
    'bodyStrong': bodyStrong,
    'body': body,
    'bodyMd': bodyMd,
    'bodyS': bodyS,
    'label': label,
    'captionStrong': captionStrong,
    'caption': caption,
    'badge': badge,
    'superscript': superscript,
  };

  @override
  DkTypography copyWith({
    TextStyle? moneyHero,
    TextStyle? moneyHeroSuffix,
    TextStyle? titleL,
    TextStyle? moneyL,
    TextStyle? wordmark,
    TextStyle? titleDialog,
    TextStyle? fieldTime,
    TextStyle? titleM,
    TextStyle? moneyM,
    TextStyle? bodyStrong,
    TextStyle? body,
    TextStyle? bodyMd,
    TextStyle? bodyS,
    TextStyle? label,
    TextStyle? captionStrong,
    TextStyle? caption,
    TextStyle? badge,
    TextStyle? superscript,
  }) {
    return DkTypography(
      moneyHero: moneyHero ?? this.moneyHero,
      moneyHeroSuffix: moneyHeroSuffix ?? this.moneyHeroSuffix,
      titleL: titleL ?? this.titleL,
      moneyL: moneyL ?? this.moneyL,
      wordmark: wordmark ?? this.wordmark,
      titleDialog: titleDialog ?? this.titleDialog,
      fieldTime: fieldTime ?? this.fieldTime,
      titleM: titleM ?? this.titleM,
      moneyM: moneyM ?? this.moneyM,
      bodyStrong: bodyStrong ?? this.bodyStrong,
      body: body ?? this.body,
      bodyMd: bodyMd ?? this.bodyMd,
      bodyS: bodyS ?? this.bodyS,
      label: label ?? this.label,
      captionStrong: captionStrong ?? this.captionStrong,
      caption: caption ?? this.caption,
      badge: badge ?? this.badge,
      superscript: superscript ?? this.superscript,
    );
  }

  @override
  DkTypography lerp(covariant DkTypography? other, double t) {
    if (other == null) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return DkTypography(
      moneyHero: l(moneyHero, other.moneyHero),
      moneyHeroSuffix: l(moneyHeroSuffix, other.moneyHeroSuffix),
      titleL: l(titleL, other.titleL),
      moneyL: l(moneyL, other.moneyL),
      wordmark: l(wordmark, other.wordmark),
      titleDialog: l(titleDialog, other.titleDialog),
      fieldTime: l(fieldTime, other.fieldTime),
      titleM: l(titleM, other.titleM),
      moneyM: l(moneyM, other.moneyM),
      bodyStrong: l(bodyStrong, other.bodyStrong),
      body: l(body, other.body),
      bodyMd: l(bodyMd, other.bodyMd),
      bodyS: l(bodyS, other.bodyS),
      label: l(label, other.label),
      captionStrong: l(captionStrong, other.captionStrong),
      caption: l(caption, other.caption),
      badge: l(badge, other.badge),
      superscript: l(superscript, other.superscript),
    );
  }
}

/// Lerp helper shared by dimension tokens.
double dkLerp(double a, double b, double t) => lerpDouble(a, b, t)!;
