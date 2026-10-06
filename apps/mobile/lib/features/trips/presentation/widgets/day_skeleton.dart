import 'package:design_kit/design_kit.dart';
import 'package:flutter/material.dart';

/// Placeholder in the shape of the Day screen (DESIGN.md §5.3).
class DaySkeleton extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Загрузка',
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: context.dkSpacing.s16,
        children: const [
          DkSkeleton.summaryCard(),
          DkSkeleton.paymentCard(),
          DkTripList(
            children: [
              DkSkeleton.tripTile(),
              DkSkeleton.tripTile(),
              DkSkeleton.tripTile(),
            ],
          ),
        ],
      ),
    );
  }
}
