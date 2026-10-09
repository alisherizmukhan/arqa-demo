import 'package:design_kit/src/theme/dk_context.dart';
import 'package:design_kit/src/tokens/dk_icons.dart';
import 'package:flutter/material.dart';

/// Day screen header, DESIGN.md §5.1: 12×12 accent square (r4), gap 10,
/// «Дневник смен» in `wordmark`; row min height 48.
class DkWordmark extends StatelessWidget {
  /// Creates the wordmark.
  const new({required this.title, this.trailing, this.caption, super.key});

  /// App title.
  final String title;

  /// Small line under the title («Администратор» on the admin screen).
  final String? caption;

  /// Right-aligned action (e.g. [DkTodayButton]).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final sizes = context.dkSizes;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: sizes.headerHeight),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: sizes.wordmarkDot,
              height: sizes.wordmarkDot,
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: BorderRadius.circular(context.dkRadii.xs),
              ),
            ),
          ),
          SizedBox(width: context.dkSpacing.s10),
          Expanded(
            child: Semantics(
              header: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: context.dkText.wordmark.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  if (caption case final value?)
                    Text(
                      value,
                      style: context.dkText.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// «Сегодня» pill for the header: `accentSoft` / `accent`, icon + label,
/// 48 tap target. Shown only while another day is selected.
class DkTodayButton extends StatelessWidget {
  /// Creates the button.
  const new({required this.onPressed, required this.label, super.key});

  /// Jumps to today.
  final VoidCallback onPressed;

  /// «Сегодня».
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final spacing = context.dkSpacing;
    final sizes = context.dkSizes;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: SizedBox(
          height: sizes.tapTargetMin,
          child: Center(
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: colors.accentSoft,
                shape: const StadiumBorder(),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.s12,
                  vertical: spacing.s6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: spacing.s6,
                  children: [
                    Icon(
                      DkIcons.today,
                      size: sizes.iconInline,
                      color: colors.accent,
                    ),
                    Text(
                      label,
                      style: context.dkText.captionStrong.copyWith(
                        color: colors.accent,
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

/// App bar of a full-screen modal, DESIGN.md §5.6: close button 48, centred
/// title (`titleM`) + subtitle (`caption`), a 48 spacer on the right.
class DkModalAppBar extends StatelessWidget {
  /// Creates the app bar.
  const new({
    required this.title,
    required this.onClose,
    required this.closeLabel,
    this.subtitle,
    this.leadingIcon = DkIcons.close,
    super.key,
  });

  /// ✕ for a modal form; [DkIcons.previous] for a pushed page («Назад»).
  final IconData leadingIcon;

  /// Title.
  final String title;

  /// Subtitle (date).
  final String? subtitle;

  /// Close action.
  final VoidCallback onClose;

  /// Accessible name of the close button.
  final String closeLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final sizes = context.dkSizes;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: sizes.appBarHeight),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.dkSpacing.s8),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: closeLabel,
              excludeSemantics: true,
              child: SizedBox.square(
                dimension: sizes.tapTargetMin,
                child: InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(context.dkRadii.md),
                  child: Icon(
                    leadingIcon,
                    size: sizes.iconNav,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Column(
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: context.dkText.titleM.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    if (subtitle case final value?)
                      Text(
                        value,
                        textAlign: TextAlign.center,
                        style: context.dkText.caption.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(width: sizes.tapTargetMin),
          ],
        ),
      ),
    );
  }
}

/// Pinned bottom bar of a form, DESIGN.md §5.6: `bg`, top border `divider`,
/// padding 12 16, bottom = safe area + 8.
class DkBottomBar extends StatelessWidget {
  /// Creates the bar.
  const new({required this.child, super.key});

  /// Usually a full-width `DkButton`.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final spacing = context.dkSpacing;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bg,
        border: Border(
          top: BorderSide(
            color: colors.divider,
            width: context.dkSizes.fieldBorder,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          spacing.s16,
          spacing.s12,
          spacing.s16,
          safeBottom + spacing.s8,
        ),
        child: child,
      ),
    );
  }
}

/// 48×48 icon button, DESIGN.md §8.0: transparent, radius md, icon 24
/// (`textPrimary`, or `accent` when [active]). [label] is its spoken name.
class DkIconButton extends StatelessWidget {
  /// Creates the button.
  const new({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
    super.key,
  });

  /// The icon.
  final IconData icon;

  /// Accessible name, e.g. «Сортировка: сначала ранние».
  final String label;

  /// Tap handler.
  final VoidCallback onPressed;

  /// Draws the icon in `accent` (a non-default setting is on).
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final sizes = context.dkSizes;
    return Semantics(
      button: true,
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
            color: active ? colors.accent : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
