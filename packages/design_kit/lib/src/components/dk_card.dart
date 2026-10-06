import 'package:design_kit/src/theme/dk_context.dart';
import 'package:flutter/material.dart';

/// Surface container with the kit's radius, border and padding.
class DkCard extends StatelessWidget {
  /// Creates a card; pass [onTap] to make the whole card tappable.
  const new({required this.child, this.padding, this.onTap, super.key});

  /// Card content.
  final Widget child;

  /// Inner padding; defaults to `spacing.md` on all sides.
  final EdgeInsetsGeometry? padding;

  /// Optional tap handler (adds ink feedback).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final content = Padding(
      padding: padding ?? EdgeInsets.all(context.dkSpacing.md),
      child: child,
    );
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.dkRadii.lg),
        side: BorderSide(
          color: colors.border,
          width: context.dkSizes.borderWidth,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}
