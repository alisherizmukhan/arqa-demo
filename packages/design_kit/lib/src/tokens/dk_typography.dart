import 'dart:ui' show FontVariation, lerpDouble;

import 'package:flutter/material.dart';

/// Font family shipped with the kit (IBM Plex Sans, variable `wght` axis).
///
/// Plex digits are tabular by default, so money figures never change width
/// while they update.
const String dkFontFamily = 'IBMPlexSans';

/// Package that owns [dkFontFamily].
const String dkFontPackage = 'design_kit';

/// Builds a kit text style. Sets both `fontWeight` and the `wght` axis so the
/// variable font renders the real weight instead of a synthetic bold.
TextStyle dkTextStyle({
  required double size,
  required FontWeight weight,
  double height = 1.3,
  double letterSpacing = 0,
}) {
  return TextStyle(
    fontFamily: dkFontFamily,
    package: dkFontPackage,
    fontSize: size,
    fontWeight: weight,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
    height: height,
    letterSpacing: letterSpacing,
  );
}

/// Type scale. Colors are applied by components from `DkColors`.
@immutable
class DkTypography extends ThemeExtension<DkTypography> {
  /// Creates a type scale. Prefer [DkTypography.standard].
  const new({
    required this.moneyHero,
    required this.moneyLarge,
    required this.moneyMedium,
    required this.title,
    required this.titleSmall,
    required this.body,
    required this.bodyStrong,
    required this.label,
  });

  /// The default scale: body 16, nothing below 14, one hero figure.
  static final DkTypography standard = DkTypography(
    moneyHero: dkTextStyle(size: 44, weight: FontWeight.w700, height: 1.1),
    moneyLarge: dkTextStyle(size: 26, weight: FontWeight.w600, height: 1.15),
    moneyMedium: dkTextStyle(size: 20, weight: FontWeight.w600, height: 1.2),
    title: dkTextStyle(size: 20, weight: FontWeight.w600),
    titleSmall: dkTextStyle(size: 17, weight: FontWeight.w600),
    body: dkTextStyle(size: 16, weight: FontWeight.w400, height: 1.5),
    bodyStrong: dkTextStyle(size: 16, weight: FontWeight.w500, height: 1.5),
    label: dkTextStyle(size: 14, weight: FontWeight.w500, height: 1.4),
  );

  /// The one figure a driver reads at a glance (net payout).
  final TextStyle moneyHero;

  /// Secondary totals (revenue, commission, cash/card).
  final TextStyle moneyLarge;

  /// Amounts in lists.
  final TextStyle moneyMedium;

  /// Screen and section titles.
  final TextStyle title;

  /// Card titles, emphasized list text.
  final TextStyle titleSmall;

  /// Running text.
  final TextStyle body;

  /// Emphasized running text, button labels.
  final TextStyle bodyStrong;

  /// Field labels, captions (smallest size in the kit).
  final TextStyle label;

  @override
  DkTypography copyWith({
    TextStyle? moneyHero,
    TextStyle? moneyLarge,
    TextStyle? moneyMedium,
    TextStyle? title,
    TextStyle? titleSmall,
    TextStyle? body,
    TextStyle? bodyStrong,
    TextStyle? label,
  }) {
    return DkTypography(
      moneyHero: moneyHero ?? this.moneyHero,
      moneyLarge: moneyLarge ?? this.moneyLarge,
      moneyMedium: moneyMedium ?? this.moneyMedium,
      title: title ?? this.title,
      titleSmall: titleSmall ?? this.titleSmall,
      body: body ?? this.body,
      bodyStrong: bodyStrong ?? this.bodyStrong,
      label: label ?? this.label,
    );
  }

  @override
  DkTypography lerp(covariant DkTypography? other, double t) {
    if (other == null) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return DkTypography(
      moneyHero: l(moneyHero, other.moneyHero),
      moneyLarge: l(moneyLarge, other.moneyLarge),
      moneyMedium: l(moneyMedium, other.moneyMedium),
      title: l(title, other.title),
      titleSmall: l(titleSmall, other.titleSmall),
      body: l(body, other.body),
      bodyStrong: l(bodyStrong, other.bodyStrong),
      label: l(label, other.label),
    );
  }
}

/// Lerp helper shared by dimension tokens.
double dkLerp(double a, double b, double t) => lerpDouble(a, b, t)!;
