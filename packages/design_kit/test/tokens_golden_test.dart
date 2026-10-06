import 'package:alchemist/alchemist.dart';
import 'package:design_kit/design_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

/// Money as the app shows it: Manrope digits, `₸` (U+20B8) and the narrow
/// no-break space (U+202F) from the bundled IBM Plex Sans fallback.
class _MoneySamples extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final text = context.dkText;
    final colors = context.dkColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: context.dkSpacing.s12,
      children: [
        Text(
          'На руки',
          style: text.label.copyWith(color: colors.textSecondary),
        ),
        DkMoneyText(
          3315,
          style: text.moneyHero.copyWith(color: colors.accent),
          suffixStyle: text.moneyHeroSuffix.copyWith(color: colors.accent),
        ),
        Row(
          spacing: context.dkSpacing.s16,
          children: [
            DkMoneyText(
              3900,
              style: text.moneyM.copyWith(color: colors.textPrimary),
            ),
            DkMoneyText(
              585,
              negative: true,
              style: text.moneyM.copyWith(color: colors.textPrimary),
            ),
          ],
        ),
        DkGroupedText(
          'комиссия 360 ₸',
          style: text.caption.copyWith(color: colors.textTertiary),
        ),
      ],
    );
  }
}

class _TypeScale extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: context.dkSpacing.s8,
      children: [
        for (final MapEntry(key: name, value: style)
            in context.dkText.all.entries)
          Text(
            '$name 0123456789 Поездка ₸',
            style: style.copyWith(
              color: name == 'moneyHero' || name == 'superscript'
                  ? colors.accent
                  : colors.textPrimary,
            ),
          ),
      ],
    );
  }
}

void main() {
  setUpAll(loadKitFonts);

  // goldenTest registers tests and returns a Future that need not be awaited.
  // ignore_for_file: discarded_futures

  goldenTest(
    'money renders with Manrope digits and the ₸ / U+202F fallback',
    fileName: 'money_fallback',
    builder: () => GoldenTestGroup(
      columns: 2,
      children: [
        GoldenTestScenario(
          name: 'light',
          child: themed(DkTheme.light(), const _MoneySamples()),
        ),
        GoldenTestScenario(
          name: 'dark',
          child: themed(DkTheme.dark(), const _MoneySamples()),
        ),
      ],
    ),
  );

  goldenTest(
    'type scale (DESIGN.md §2.2), tabular figures',
    fileName: 'typography',
    builder: () => GoldenTestGroup(
      columns: 2,
      children: [
        GoldenTestScenario(
          name: 'light',
          child: themed(DkTheme.light(), const _TypeScale()),
        ),
        GoldenTestScenario(
          name: 'dark',
          child: themed(DkTheme.dark(), const _TypeScale()),
        ),
      ],
    ),
  );
}
