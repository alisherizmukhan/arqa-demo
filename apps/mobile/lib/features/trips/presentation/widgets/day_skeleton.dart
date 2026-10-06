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
        spacing: spacing.s24,
        children: [
          DkCard(
            padding: EdgeInsets.all(spacing.s24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: spacing.s12,
              children: [
                DkSkeleton(height: spacing.s16, width: spacing.s48 * 2),
                DkSkeleton(height: spacing.s48, width: spacing.s48 * 4),
                SizedBox(height: spacing.s8),
                DkSkeleton(height: spacing.s32),
                DkSkeleton(height: spacing.s32),
              ],
            ),
          ),
          DkCard(
            child: Column(
              spacing: spacing.s16,
              children: [
                for (var i = 0; i < 3; i++)
                  DkSkeleton(height: sizes.tapTargetMin),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
