import 'package:design_kit/src/components/dk_button.dart';
import 'package:design_kit/src/components/dk_card.dart';
import 'package:design_kit/src/theme/dk_context.dart';
import 'package:design_kit/src/tokens/dk_dimensions.dart';
import 'package:design_kit/src/tokens/dk_icons.dart';
import 'package:flutter/material.dart';

/// Empty state, DESIGN.md §4: route icon on an accentSoft tile (80), title,
/// message, optional primary button with a plus icon.
class DkEmptyState extends StatelessWidget {
  /// Creates an empty state.
  const new({
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  /// `titleL` title.
  final String title;

  /// `body` message.
  final String? message;

  /// Button label (with [onAction]).
  final String? actionLabel;

  /// Button action.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final label = actionLabel;
    return _StateLayout(
      icon: DkIcons.empty,
      tileColor: colors.accentSoft,
      iconColor: colors.accent,
      title: title,
      message: message,
      action: label == null || onAction == null
          ? null
          : DkButton(label: label, icon: DkIcons.add, onPressed: onAction),
    );
  }
}

/// Error state, DESIGN.md §4: cloud-off on an errorSoft tile, title, message,
/// «Повторить» with a rotate icon. A live region.
class DkErrorState extends StatelessWidget {
  /// Creates an error state.
  const new({
    required this.title,
    required this.onRetry,
    this.message,
    this.retryLabel = 'Повторить',
    this.isRetrying = false,
    super.key,
  });

  /// `titleL` title.
  final String title;

  /// `body` message.
  final String? message;

  /// Retry action.
  final VoidCallback onRetry;

  /// Button label.
  final String retryLabel;

  /// Shows the button as loading.
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    return Semantics(
      liveRegion: true,
      child: _StateLayout(
        icon: DkIcons.loadError,
        tileColor: colors.errorSoft,
        iconColor: colors.error,
        title: title,
        message: message,
        action: DkButton(
          label: retryLabel,
          icon: DkIcons.retry,
          isLoading: isRetrying,
          onPressed: onRetry,
        ),
      ),
    );
  }
}

class _StateLayout extends StatelessWidget {
  const new({
    required this.icon,
    required this.tileColor,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.action,
  });

  final IconData icon;
  final Color tileColor;
  final Color iconColor;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final text = context.dkText;
    final spacing = context.dkSpacing;
    final sizes = context.dkSizes;
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(spacing.s16, 0, spacing.s16, spacing.s64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: spacing.s24,
          children: [
            ExcludeSemantics(
              child: Container(
                width: sizes.stateIconTile,
                height: sizes.stateIconTile,
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(context.dkRadii.xl),
                ),
                child: Icon(icon, size: sizes.stateIcon, color: iconColor),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              spacing: spacing.s8,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: text.titleL.copyWith(color: colors.textPrimary),
                ),
                if (message case final value?)
                  Text(
                    value,
                    textAlign: TextAlign.center,
                    style: text.body.copyWith(color: colors.textSecondary),
                  ),
              ],
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}

enum _SkeletonKind { line, box, summaryCard, paymentCard, listHeader, tripTile }

/// Loading placeholders, DESIGN.md §4. Color `skeleton`, pulse
/// 1 → 0.55 → 1 in 1.4 s, still under reduced motion. Composites replicate
/// the real layouts 1:1 (same paddings, radii, tile sizes).
class DkSkeleton extends StatelessWidget {
  /// A line; radius defaults to `min(sm, height / 2)` (16 → 8, 12 → 6).
  const new line({
    required double this.width,
    required double this.height,
    this.radius,
    super.key,
  }) : _kind = _SkeletonKind.line;

  /// A square box (icon tiles); radius defaults to `md`.
  const new box({required double size, this.radius, super.key})
    : width = size,
      height = size,
      _kind = _SkeletonKind.box;

  /// The summary card's shape.
  const new summaryCard({super.key})
    : width = null,
      height = null,
      radius = null,
      _kind = _SkeletonKind.summaryCard;

  /// The payment card's shape.
  const new paymentCard({super.key})
    : width = null,
      height = null,
      radius = null,
      _kind = _SkeletonKind.paymentCard;

  /// The list header's shape (§5.3: 88×18, with `DkListHeader`'s padding).
  const new listHeader({super.key})
    : width = null,
      height = null,
      radius = null,
      _kind = _SkeletonKind.listHeader;

  /// One trip row's shape (put several in a `DkTripList`).
  const new tripTile({super.key})
    : width = null,
      height = null,
      radius = null,
      _kind = _SkeletonKind.tripTile;

  /// Width (line/box); `double.infinity` stretches.
  final double? width;

  /// Height (line/box).
  final double? height;

  /// Corner radius override.
  final double? radius;

  final _SkeletonKind _kind;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: _Pulse(
        child: switch (_kind) {
          _SkeletonKind.line => _block(
            context,
            width!,
            height!,
            radius ??
                (context.dkRadii.sm < height! / 2
                    ? context.dkRadii.sm
                    : height! / 2),
          ),
          _SkeletonKind.box => _block(
            context,
            width!,
            height!,
            radius ?? context.dkRadii.md,
          ),
          _SkeletonKind.summaryCard => const _SummaryCardShape(),
          _SkeletonKind.paymentCard => const _PaymentCardShape(),
          _SkeletonKind.listHeader => Padding(
            padding: EdgeInsets.symmetric(horizontal: context.dkSpacing.s4),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: _line(
                context,
                context.dkSpacing.s64 + context.dkSpacing.s24,
                context.dkSpacing.s16 + context.dkSpacing.s2,
              ),
            ),
          ),
          _SkeletonKind.tripTile => const _TripTileShape(),
        },
      ),
    );
  }
}

Widget _block(BuildContext context, double w, double h, double r) => Container(
  width: w,
  height: h,
  decoration: BoxDecoration(
    color: context.dkColors.skeleton,
    borderRadius: BorderRadius.circular(r),
  ),
);

/// A line with the default skeleton radius rule.
Widget _line(BuildContext context, double w, double h) {
  final sm = context.dkRadii.sm;
  return _block(context, w, h, sm < h / 2 ? sm : h / 2);
}

class _SummaryCardShape extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final s = context.dkSpacing;
    // Sizes from DESIGN.md §4 (label 72×16, hero 196×44 r12, metric label
    // 56–64×12, value 64–80×20); the count column from 04_day_loading.
    Widget metric(double labelW, double valueW) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: s.s8,
      children: [_line(context, labelW, s.s12), _line(context, valueW, s.s20)],
    );
    return DkCard(
      hero: true,
      radius: context.dkRadii.xl,
      padding: EdgeInsets.all(s.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: s.s16,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: s.s8,
            children: [
              _line(context, s.s64 + s.s8, s.s16),
              _block(
                context,
                s.s64 * 3 + s.s4,
                s.s40 + s.s4,
                context.dkRadii.md,
              ),
            ],
          ),
          Divider(height: context.dkSizes.fieldBorder),
          Row(
            spacing: s.s12,
            children: [
              Expanded(child: metric(s.s48 + s.s8, s.s64 + s.s16)),
              Expanded(child: metric(s.s64, s.s64)),
              Expanded(child: metric(s.s48 + s.s4, s.s24)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentCardShape extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final s = context.dkSpacing;
    final sizes = context.dkSizes;
    Widget tile(double labelW) => Row(
      spacing: s.s12,
      children: [
        _block(context, sizes.iconTile, sizes.iconTile, context.dkRadii.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: s.s8,
          children: [
            _line(context, labelW, s.s12),
            _line(context, s.s64 + s.s8, s.s20),
          ],
        ),
      ],
    );
    return DkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: s.s14,
        children: [
          Row(
            spacing: s.s12,
            children: [
              Expanded(child: tile(s.s64 + s.s24)),
              Expanded(child: tile(s.s64 + s.s8)),
            ],
          ),
          _block(
            context,
            double.infinity,
            sizes.splitBarHeight,
            context.dkRadii.xs,
          ),
        ],
      ),
    );
  }
}

class _TripTileShape extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final s = context.dkSpacing;
    final sizes = context.dkSizes;
    // DESIGN.md §4: trip 112×16 + 88×12, amount 68×16 + 96×12.
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: sizes.tripTileMinHeight),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: s.s16, vertical: s.s12),
        child: Row(
          spacing: s.s12,
          children: [
            _block(context, sizes.iconTile, sizes.iconTile, context.dkRadii.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: s.s8,
                children: [
                  _line(context, s.s64 + s.s48, s.s16),
                  _line(context, s.s64 + s.s24, s.s12),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: s.s8,
              children: [
                _line(context, s.s64 + s.s4, s.s16),
                _line(context, s.s64 + s.s32, s.s12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pulse extends StatefulWidget {
  const new({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: DkMotion.skeletonPulse,
  );
  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1, end: DkMotion.skeletonMinOpacity),
      weight: 1,
    ),
    TweenSequenceItem(
      tween: Tween(begin: DkMotion.skeletonMinOpacity, end: 1),
      weight: 1,
    ),
  ]).chain(CurveTween(curve: DkMotion.skeletonCurve)).animate(_controller);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: widget.child);
}
