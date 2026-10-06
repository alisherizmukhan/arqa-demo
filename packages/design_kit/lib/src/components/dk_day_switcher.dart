import 'package:design_kit/src/theme/dk_context.dart';
import 'package:flutter/material.dart';

/// `←  [📅 Сегодня, 6 октября]  →` — step between days or open a date picker.
///
/// The kit only lays out the control; the app formats [label] and shows the
/// picker in [onPick]. A null [onNext]/[onPrevious] disables that arrow.
class DkDaySwitcher extends StatelessWidget {
  /// Creates a day switcher.
  const new({
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
    this.previousTooltip = 'Предыдущий день',
    this.nextTooltip = 'Следующий день',
    this.pickHint = 'Выбрать дату',
    super.key,
  });

  /// The selected day, formatted by the app.
  final String label;

  /// Go one day back; null disables.
  final VoidCallback? onPrevious;

  /// Go one day forward; null disables.
  final VoidCallback? onNext;

  /// Open a date picker.
  final VoidCallback onPick;

  /// Tooltip / accessible name of the back arrow.
  final String previousTooltip;

  /// Tooltip / accessible name of the forward arrow.
  final String nextTooltip;

  /// Accessibility hint of the date button.
  final String pickHint;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final sizes = context.dkSizes;
    final spacing = context.dkSpacing;

    Widget arrow(IconData icon, String tooltip, VoidCallback? onPressed) {
      return IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon),
        iconSize: sizes.iconMd,
        color: colors.textPrimary,
        disabledColor: colors.border,
        constraints: BoxConstraints.tightFor(
          width: sizes.minTouchTarget,
          height: sizes.minTouchTarget,
        ),
      );
    }

    return Row(
      children: [
        arrow(Icons.chevron_left, previousTooltip, onPrevious),
        SizedBox(width: spacing.xs),
        Expanded(
          child: Semantics(
            hint: pickHint,
            child: TextButton(
              onPressed: onPick,
              style: TextButton.styleFrom(
                foregroundColor: colors.textPrimary,
                minimumSize: Size.fromHeight(sizes.minTouchTarget),
                padding: EdgeInsets.symmetric(horizontal: spacing.sm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: sizes.iconSm),
                  SizedBox(width: spacing.xs),
                  Flexible(
                    child: Text(
                      label,
                      style: context.dkText.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: spacing.xs),
        arrow(Icons.chevron_right, nextTooltip, onNext),
      ],
    );
  }
}
