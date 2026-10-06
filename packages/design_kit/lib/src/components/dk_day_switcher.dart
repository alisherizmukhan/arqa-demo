import 'package:design_kit/src/format/dk_format.dart';
import 'package:design_kit/src/theme/dk_context.dart';
import 'package:design_kit/src/tokens/dk_icons.dart';
import 'package:flutter/material.dart';

/// Day switcher, DESIGN.md §4: ‹ «1 октября 2026 ⌄ / Четверг» ›.
///
/// Titles follow §3 (Сегодня / Вчера / date). Next is disabled when [date]
/// is [today] (or later) or [onNext] is null. Only y/m/d of the dates matter.
class DkDaySwitcher extends StatelessWidget {
  /// Creates a day switcher.
  const new({
    required this.date,
    required this.today,
    required this.onPrev,
    required this.onPickDate,
    this.onNext,
    this.prevLabel = 'Предыдущий день',
    this.nextLabel = 'Следующий день',
    this.pickLabel = 'Выбрать дату',
    super.key,
  });

  /// The shown day.
  final DateTime date;

  /// Today (the driver's).
  final DateTime today;

  /// One day back.
  final VoidCallback onPrev;

  /// One day forward.
  final VoidCallback? onNext;

  /// Opens the date picker.
  final VoidCallback onPickDate;

  /// «Предыдущий день».
  final String prevLabel;

  /// «Следующий день».
  final String nextLabel;

  /// «Выбрать дату» (the date is appended).
  final String pickLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final text = context.dkText;
    final sizes = context.dkSizes;
    final spacing = context.dkSpacing;
    final label = DkFormat.relativeDay(date, today);
    final isToday = !DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).isBefore(DateTime.utc(today.year, today.month, today.day));
    final next = isToday ? null : onNext;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.dkRadii.lg),
        boxShadow: context.dkElevation.e1,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: sizes.daySwitcherHeight),
        child: Padding(
          padding: EdgeInsets.all(spacing.s4),
          child: Row(
            children: [
              _ArrowButton(
                icon: DkIcons.previous,
                label: prevLabel,
                onPressed: onPrev,
              ),
              Expanded(
                child: Semantics(
                  button: true,
                  label: '$pickLabel, ${DkFormat.date(date)}',
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: onPickDate,
                    borderRadius: BorderRadius.circular(context.dkRadii.md),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: sizes.tapTargetMin,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: spacing.s4,
                            children: [
                              Flexible(
                                child: Text(
                                  label.title,
                                  textAlign: TextAlign.center,
                                  style: text.titleM.copyWith(
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                              Icon(
                                DkIcons.chevronDown,
                                size: sizes.iconInline,
                                color: colors.textTertiary,
                              ),
                            ],
                          ),
                          Text(
                            label.subtitle,
                            textAlign: TextAlign.center,
                            style: text.caption.copyWith(
                              color: colors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _ArrowButton(
                icon: DkIcons.next,
                label: nextLabel,
                onPressed: next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const new({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final sizes = context.dkSizes;
    final colors = context.dkColors;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: sizes.tapTargetMin,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(context.dkRadii.md),
          child: Icon(
            icon,
            size: sizes.iconNav,
            color: onPressed == null ? colors.iconDisabled : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
