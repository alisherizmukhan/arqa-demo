import 'package:design_kit/src/format/dk_fit_text.dart';
import 'package:design_kit/src/theme/dk_context.dart';
import 'package:design_kit/src/tokens/dk_icons.dart';
import 'package:flutter/material.dart';

/// Day switcher, DESIGN.md §4: ‹ «1 октября 2026 ⌄ / Четверг» ›.
///
/// The caller formats [title] and [subtitle] (§3: Сегодня / Вчера / date,
/// in the active language). Next is disabled when [onNext] is null (today).
class DkDaySwitcher extends StatelessWidget {
  /// Creates a day switcher.
  const new({
    required this.title,
    required this.subtitle,
    required this.onPrev,
    required this.onPickDate,
    required this.prevLabel,
    required this.nextLabel,
    required this.pickLabel,
    this.onNext,
    super.key,
  });

  /// «Сегодня», «Вчера» or the date.
  final String title;

  /// The date, or the weekday.
  final String subtitle;

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

  /// Spoken name of the middle button, e.g. «Выбрать дату, 1 октября 2026».
  final String pickLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final text = context.dkText;
    final sizes = context.dkSizes;
    final spacing = context.dkSpacing;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.dkRadii.lg),
        boxShadow: context.dkElevation.e1,
      ),
      child: ConstrainedBox(
        // Fixed (DESIGN.md §10): title and subtitle scale together to fit.
        constraints: BoxConstraints.tightFor(height: sizes.daySwitcherHeight),
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
                  label: pickLabel,
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: onPickDate,
                    borderRadius: BorderRadius.circular(context.dkRadii.md),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: sizes.tapTargetMin,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: spacing.s4),
                        // The chevron sits on the title line (DESIGN.md §4);
                        // both lines scale together to fit the 56 (§10).
                        child: Center(
                          child: DkFitLines(
                            textAlign: TextAlign.center,
                            tooltip: false,
                            [
                              DkLine(
                                title,
                                style: text.titleM.copyWith(
                                  color: colors.textPrimary,
                                ),
                                trailing: Padding(
                                  padding: EdgeInsetsDirectional.only(
                                    start: spacing.s4,
                                  ),
                                  child: Icon(
                                    DkIcons.chevronDown,
                                    size: sizes.iconInline,
                                    color: colors.textTertiary,
                                  ),
                                ),
                              ),
                              DkLine(
                                subtitle,
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
                ),
              ),
              _ArrowButton(
                icon: DkIcons.next,
                label: nextLabel,
                onPressed: onNext,
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
