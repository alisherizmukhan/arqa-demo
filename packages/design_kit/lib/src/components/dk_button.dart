import 'package:design_kit/src/theme/dk_context.dart';
import 'package:flutter/material.dart';

/// Visual weight of a [DkButton]. Use one [primary] button per screen.
enum DkButtonVariant {
  /// Filled, the main action.
  primary,

  /// Outlined, an alternative action.
  secondary,

  /// Text only, a low-emphasis action.
  text,
}

/// Button with a 56dp height, optional leading icon and a loading state.
///
/// While [isLoading] the button keeps its colors, shows a spinner and ignores
/// taps, so a slow request cannot be submitted twice.
class DkButton extends StatelessWidget {
  /// Creates a button. A null [onPressed] disables it.
  const new({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = DkButtonVariant.primary,
    this.isLoading = false,
    this.expand = true,
    super.key,
  });

  /// Visible text and accessible name.
  final String label;

  /// Tap handler; null disables the button.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  /// Visual weight.
  final DkButtonVariant variant;

  /// Shows a spinner and ignores taps.
  final bool isLoading;

  /// Stretch to the available width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final sizes = context.dkSizes;
    final spacing = context.dkSpacing;

    final (background, foreground) = switch (variant) {
      DkButtonVariant.primary => (colors.accent, colors.onAccent),
      DkButtonVariant.secondary => (Colors.transparent, colors.textPrimary),
      DkButtonVariant.text => (Colors.transparent, colors.accent),
    };
    // Loading keeps the enabled look; a real disabled state is muted.
    final disabledBackground = isLoading
        ? background
        : variant == DkButtonVariant.primary
        ? colors.surfaceMuted
        : Colors.transparent;
    final disabledForeground = isLoading ? foreground : colors.textSecondary;

    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(expand ? double.infinity : sizes.tapTargetMin, sizes.buttonHeight),
      ),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: spacing.s24),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.dkRadii.md),
        ),
      ),
      textStyle: WidgetStatePropertyAll(context.dkText.bodyStrong),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? disabledBackground
            : background,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? disabledForeground
            : foreground,
      ),
      side: variant == DkButtonVariant.secondary
          ? WidgetStateProperty.resolveWith(
              (states) => BorderSide(
                color: states.contains(WidgetState.disabled)
                    ? colors.divider
                    : colors.border,
                width: sizes.fieldBorder,
              ),
            )
          : null,
      elevation: const WidgetStatePropertyAll(0),
    );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox.square(
            dimension: sizes.iconField,
            child: CircularProgressIndicator(
              strokeWidth: sizes.fieldBorderFocused,
              color: foreground,
            ),
          )
        else if (icon != null)
          Icon(icon, size: sizes.iconField),
        if (isLoading || icon != null) SizedBox(width: spacing.s8),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );

    final onTap = isLoading ? null : onPressed;
    final button = switch (variant) {
      DkButtonVariant.primary => FilledButton(
        onPressed: onTap,
        style: style,
        child: content,
      ),
      DkButtonVariant.secondary => OutlinedButton(
        onPressed: onTap,
        style: style,
        child: content,
      ),
      DkButtonVariant.text => TextButton(
        onPressed: onTap,
        style: style,
        child: content,
      ),
    };

    // Merge so the busy state is announced with the button's own label.
    return MergeSemantics(
      child: Semantics(value: isLoading ? 'Загрузка' : null, child: button),
    );
  }
}
