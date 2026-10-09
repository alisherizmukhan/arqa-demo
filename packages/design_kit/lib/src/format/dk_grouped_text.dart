import 'package:design_kit/src/format/dk_money.dart';
import 'package:flutter/material.dart';

/// Visual width of a digit-group gap, as drawn in the mockups.
const double dkGroupGapEm = 0.25;

final Map<(String?, double, FontWeight?), double> _separatorAdvance = {};

/// Advance of one U+202F in [style] (measured once per font/size/weight;
/// it comes from the fallback font, about 0.1 em).
double _measureSeparator(TextStyle style) {
  final size = style.fontSize ?? 14;
  final key = (style.fontFamily, size, style.fontWeight);
  return _separatorAdvance.putIfAbsent(key, () {
    final plain = style.copyWith(letterSpacing: 0);
    final painter = TextPainter(
      text: TextSpan(text: DkMoney.separator, style: plain),
      textDirection: TextDirection.ltr,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  });
}

/// Spans for [text] where every U+202F is widened to ~0.25 em by extra
/// letter-spacing on that character only. The string is unchanged, so copy,
/// semantics and the caret see the real U+202F. Shared by `DkGroupedText`
/// (display) and the money field's controller (editing), so gaps look the
/// same while typing and on screen.
List<InlineSpan> dkGroupedSpans(String text, TextStyle style) {
  if (!text.contains(DkMoney.separator)) return [TextSpan(text: text)];
  final size = style.fontSize ?? 14;
  final base = style.letterSpacing ?? 0;
  final extra = dkGroupGapEm * size - _measureSeparator(style) - base;
  final gapStyle = TextStyle(letterSpacing: base + (extra > 0 ? extra : 0));
  final spans = <InlineSpan>[];
  final parts = text.split(DkMoney.separator);
  for (var i = 0; i < parts.length; i++) {
    if (i > 0) {
      spans.add(TextSpan(text: DkMoney.separator, style: gapStyle));
    }
    if (parts[i].isNotEmpty) spans.add(TextSpan(text: parts[i]));
  }
  return spans;
}

/// Text in which digit-group gaps (U+202F) render at ~0.25 em.
class DkGroupedText extends StatelessWidget {
  /// Creates grouped text. [style] must be a complete style (font size set).
  const new(
    this.text, {
    required this.style,
    this.maxLines,
    this.textAlign,
    this.overflow,
    super.key,
  });

  /// The text, with U+202F separators.
  final String text;

  /// Style of the whole text.
  final TextStyle style;

  /// Optional line limit.
  final int? maxLines;

  /// Optional alignment.
  final TextAlign? textAlign;

  /// Optional overflow (with [maxLines]).
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final effective = DefaultTextStyle.of(context).style.merge(style);
    return Text.rich(
      TextSpan(style: effective, children: dkGroupedSpans(text, effective)),
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: overflow,
    );
  }
}

/// A money amount: `3 315 ₸`, gaps widened like in the mockups.
///
/// With [suffixStyle] the `₸` is its own span in that style (the «На руки»
/// hero: `moneyHero` + `moneyHeroSuffix`, DESIGN.md §3).
class DkMoneyText extends StatelessWidget {
  /// Creates a money text for [amount] in whole tenge.
  const new(
    this.amount, {
    required this.style,
    this.suffixStyle,
    this.negative = false,
    super.key,
  });

  /// Whole tenge.
  final int amount;

  /// Style of the number (and of `₸` unless [suffixStyle] is set).
  final TextStyle style;

  /// Optional separate style for `₸`.
  final TextStyle? suffixStyle;

  /// Show as a deduction with U+2212 (`−585 ₸`).
  final bool negative;

  @override
  Widget build(BuildContext context) {
    final value = negative && amount > 0 ? -amount : amount;
    final number = '${DkMoney.formatNumber(value)}${DkMoney.separator}';
    final base = DefaultTextStyle.of(context).style.merge(style);
    final suffix = suffixStyle == null ? base : base.merge(suffixStyle);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          ...dkGroupedSpans(number, base),
          TextSpan(text: DkMoney.currency, style: suffix),
        ],
      ),
      semanticsLabel: DkMoneySemantics.labelOf(context, value),
    );
  }
}

/// How amounts are spoken: the app puts this above its screens with the
/// active language («3 315 тенге», «3 315 теңге»). Without it a screen
/// reader reads the visible text.
class DkMoneySemantics extends InheritedWidget {
  /// Provides [label] to the [DkMoneyText]s below.
  const new({required this.label, required super.child, super.key});

  /// The spoken amount, from the grouped number (`3 315`, `−585`).
  final String Function(String number) label;

  /// The spoken form of [amount] under [context], or null.
  static String? labelOf(BuildContext context, int amount) => context
      .dependOnInheritedWidgetOfExactType<DkMoneySemantics>()
      ?.label(DkMoney.formatNumber(amount));

  @override
  bool updateShouldNotify(DkMoneySemantics oldWidget) =>
      label != oldWidget.label;
}
