import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// Placeholder in the shape of the Day screen (DESIGN.md §5.3).
class DaySkeleton extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    return Semantics(
      label: context.l10n.loading,
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing.s16,
        children: [
          const DkSkeleton.summaryCard(),
          const DkSkeleton.paymentCard(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: spacing.s8,
            children: const [
              DkSkeleton.listHeader(),
              DkTripList(
                children: [
                  DkSkeleton.tripTile(),
                  DkSkeleton.tripTile(),
                  DkSkeleton.tripTile(),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
