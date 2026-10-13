import 'package:design_kit/src/components/dk_card.dart';
import 'package:design_kit/src/components/dk_layout.dart';
import 'package:design_kit/src/format/dk_fit_text.dart';
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

  /// Lucide icon.
  IconData get icon => switch (this) {
    DkPaymentMethod.cash => DkIcons.cash,
    DkPaymentMethod.card => DkIcons.card,
  };
}

/// One trip row, DESIGN.md §4. Strings come formatted: `08:10 – 08:32`,
/// `22 мин · Карта`, `2 400 ₸`, `комиссия 360 ₸`. A trip with places
/// (DESIGN.md §9) adds the [route] line and opens its details on [onTap]
/// (trailing chevron); a trip without places stays read-only.
class DkTripTile extends StatelessWidget {
  /// Creates a trip row.
  const new({
    required this.timeRange,
    required this.endsNextDay,
    required this.meta,
    required this.amount,
    required this.commission,
    required this.method,
    required this.nextDayLabel,
    this.highlighted = false,
    this.driver,
    this.route,
    this.onTap,
    super.key,
  });

  /// `Зелёный базар → ТРЦ Есентай Молл` (`caption`, textTertiary, one line,
  /// «…»): under the time, meta and amount lines, across their full width
  /// (beside the amounts it would keep only its first place).
  final String? route;

  /// Opens the trip details; adds a chevron (20, textTertiary).
  final VoidCallback? onTap;

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

    final tile = MergeSemantics(
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : DkMotion.segment,
        color: highlighted ? colors.accentSoft : colors.surface,
        constraints: BoxConstraints(
          minHeight: context.dkSizes.tripTileMinHeight,
        ),
        // A tappable row: the chevron sits 4 after the amounts and 8 from
        // the edge (its glyph has its own margin), so the text keeps room.
        padding: EdgeInsetsDirectional.fromSTEB(
          spacing.s16,
          spacing.s12,
          onTap == null ? spacing.s16 : spacing.s8,
          spacing.s12,
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                spacing: spacing.s12,
                children: [
                  DkIconTile(
                    icon: method.icon,
                    background: highlighted ? colors.surface : null,
                  ),
                  Expanded(
                    // DESIGN.md §10, rule 7: every line is one line. The
                    // time and the amounts are never cut; the meta and
                    // driver lines give way first; if the amounts still
                    // cannot fit at 85 %, they move to their own line.
                    child: _withRoute(
                      context,
                      route,
                      DkAmountRow(
                        gap: spacing.s12,
                        start: DkFitLines([
                          DkLine.span(
                            TextSpan(
                              style: text.bodyStrong.copyWith(
                                color: colors.textPrimary,
                              ),
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
                            text: timeRange,
                            ellipsis: false,
                          ),
                          DkLine(
                            meta,
                            style: text.bodyS.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          if (driver case final name?)
                            DkLine(
                              name,
                              style: text.caption.copyWith(
                                color: colors.textTertiary,
                              ),
                            ),
                        ]),
                        end: DkFitLines(textAlign: TextAlign.end, [
                          DkLine(
                            amount,
                            ellipsis: false,
                            style: text.bodyStrong.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          DkLine(
                            commission,
                            ellipsis: false,
                            style: text.caption.copyWith(
                              color: colors.textTertiary,
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Padding(
                padding: EdgeInsetsDirectional.only(start: spacing.s4),
                child: Icon(
                  DkIcons.next,
                  size: context.dkSizes.iconField,
                  color: colors.textTertiary,
                ),
              ),
          ],
        ),
      ),
    );
    final tap = onTap;
    if (tap == null) return tile;
    // One node: the button carries the row's texts.
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(onTap: tap, child: tile),
      ),
    );
  }
}

/// [row], then the [route] line across its full width (DESIGN.md §9).
Widget _withRoute(BuildContext context, String? route, Widget row) {
  if (route == null) return row;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: context.dkSpacing.s2,
    children: [
      row,
      DkFitText(
        route,
        style: context.dkText.caption.copyWith(
          color: context.dkColors.textTertiary,
        ),
      ),
    ],
  );
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
