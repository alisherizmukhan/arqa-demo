import 'package:design_kit/src/components/dk_button.dart';
import 'package:design_kit/src/theme/dk_context.dart';
import 'package:design_kit/src/tokens/dk_dimensions.dart';
import 'package:flutter/material.dart';

/// Nothing to show yet, with an optional next step.
class DkEmptyState extends StatelessWidget {
  /// Creates an empty state. [actionLabel] and [onAction] go together.
  const new({
    required this.title,
    this.message,
    this.icon = Icons.local_taxi_outlined,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction must be set together',
       );

  /// Main line, e.g. `Поездок нет`.
  final String title;

  /// Supporting text.
  final String? message;

  /// Illustration icon.
  final IconData icon;

  /// Label of the optional action button.
  final String? actionLabel;

  /// Optional action.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return _StateLayout(
      icon: icon,
      iconColor: context.dkColors.textSecondary,
      title: title,
      message: message,
      action: onAction == null
          ? null
          : DkButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: DkButtonVariant.secondary,
              expand: false,
            ),
    );
  }
}

/// Something went wrong; always offers a retry.
class DkErrorState extends StatelessWidget {
  /// Creates an error state.
  const new({
    required this.onRetry,
    this.title = 'Не удалось загрузить',
    this.message,
    this.retryLabel = 'Повторить',
    this.icon = Icons.cloud_off_outlined,
    super.key,
  });

  /// Main line.
  final String title;

  /// Cause and what to do, e.g. `Проверьте интернет и попробуйте ещё раз.`
  final String? message;

  /// Retry handler.
  final VoidCallback onRetry;

  /// Retry button label.
  final String retryLabel;

  /// Illustration icon.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: _StateLayout(
        icon: icon,
        iconColor: context.dkColors.error,
        title: title,
        message: message,
        action: DkButton(
          label: retryLabel,
          onPressed: onRetry,
          icon: Icons.refresh,
          expand: false,
        ),
      ),
    );
  }
}

class _StateLayout extends StatelessWidget {
  const new({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final text = context.dkText;
    final spacing = context.dkSpacing;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.s24,
          vertical: spacing.s48,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(
                icon,
                size: context.dkSizes.stateIcon,
                color: iconColor,
              ),
            ),
            SizedBox(height: spacing.s16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: text.titleM.copyWith(color: colors.textPrimary),
            ),
            if (message != null) ...[
              SizedBox(height: spacing.s8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: text.body.copyWith(color: colors.textSecondary),
              ),
            ],
            if (action != null) ...[SizedBox(height: spacing.s24), action!],
          ],
        ),
      ),
    );
  }
}

/// Placeholder block shown while content loads. Pulses gently, and stays
/// still when the platform requests reduced motion.
class DkSkeleton extends StatefulWidget {
  /// Creates a skeleton block. A null [width] fills the available width.
  const new({required this.height, this.width, this.radius, super.key});

  /// Block height.
  final double height;

  /// Block width.
  final double? width;

  /// Corner radius; defaults to `radii.sm`.
  final double? radius;

  @override
  State<DkSkeleton> createState() => _DkSkeletonState();
}

class _DkSkeletonState extends State<DkSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: DkMotion.skeletonPulse,
    lowerBound: 0.55,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: _controller,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: context.dkColors.surfaceMuted,
            borderRadius: BorderRadius.circular(
              widget.radius ?? context.dkRadii.sm,
            ),
          ),
        ),
      ),
    );
  }
}
