import 'package:design_kit/src/theme/dk_context.dart';
import 'package:flutter/material.dart';

/// Visual weight of a [DkButton].
enum DkButtonVariant {
  /// Accent fill: the main action.
  primary,

  /// Accent-soft fill: an alternative action.
  secondary,

  /// Text only, 48 high.
  text,
}

/// Button, DESIGN.md §4. Min height 56 (text: 48); grows with text scale.
///
/// `onPressed == null` → disabled (`disabledFill` / `textDisabled`).
/// [isLoading] → spinner + [label] (pass e.g. «Сохраняем…»), not tappable.
class DkButton extends StatelessWidget {
  /// Creates a button.
  const new({
    required this.label,
    this.onPressed,
    this.variant = DkButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.expand = false,
    super.key,
  });

  /// Visible text and accessible name.
  final String label;

  /// Tap handler; null disables the button.
  final VoidCallback? onPressed;

  /// Visual weight.
  final DkButtonVariant variant;

  /// Shows a spinner and ignores taps.
  final bool isLoading;

  /// Optional leading icon (22).
  final IconData? icon;

  /// Stretch to the available width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final sizes = context.dkSizes;
    final spacing = context.dkSpacing;
    final radii = context.dkRadii;
    final isText = variant == DkButtonVariant.text;
    final disabled = onPressed == null && !isLoading;

    final (background, foreground) = switch (variant) {
      _ when disabled && isText => (Colors.transparent, colors.textDisabled),
      _ when disabled => (colors.disabledFill, colors.textDisabled),
      DkButtonVariant.primary => (colors.accent, colors.onAccent),
      DkButtonVariant.secondary => (colors.accentSoft, colors.accent),
      DkButtonVariant.text => (Colors.transparent, colors.accent),
    };
    final radius = BorderRadius.circular(isText ? radii.md : radii.lg);
    final leading = isLoading || icon != null;
    final labelStyle = context.dkText.bodyStrong;
    final minHeight = isText ? sizes.textButtonHeight : sizes.buttonHeight;
    // The spec's height is one label line plus equal insets (56 = 24 + 2·16;
    // text: 48 = 24 + 2·12). Keeping those insets means a label that grows
    // (text scale, a narrow dialog) never touches the button's edges.
    final verticalInset =
        (minHeight - labelStyle.fontSize! * labelStyle.height!) / 2;

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox.square(
            dimension: sizes.iconField,
            child: CircularProgressIndicator(
              strokeWidth: sizes.spinnerStroke,
              color: foreground,
            ),
          ),
          SizedBox(width: spacing.s10),
        ] else if (icon != null) ...[
          Icon(icon, size: sizes.iconAction, color: foreground),
          SizedBox(width: spacing.s8),
        ],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: labelStyle.copyWith(color: foreground),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: !disabled && !isLoading,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: background,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: disabled || isLoading ? null : onPressed,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: minHeight,
              minWidth: expand ? double.infinity : sizes.tapTargetMin,
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                // 20 on the icon side, 24 otherwise (DESIGN.md §4).
                start: leading ? spacing.s20 : spacing.s24,
                end: spacing.s24,
                top: verticalInset,
                bottom: verticalInset,
              ),
              // Both factors: without heightFactor a Center fills all the
              // height it is offered (e.g. a Scaffold bottom bar).
              child: Center(widthFactor: 1, heightFactor: 1, child: content),
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating action button «+ Поездка», DESIGN.md §4: pill, min 56, `e2Fab`
/// shadow (none in dark). Place it with `Scaffold.floatingActionButton`
/// (right 16, bottom safe area + 16).
class DkFab extends StatelessWidget {
  /// Creates the FAB.
  const new({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  /// Visible text and accessible name.
  final String label;

  /// Leading icon (22).
  final IconData icon;

  /// Tap handler.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final spacing = context.dkSpacing;
    final shape = BorderRadius.circular(context.dkRadii.pill);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: shape,
          boxShadow: context.dkElevation.e2Fab,
        ),
        child: Material(
          color: colors.accent,
          borderRadius: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: context.dkSizes.buttonHeight,
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: spacing.s20,
                  end: spacing.s24,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: context.dkSizes.iconAction,
                      color: colors.onAccent,
                    ),
                    SizedBox(width: spacing.s8),
                    Text(
                      label,
                      style: context.dkText.bodyStrong.copyWith(
                        color: colors.onAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
