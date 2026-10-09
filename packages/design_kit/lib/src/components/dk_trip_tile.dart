import 'package:design_kit/src/components/dk_card.dart';
import 'package:design_kit/src/format/dk_grouped_text.dart';
import 'package:design_kit/src/theme/dk_context.dart';
import 'package:design_kit/src/tokens/dk_dimensions.dart';
import 'package:design_kit/src/tokens/dk_icons.dart';
import 'package:flutter/material.dart';

/// How a trip was paid (the kit's own enum; the app maps its domain enum).
enum DkPaymentMethod {
  /// Cash.
  cash,

  /// Card.
  card;

  /// Default Russian label.
  String get label => switch (this) {
    DkPaymentMethod.cash => 'Наличные',
    DkPaymentMethod.card => 'Карта',
  };

  /// Lucide icon.
  IconData get icon => switch (this) {
    DkPaymentMethod.cash => DkIcons.cash,
    DkPaymentMethod.card => DkIcons.card,
  };
}

/// One trip row, DESIGN.md §4 (read-only, no tap). Strings come formatted:
/// `08:10 – 08:32`, `22 мин · Карта`, `2 400 ₸`, `комиссия 360 ₸`.
class DkTripTile extends StatelessWidget {
  /// Creates a trip row.
  const new({
    required this.timeRange,
    required this.endsNextDay,
    required this.meta,
    required this.amount,
    required this.commission,
    required this.method,
    this.highlighted = false,
    this.nextDayLabel = 'следующий день',
    this.driver,
    super.key,
  });

  /// Admin, all drivers: the driver's name on its own third line (`caption`,
  /// textTertiary), DESIGN.md §8.6.
  final String? driver;

  /// `08:10 – 08:32`.
  final String timeRange;

  /// Adds the accent «+1» superscript after the end time.
  final bool endsNextDay;

  /// `22 мин · Карта`.
  final String meta;

  /// `2 400 ₸`.
  final String amount;

  /// `комиссия 360 ₸`.
  final String commission;

  /// Payment method (icon).
  final DkPaymentMethod method;

  /// `accentSoft` background, for ~2 s after the trip was added.
  final bool highlighted;

  /// Accessible reading of «+1».
  final String nextDayLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final text = context.dkText;
    final spacing = context.dkSpacing;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return MergeSemantics(
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : DkMotion.segment,
        color: highlighted ? colors.accentSoft : colors.surface,
        constraints: BoxConstraints(
          minHeight: context.dkSizes.tripTileMinHeight,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: spacing.s16,
          vertical: spacing.s12,
        ),
        child: Row(
          spacing: spacing.s12,
          children: [
            DkIconTile(
              icon: method.icon,
              background: highlighted ? colors.surface : null,
            ),
            Expanded(
              // Both columns keep their natural width (at most half each):
              // the amount sits at the right padding, and with huge amounts
              // or a large text scale «комиссия …» wraps instead of
              // overflowing. No LayoutBuilder, so intrinsic layouts work.
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: spacing.s12,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: timeRange),
                              if (endsNextDay)
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.top,
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.only(
                                      start: spacing.s2,
                                    ),
                                    child: Text(
                                      '+1',
                                      semanticsLabel: nextDayLabel,
                                      style: text.superscript.copyWith(
                                        color: colors.accent,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          style: text.bodyStrong.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        // One line: «30 мин · Наличные» shrinks to fit
                        // rather than wrapping the payment onto a new line.
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            meta,
                            maxLines: 1,
                            style: text.bodyS.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                        if (driver case final name?)
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.caption.copyWith(
                              color: colors.textTertiary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        DkGroupedText(
                          amount,
                          textAlign: TextAlign.end,
                          style: text.bodyStrong.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        DkGroupedText(
                          commission,
                          textAlign: TextAlign.end,
                          style: text.caption.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
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

/// Trip rows in one card (padding 0, clipped), dividers inset 68.
class DkTripList extends StatelessWidget {
  /// Creates the list card.
  const new({required this.children, super.key});

  /// Usually [DkTripTile]s.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    // Inset = row padding + icon tile + gap (16 + 40 + 12 = 68).
    final inset = spacing.s16 + context.dkSizes.iconTile + spacing.s12;
    return DkCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0)
              Divider(height: context.dkSizes.fieldBorder, indent: inset),
            child,
          ],
        ],
      ),
    );
  }
}

/// Section header above a list: «Поездки» + «2 поездки · 37 мин».
class DkListHeader extends StatelessWidget {
  /// Creates a header.
  const new({required this.title, this.trailing, this.action, super.key});

  /// `titleM` title.
  final String title;

  /// `captionStrong` summary on the right.
  final String? trailing;

  /// A control after the summary (e.g. a sort `DkIconButton`).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final text = context.dkText;
    final heading = Semantics(
      header: true,
      child: Text(
        title,
        style: text.titleM.copyWith(color: colors.textPrimary),
      ),
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.dkSpacing.s4),
      child: Row(
        spacing: context.dkSpacing.s8,
        children: [
          // The summary (or, without one, the title) takes the free space,
          // so the summary and the action end at the right edge.
          if (trailing == null) Expanded(child: heading) else heading,
          if (trailing case final value?)
            // One line: scales down rather than wrapping or overflowing
            // when an [action] takes room.
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  value,
                  maxLines: 1,
                  style: text.captionStrong.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ),
            ),
          ?action,
        ],
      ),
    );
  }
}
