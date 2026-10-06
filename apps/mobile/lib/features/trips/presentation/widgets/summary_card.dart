import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/features/trips/domain/entities/daily_summary.dart';
import 'package:flutter/material.dart';

/// The day's totals; net payout is the hero figure.
class SummaryCard extends StatelessWidget {
  const new({required this.summary, super.key});

  final DailySummary summary;

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    return DkCard(
      padding: EdgeInsets.all(spacing.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing.s24,
        children: [
          DkSummaryTile.money(
            label: 'Чистыми',
            amount: summary.net,
            icon: Icons.account_balance_wallet_outlined,
            tone: DkTone.positive,
            emphasis: DkSummaryEmphasis.hero,
          ),
          _Pair(
            left: DkSummaryTile.money(
              label: 'Выручка',
              amount: summary.revenue,
            ),
            right: DkSummaryTile.money(
              label: 'Комиссия',
              amount: summary.commission,
              isDeduction: true,
            ),
          ),
          _Pair(
            left: DkSummaryTile.money(
              label: 'Наличные',
              amount: summary.cash,
              icon: DkPaymentKind.cash.icon,
              tone: DkTone.cash,
            ),
            right: DkSummaryTile.money(
              label: 'Карта',
              amount: summary.card,
              icon: DkPaymentKind.card.icon,
              tone: DkTone.card,
            ),
          ),
          DkSummaryTile.count(
            label: 'Поездок',
            count: summary.tripsCount,
            icon: Icons.local_taxi_outlined,
          ),
        ],
      ),
    );
  }
}

class _Pair extends StatelessWidget {
  const new({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: context.dkSpacing.s16,
      children: [
        Expanded(child: left),
        Expanded(child: right),
      ],
    );
  }
}
