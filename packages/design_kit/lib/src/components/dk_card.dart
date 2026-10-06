import 'package:design_kit/src/format/dk_format.dart';
import 'package:design_kit/src/format/dk_grouped_text.dart';
import 'package:design_kit/src/format/dk_money.dart';
import 'package:design_kit/src/theme/dk_context.dart';
import 'package:design_kit/src/tokens/dk_icons.dart';
import 'package:flutter/material.dart';

/// Surface card, DESIGN.md §4: `surface`, shadow `e1` (`e1Hero` when [hero]),
/// no shadow in dark.
class DkCard extends StatelessWidget {
  /// Creates a card. Padding defaults to 16, radius to `lg`.
  const new({
    required this.child,
    this.padding,
    this.radius,
    this.hero = false,
    super.key,
  });

  /// Content.
  final Widget child;

  /// Inner padding (default 16).
  final EdgeInsetsGeometry? padding;

  /// Corner radius (default `lg`).
  final double? radius;

  /// Use the stronger `e1Hero` shadow (summary card).
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius ?? context.dkRadii.lg);
    final elevation = context.dkElevation;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.dkColors.surface,
        borderRadius: borderRadius,
        boxShadow: hero ? elevation.e1Hero : elevation.e1,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Padding(
          padding: padding ?? EdgeInsets.all(context.dkSpacing.s16),
          child: child,
        ),
      ),
    );
  }
}

/// A labelled figure, DESIGN.md §4. Without [icon]: label over value. With
/// [icon]: the payment tile (icon tile 40 + «Наличные · 38%» over value).
class DkSummaryTile extends StatelessWidget {
  /// Creates a tile. [value] may contain U+202F (rendered as a wide gap).
  const new({
    required this.label,
    required this.value,
    this.icon,
    this.hint,
    super.key,
  });

  /// Caption, e.g. «Выручка».
  final String label;

  /// Formatted value, e.g. `3 900 ₸`.
  final String value;

  /// Payment icon (makes this a payment tile).
  final IconData? icon;

  /// Appended to the label as « · hint», e.g. `38%`.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final text = context.dkText;
    final caption = hint == null ? label : '$label · $hint';
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: context.dkSpacing.s2,
      children: [
        Text(
          caption,
          style: text.captionStrong.copyWith(color: colors.textTertiary),
        ),
        DkGroupedText(
          value,
          style: text.moneyM.copyWith(color: colors.textPrimary),
        ),
      ],
    );
    final iconData = icon;
    if (iconData == null) return MergeSemantics(child: column);
    return MergeSemantics(
      child: Row(
        children: [
          DkIconTile(icon: iconData),
          SizedBox(width: context.dkSpacing.s12),
          Expanded(child: column),
        ],
      ),
    );
  }
}

/// 40×40 icon tile (`surfaceMuted`, radius md, icon 22), DESIGN.md §2.6.
class DkIconTile extends StatelessWidget {
  /// Creates an icon tile. [background] overrides `surfaceMuted`.
  const new({required this.icon, this.background, super.key});

  /// The icon.
  final IconData icon;

  /// Tile color (default `surfaceMuted`).
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final sizes = context.dkSizes;
    return ExcludeSemantics(
      child: Container(
        width: sizes.iconTile,
        height: sizes.iconTile,
        decoration: BoxDecoration(
          color: background ?? context.dkColors.surfaceMuted,
          borderRadius: BorderRadius.circular(context.dkRadii.md),
        ),
        child: Icon(
          icon,
          size: sizes.iconTileIcon,
          color: context.dkColors.textPrimary,
        ),
      ),
    );
  }
}

/// The day's totals, DESIGN.md §4: «На руки» hero, divider, then
/// Выручка / Комиссия / Поездок. Amounts in whole tenge.
class DkSummaryCard extends StatelessWidget {
  /// Creates the summary card.
  const new({
    required this.net,
    required this.revenue,
    required this.commission,
    required this.tripsCount,
    this.netLabel = 'На руки',
    this.revenueLabel = 'Выручка',
    this.commissionLabel = 'Комиссия',
    this.tripsLabel = 'Поездок',
    super.key,
  });

  /// Net payout (hero).
  final int net;

  /// Revenue.
  final int revenue;

  /// Commission (shown as `−585 ₸`).
  final int commission;

  /// Number of trips.
  final int tripsCount;

  /// «На руки».
  final String netLabel;

  /// «Выручка».
  final String revenueLabel;

  /// «Комиссия».
  final String commissionLabel;

  /// «Поездок».
  final String tripsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final text = context.dkText;
    final spacing = context.dkSpacing;
    return DkCard(
      hero: true,
      radius: context.dkRadii.xl,
      padding: EdgeInsets.all(spacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing.s16,
        children: [
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: spacing.s4,
              children: [
                Text(
                  netLabel,
                  style: text.label.copyWith(color: colors.textSecondary),
                ),
                DkMoneyText(
                  net,
                  style: text.moneyHero.copyWith(color: colors.accent),
                  suffixStyle: text.moneyHeroSuffix.copyWith(
                    color: colors.accent,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: context.dkSizes.fieldBorder),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: spacing.s12,
            children: [
              Expanded(
                child: DkSummaryTile(
                  label: revenueLabel,
                  value: DkMoney.format(revenue),
                ),
              ),
              Expanded(
                child: DkSummaryTile(
                  label: commissionLabel,
                  value: DkMoney.format(-commission),
                ),
              ),
              Expanded(
                child: DkSummaryTile(label: tripsLabel, value: '$tripsCount'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Cash/card split bar, DESIGN.md §4: height 8, gap 3, cash `splitNeutral`
/// (left), card `accent` (right), flex = amounts. Empty when both are 0.
class DkSplitBar extends StatelessWidget {
  /// Creates the bar.
  const new({
    required this.cash,
    required this.card,
    this.cashLabel = 'Наличные',
    this.cardLabel = 'карта',
    super.key,
  });

  /// Cash amount.
  final int cash;

  /// Card amount.
  final int card;

  /// Semantics name of the cash part.
  final String cashLabel;

  /// Semantics name of the card part (lower case, mid-sentence).
  final String cardLabel;

  @override
  Widget build(BuildContext context) {
    final percent = DkFormat.splitPercent(cash, card);
    if (percent == null) return const SizedBox.shrink();
    final sizes = context.dkSizes;
    final radius = BorderRadius.circular(context.dkRadii.xs);
    Widget segment(int flex, Color color) => Expanded(
      flex: flex,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, borderRadius: radius),
      ),
    );
    return Semantics(
      label: '$cashLabel ${percent.cash}%, $cardLabel ${percent.card}%',
      excludeSemantics: true,
      child: SizedBox(
        height: sizes.splitBarHeight,
        child: Row(
          spacing: cash > 0 && card > 0 ? sizes.splitBarGap : 0,
          children: [
            if (cash > 0) segment(cash, context.dkColors.splitNeutral),
            if (card > 0) segment(card, context.dkColors.accent),
          ],
        ),
      ),
    );
  }
}

/// Payment card, DESIGN.md §4: two payment tiles (with share) + split bar.
class DkPaymentCard extends StatelessWidget {
  /// Creates the payment card. Amounts in whole tenge.
  const new({
    required this.cash,
    required this.card,
    this.cashLabel = 'Наличные',
    this.cardLabel = 'Карта',
    super.key,
  });

  /// Cash revenue.
  final int cash;

  /// Card revenue.
  final int card;

  /// «Наличные».
  final String cashLabel;

  /// «Карта».
  final String cardLabel;

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    final percent = DkFormat.splitPercent(cash, card);
    return DkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing.s14,
        children: [
          Row(
            spacing: spacing.s12,
            children: [
              Expanded(
                child: DkSummaryTile(
                  label: cashLabel,
                  hint: percent == null ? null : '${percent.cash}%',
                  value: DkMoney.format(cash),
                  icon: DkIcons.cash,
                ),
              ),
              Expanded(
                child: DkSummaryTile(
                  label: cardLabel,
                  hint: percent == null ? null : '${percent.card}%',
                  value: DkMoney.format(card),
                  icon: DkIcons.card,
                ),
              ),
            ],
          ),
          if (percent != null)
            DkSplitBar(
              cash: cash,
              card: card,
              cashLabel: cashLabel,
              cardLabel: cardLabel.toLowerCase(),
            ),
        ],
      ),
    );
  }
}
