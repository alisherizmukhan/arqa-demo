import 'package:design_kit/design_kit.dart';
import 'package:flutter/material.dart';

/// Placeholder in the shape of the summary card and the trip list.
class DaySkeleton extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    final sizes = context.dkSizes;
    return Semantics(
      label: 'Загрузка',
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing.lg,
        children: [
          DkCard(
            padding: EdgeInsets.all(spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: spacing.sm,
              children: [
                DkSkeleton(height: spacing.md, width: spacing.xxl * 2),
                DkSkeleton(height: spacing.xxl, width: spacing.xxl * 4),
                SizedBox(height: spacing.xs),
                DkSkeleton(height: spacing.xl),
                DkSkeleton(height: spacing.xl),
              ],
            ),
          ),
          DkCard(
            child: Column(
              spacing: spacing.md,
              children: [
                for (var i = 0; i < 3; i++)
                  DkSkeleton(height: sizes.minTouchTarget),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
