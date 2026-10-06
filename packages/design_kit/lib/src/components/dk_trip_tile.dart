import 'package:design_kit/src/format/dk_money.dart';
import 'package:design_kit/src/theme/dk_context.dart';
import 'package:flutter/material.dart';

/// How a trip was paid. Shown as icon + label, never by color alone.
enum DkPaymentKind {
  /// Cash.
  cash,

  /// Card.
  card;

  /// Default Russian label.
  String get label => switch (this) {
    DkPaymentKind.cash => 'Наличные',
    DkPaymentKind.card => 'Карта',
  };

  /// Icon for this payment kind.
  IconData get icon => switch (this) {
    DkPaymentKind.cash => Icons.payments_outlined,
    DkPaymentKind.card => Icons.credit_card,
  };
}

/// One trip in the day's list: time range, payment method and fare.
class DkTripTile extends StatelessWidget {
  /// Creates a trip row.
  ///
  /// [timeRange] is already formatted, e.g. `08:10 – 08:32`.
  const new({
    required this.timeRange,
    required this.amount,
    required this.payment,
    this.details,
    this.onTap,
    super.key,
  });

  /// Formatted start–end time.
  final String timeRange;

  /// Fare in integer tenge.
  final int amount;

  /// Payment method.
  final DkPaymentKind payment;

  /// Optional extra line after the payment label (e.g. `комиссия 360 ₸`).
  final String? details;

  /// Optional tap handler.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final text = context.dkText;
    final spacing = context.dkSpacing;
    final sizes = context.dkSizes;
    final accent = payment == DkPaymentKind.cash
        ? colors.textPrimary
        : colors.accent;
    final secondLine = [payment.label, ?details].join(' · ');

    final row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: sizes.tripTileMinHeight),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.s16,
          vertical: spacing.s12,
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Container(
                width: sizes.tapTargetMin,
                height: sizes.tapTargetMin,
                decoration: BoxDecoration(
                  color: colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(context.dkRadii.md),
                ),
                child: Icon(payment.icon, color: accent, size: sizes.iconNav),
              ),
            ),
            SizedBox(width: spacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeRange,
                    style: text.bodyStrong.copyWith(color: colors.textPrimary),
                  ),
                  Text(
                    secondLine,
                    style: text.label.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            SizedBox(width: spacing.s12),
            Text(
              DkMoney.format(amount),
              style: text.bodyStrong.copyWith(color: colors.textPrimary),
            ),
          ],
        ),
      ),
    );

    return MergeSemantics(
      child: Material(
        type: MaterialType.transparency,
        child: onTap == null ? row : InkWell(onTap: onTap, child: row),
      ),
    );
  }
}
