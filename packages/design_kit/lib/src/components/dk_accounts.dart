import 'package:design_kit/src/components/dk_button.dart';
import 'package:design_kit/src/components/dk_card.dart';
import 'package:design_kit/src/components/dk_chrome.dart';
import 'package:design_kit/src/components/dk_inputs.dart';
import 'package:design_kit/src/format/dk_grouped_text.dart';
import 'package:design_kit/src/format/dk_money.dart';
import 'package:design_kit/src/theme/dk_context.dart';
import 'package:design_kit/src/tokens/dk_icons.dart';
import 'package:flutter/material.dart';

// Components of DESIGN.md §8 (accounts, menu, withdrawals, admin). They have
// no texts of their own: every label is a parameter, so the app can translate.

/// Password field, DESIGN.md §8.0: a [DkTextField] with an eye button that
/// shows or hides the text ([showLabel] / [hideLabel] are its spoken names).
class DkPasswordField extends StatefulWidget {
  /// Creates the field.
  const new({
    required this.label,
    required this.controller,
    required this.showLabel,
    required this.hideLabel,
    this.errorText,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// «Пароль».
  final String label;

  /// Text controller.
  final TextEditingController controller;

  /// «Показать пароль».
  final String showLabel;

  /// «Скрыть пароль».
  final String hideLabel;

  /// Error below the field.
  final String? errorText;

  /// Focus node.
  final FocusNode? focusNode;

  /// Keyboard action.
  final TextInputAction? textInputAction;

  /// Enter pressed.
  final ValueChanged<String>? onSubmitted;

  /// Change handler.
  final ValueChanged<String>? onChanged;

  /// Whether the field is interactive.
  final bool enabled;

  @override
  State<DkPasswordField> createState() => _DkPasswordFieldState();
}

class _DkPasswordFieldState extends State<DkPasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) => DkTextField(
    label: widget.label,
    controller: widget.controller,
    errorText: widget.errorText,
    focusNode: widget.focusNode,
    textInputAction: widget.textInputAction,
    onSubmitted: widget.onSubmitted,
    onChanged: widget.onChanged,
    enabled: widget.enabled,
    obscureText: !_visible,
    autofillHints: const [AutofillHints.password],
    trailing: DkIconButton(
      icon: _visible ? DkIcons.eyeOff : DkIcons.eye,
      label: _visible ? widget.hideLabel : widget.showLabel,
      onPressed: () => setState(() => _visible = !_visible),
    ),
  );
}

/// Language switch, DESIGN.md §8.0: a [DkSegmentedControl] with one segment
/// per language, no icons. Labels are each language's own name («Русский»,
/// «Қазақша»), never translated. Always 56 high: a 48-high track (§8.1
/// "compact") would make each segment 40, below the 48 dp tap target.
class DkLanguageSwitch extends StatelessWidget {
  /// Creates the switch.
  const new({
    required this.languages,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  /// (code, own name) per language, in display order.
  final List<({String code, String name})> languages;

  /// Selected code.
  final String selected;

  /// Selection handler.
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => DkSegmentedControl<String>(
    segments: [
      for (final language in languages)
        DkSegment(value: language.code, label: language.name),
    ],
    selected: selected,
    onChanged: onChanged,
  );
}

/// A group of rows in one card, DESIGN.md §8.0: [DkCard] (padding 0, clipped)
/// with 1 px dividers inset 68 between children. A [DkListAttachment] belongs
/// to the row above it (no divider before it).
class DkListGroup extends StatelessWidget {
  /// Creates the group.
  const new({required this.children, super.key});

  /// Usually [DkListRow]s.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    final inset = spacing.s16 + context.dkSizes.iconTile + spacing.s12;
    return DkCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0 && child is! DkListAttachment)
              Divider(height: context.dkSizes.fieldBorder, indent: inset),
            child,
          ],
        ],
      ),
    );
  }
}

/// Content under a row inside a [DkListGroup] (padding 0 16 16), e.g. the
/// language switch under «Язык».
class DkListAttachment extends StatelessWidget {
  /// Creates the attachment.
  const new({required this.child, super.key});

  /// Content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    return Padding(
      padding: EdgeInsets.fromLTRB(spacing.s16, 0, spacing.s16, spacing.s16),
      child: child,
    );
  }
}

/// A row of a [DkListGroup], DESIGN.md §8.0: min 56, padding 0 16, gap 12;
/// icon tile 40 · title (`bodyStrong`) over optional subtitle (`caption`,
/// textTertiary) · trailing (a chevron when [onTap] and no [trailing]).
/// [destructive]: title and icon in `error`.
class DkListRow extends StatelessWidget {
  /// Creates the row.
  const new({
    required this.title,
    this.icon,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
    super.key,
  });

  /// Title.
  final String title;

  /// Leading icon (in a 40 tile).
  final IconData? icon;

  /// Second line.
  final String? subtitle;

  /// Trailing widget (value, control).
  final Widget? trailing;

  /// Tap handler.
  final VoidCallback? onTap;

  /// Destructive action («Выйти»).
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final text = context.dkText;
    final spacing = context.dkSpacing;
    final sizes = context.dkSizes;
    final tone = destructive ? colors.error : colors.textPrimary;
    final end =
        trailing ??
        (onTap != null && !destructive
            ? Icon(
                DkIcons.next,
                size: sizes.iconField,
                color: colors.textTertiary,
              )
            : null);
    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: sizes.buttonHeight),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.s16,
          vertical: spacing.s8,
        ),
        child: Row(
          spacing: spacing.s12,
          children: [
            if (icon case final iconData?)
              ExcludeSemantics(
                child: Container(
                  width: sizes.iconTile,
                  height: sizes.iconTile,
                  decoration: BoxDecoration(
                    color: destructive ? colors.errorSoft : colors.surfaceMuted,
                    borderRadius: BorderRadius.circular(context.dkRadii.md),
                  ),
                  child: Icon(iconData, size: sizes.iconTileIcon, color: tone),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: text.bodyStrong.copyWith(color: tone)),
                  if (subtitle case final value?)
                    DkGroupedText(
                      value,
                      style: text.caption.copyWith(color: colors.textTertiary),
                    ),
                ],
              ),
            ),
            ?end,
          ],
        ),
      ),
    );
    final tap = onTap;
    if (tap == null) return MergeSemantics(child: content);
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(onTap: tap, child: content),
      ),
    );
  }
}

/// Profile card at the top of the Menu, DESIGN.md §8.3: icon tile with
/// `user-round`, [name] (`titleM`) over [caption] («@user_1 · Водитель»).
class DkProfileCard extends StatelessWidget {
  /// Creates the card.
  const new({required this.name, required this.caption, super.key});

  /// Display name.
  final String name;

  /// «@login · role».
  final String caption;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final text = context.dkText;
    return DkCard(
      child: MergeSemantics(
        child: Row(
          spacing: context.dkSpacing.s12,
          children: [
            const DkIconTile(icon: DkIcons.user),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: text.titleM.copyWith(color: colors.textPrimary),
                  ),
                  Text(
                    caption,
                    style: text.caption.copyWith(color: colors.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Withdrawal status, DESIGN.md §8.0.
enum DkStatusKind {
  /// «В обработке»: surfaceMuted / textSecondary, clock.
  pending,

  /// «Выплачено»: successSoft / success, circle-check.
  paid,

  /// «Отклонено»: errorSoft / error, circle-x.
  rejected,
}

/// Status chip, DESIGN.md §8.0: height 24, radius sm, padding h 8, gap 4,
/// icon 14 + [label] in `badge` style. Always icon + text.
class DkStatusChip extends StatelessWidget {
  /// Creates the chip.
  const new({required this.kind, required this.label, super.key});

  /// Which status.
  final DkStatusKind kind;

  /// «В обработке» / «Выплачено» / «Отклонено».
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final (background, foreground, icon) = switch (kind) {
      DkStatusKind.pending => (
        colors.surfaceMuted,
        colors.textSecondary,
        DkIcons.pending,
      ),
      DkStatusKind.paid => (colors.successSoft, colors.success, DkIcons.saved),
      DkStatusKind.rejected => (
        colors.errorSoft,
        colors.error,
        DkIcons.rejected,
      ),
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: EdgeInsets.symmetric(horizontal: context.dkSpacing.s8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(context.dkRadii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: context.dkSpacing.s4,
        children: [
          Icon(icon, size: 14, color: foreground),
          Text(
            label,
            style: context.dkText.badge.copyWith(
              color: foreground,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter chips, DESIGN.md §8.0: a horizontally scrolling row of chips
/// (height 40, tap area 48, radius pill, padding h 16, label 14/600).
/// Selected: `accent` / `onAccent`; others: `surface`, border 1, textPrimary.
class DkFilterChips<T> extends StatelessWidget {
  /// Creates the row.
  const new({
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  /// (value, label) per chip.
  final List<({T value, String label})> options;

  /// Selected value.
  final T selected;

  /// Selection handler.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final spacing = context.dkSpacing;
    final sizes = context.dkSizes;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: spacing.s8,
        children: [
          for (final option in options)
            Semantics(
              button: true,
              selected: option.value == selected,
              inMutuallyExclusiveGroup: true,
              child: SizedBox(
                height: sizes.tapTargetMin,
                child: Center(
                  child: Material(
                    color: option.value == selected
                        ? colors.accent
                        : colors.surface,
                    shape: StadiumBorder(
                      side: option.value == selected
                          ? BorderSide.none
                          : BorderSide(
                              color: colors.border,
                              width: sizes.fieldBorder,
                            ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => onChanged(option.value),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(horizontal: spacing.s16),
                        child: Text(
                          option.label,
                          style: context.dkText.label.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: option.value == selected
                                ? colors.onAccent
                                : colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One figure of a [DkBalanceCard]'s grid.
typedef DkBalanceTile = ({String label, int amount, bool deduction});

/// Balance card, DESIGN.md §8.4: like the summary card — [label] over the
/// [amount] (`moneyHero`, accent), divider, then up to three [tiles]
/// («Безнал», «Комиссия» −, «Выведено» −).
class DkBalanceCard extends StatelessWidget {
  /// Creates the card.
  const new({
    required this.label,
    required this.amount,
    required this.tiles,
    super.key,
  });

  /// «Доступно к выводу».
  final String label;

  /// Available amount (tenge; may be 0 or negative).
  final int amount;

  /// The grid under the divider.
  final List<DkBalanceTile> tiles;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final text = context.dkText;
    final spacing = context.dkSpacing;
    return DkCard(
      hero: true,
      radius: context.dkRadii.xl,
      padding: EdgeInsets.all(spacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing.s16,
        children: [
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: spacing.s4,
              children: [
                Text(
                  label,
                  style: text.label.copyWith(color: colors.textSecondary),
                ),
                DkMoneyText(
                  amount,
                  style: text.moneyHero.copyWith(color: colors.accent),
                  suffixStyle: text.moneyHeroSuffix.copyWith(
                    color: colors.accent,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: context.dkSizes.fieldBorder),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: spacing.s12,
            children: [
              for (final tile in tiles)
                Expanded(
                  child: DkSummaryTile(
                    label: tile.label,
                    value: DkMoney.format(
                      tile.deduction ? -tile.amount : tile.amount,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A withdrawal row, DESIGN.md §8.4 / §8.6: icon tile `wallet` · [title]
/// (amount, or driver for the admin) over [subtitle] (date) and an optional
/// [note] (reject reason) · [status] chip. [actions] go under the row
/// (the admin's «Отклонить» / «Выплатить»). [highlighted]: accentSoft.
class DkWithdrawalTile extends StatelessWidget {
  /// Creates the row.
  const new({
    required this.title,
    required this.subtitle,
    required this.status,
    this.note,
    this.actions,
    this.highlighted = false,
    super.key,
  });

  /// `bodyStrong` first line.
  final String title;

  /// `caption` second line.
  final String subtitle;

  /// Status chip.
  final Widget status;

  /// Third line (`caption`, textSecondary), e.g. the reject reason.
  final String? note;

  /// Buttons under the content.
  final Widget? actions;

  /// Just created: `accentSoft` background.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final text = context.dkText;
    final spacing = context.dkSpacing;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: highlighted ? colors.accentSoft : Colors.transparent,
      padding: EdgeInsets.symmetric(
        horizontal: spacing.s16,
        vertical: spacing.s12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing.s12,
        children: [
          MergeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: spacing.s12,
              children: [
                DkIconTile(
                  icon: DkIcons.wallet,
                  background: highlighted ? colors.surface : null,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DkGroupedText(
                        title,
                        style: text.bodyStrong.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: text.caption.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                      if (note case final value?)
                        Text(
                          value,
                          style: text.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                status,
              ],
            ),
          ),
          ?actions,
        ],
      ),
    );
  }
}

/// An info line (icon `info` 16 + text, textSecondary), DESIGN.md §8.4
/// («Сейчас нечего выводить.»).
class DkInfoRow extends StatelessWidget {
  /// Creates the line.
  const new({required this.text, super.key});

  /// The message.
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: context.dkSpacing.s8,
      children: [
        Icon(
          DkIcons.info,
          size: context.dkSizes.iconField,
          color: colors.textSecondary,
        ),
        Expanded(
          child: Text(
            text,
            style: context.dkText.bodyS.copyWith(color: colors.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// One action of [showDkActionSheet].
typedef DkSheetAction = ({
  IconData icon,
  String label,
  bool destructive,
  VoidCallback onTap,
});

/// An action sheet (DESIGN.md §8.6, driver actions): handle, [title], then the
/// [actions] as [DkListRow]s. Tapping one closes the sheet, then runs it.
Future<void> showDkActionSheet(
  BuildContext context, {
  required String title,
  required List<DkSheetAction> actions,
  String? subtitle,
}) {
  final colors = context.dkColors;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: colors.surface,
    barrierColor: colors.scrim,
    useSafeArea: true,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(context.dkRadii.xl),
      ),
    ),
    builder: (_) =>
        DkActionSheet(title: title, subtitle: subtitle, actions: actions),
  );
}

/// The action sheet's content (public for the showcase and goldens).
class DkActionSheet extends StatelessWidget {
  /// Creates the content.
  const new({
    required this.title,
    required this.actions,
    this.subtitle,
    this.popOnAction = true,
    super.key,
  });

  /// Sheet title.
  final String title;

  /// Second line under the title.
  final String? subtitle;

  /// The actions.
  final List<DkSheetAction> actions;

  /// Close the sheet before running an action (false in previews).
  final bool popOnAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final spacing = context.dkSpacing;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: spacing.s8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: spacing.s40,
                  height: spacing.s4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(context.dkRadii.pill),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.s16,
                  vertical: spacing.s12,
                ),
                child: Semantics(
                  header: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.dkText.titleM.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      if (subtitle case final value?)
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
              for (final action in actions)
                DkListRow(
                  icon: action.icon,
                  title: action.label,
                  destructive: action.destructive,
                  trailing: const SizedBox.shrink(),
                  onTap: () {
                    if (popOnAction) Navigator.of(context).pop();
                    action.onTap();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two buttons side by side under an admin's pending withdrawal (§8.6):
/// secondary «Отклонить», primary «Выплатить», each 48 high.
class DkDecisionButtons extends StatelessWidget {
  /// Creates the pair.
  const new({
    required this.rejectLabel,
    required this.approveLabel,
    required this.onReject,
    required this.onApprove,
    this.approving = false,
    super.key,
  });

  /// «Отклонить».
  final String rejectLabel;

  /// «Выплатить».
  final String approveLabel;

  /// Reject tapped.
  final VoidCallback? onReject;

  /// Approve tapped.
  final VoidCallback? onApprove;

  /// Approve in flight: its button shows a spinner, both are disabled.
  final bool approving;

  @override
  Widget build(BuildContext context) => Row(
    spacing: context.dkSpacing.s8,
    children: [
      Expanded(
        child: DkButton(
          label: rejectLabel,
          variant: DkButtonVariant.secondary,
          compact: true,
          expand: true,
          onPressed: approving ? null : onReject,
        ),
      ),
      Expanded(
        child: DkButton(
          label: approveLabel,
          compact: true,
          expand: true,
          isLoading: approving,
          onPressed: approving ? null : onApprove,
        ),
      ),
    ],
  );
}
