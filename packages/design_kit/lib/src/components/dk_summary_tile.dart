import 'package:design_kit/src/format/dk_money.dart';
import 'package:design_kit/src/theme/dk_context.dart';
import 'package:design_kit/src/tokens/dk_colors.dart';
import 'package:flutter/material.dart';

/// Meaning of a figure; drives the icon/figure color. Never the only signal:
/// every tile also has a text label.
enum DkTone {
  /// Plain figure.
  neutral,

  /// Earnings (net payout).
  positive,

  /// Paid in cash.
  cash,

  /// Paid by card.
  card,
}

/// Size of a summary figure.
enum DkSummaryEmphasis {
  /// The one figure read at a glance (e.g. net payout).
  hero,

  /// Supporting totals.
  regular,
}

/// A labelled figure from the daily summary: money or a count.
///
/// Money is passed as integer tenge and always formatted as `3 315 ₸`; a long
/// figure scales down rather than wrapping or being cut off.
class DkSummaryTile extends StatelessWidget {
  /// A money figure. [isDeduction] renders it with a minus sign (commission).
  const new money({
    required this.label,
    required int this._amount,
    this.icon,
    this.tone = DkTone.neutral,
    this.emphasis = DkSummaryEmphasis.regular,
    this.isDeduction = false,
    super.key,
  }) : _count = null;

  /// A plain count (e.g. number of trips).
  const new count({
    required this.label,
    required int this._count,
    this.icon,
    this.emphasis = DkSummaryEmphasis.regular,
    super.key,
  }) : _amount = null,
       tone = DkTone.neutral,
       isDeduction = false;

  /// Caption above the figure.
  final String label;

  /// Optional icon next to the caption.
  final IconData? icon;

  /// Meaning of the figure.
  final DkTone tone;

  /// Figure size.
  final DkSummaryEmphasis emphasis;

  /// Show the amount as a deduction (`−585 ₸`).
  final bool isDeduction;

  final int? _amount;
  final int? _count;

  /// The figure exactly as displayed.
  String get displayValue {
    final amount = _amount;
    if (amount == null) return '${_count!}';
    return DkMoney.format(isDeduction && amount > 0 ? -amount : amount);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final text = context.dkText;
    final accent = _accent(colors);
    final figureStyle =
        (emphasis == DkSummaryEmphasis.hero ? text.moneyHero : text.moneyM)
            .copyWith(
              color: tone == DkTone.positive
                  ? colors.accent
                  : colors.textPrimary,
            );

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                ExcludeSemantics(
                  child: Icon(
                    icon,
                    size: context.dkSizes.iconField,
                    color: accent,
                  ),
                ),
                SizedBox(width: context.dkSpacing.s4),
              ],
              Flexible(
                child: Text(
                  label,
                  style: text.label.copyWith(color: colors.textSecondary),
                ),
              ),
            ],
          ),
          SizedBox(height: context.dkSpacing.s4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(displayValue, style: figureStyle, maxLines: 1),
          ),
        ],
      ),
    );
  }

  Color _accent(DkColors colors) => switch (tone) {
    DkTone.neutral => colors.textSecondary,
    DkTone.positive => colors.accent,
    DkTone.cash => colors.textPrimary,
    DkTone.card => colors.accent,
  };
}
