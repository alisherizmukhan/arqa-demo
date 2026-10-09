import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/l10n/l10n.dart';
import 'package:driver_diary/features/trips/domain/entities/daily_summary.dart';
import 'package:flutter/material.dart';

/// The day's totals and the cash/card split.
class SummaryCard extends StatelessWidget {
  const new({required this.summary, super.key});

  final DailySummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: context.dkSpacing.s16,
      children: [
        DkSummaryCard(
          net: summary.net,
          revenue: summary.revenue,
          commission: summary.commission,
          tripsCount: summary.tripsCount,
          netLabel: l10n.summaryNet,
          revenueLabel: l10n.summaryRevenue,
          commissionLabel: l10n.summaryCommission,
          tripsLabel: l10n.summaryTrips,
        ),
        DkPaymentCard(
          cash: summary.cash,
          card: summary.card,
          cashLabel: l10n.cash,
          cardLabel: l10n.card,
        ),
      ],
    );
  }
}
