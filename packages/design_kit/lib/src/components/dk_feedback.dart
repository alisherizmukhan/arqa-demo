import 'dart:async';

import 'package:design_kit/src/components/dk_button.dart';
import 'package:design_kit/src/theme/dk_context.dart';
import 'package:design_kit/src/tokens/dk_dimensions.dart';
import 'package:design_kit/src/tokens/dk_icons.dart';
import 'package:flutter/material.dart';

/// Kind of [showDkSnackbar].
enum DkSnackTone {
  /// Neutral message, full width.
  info,

  /// Compact «Поездка добавлена», bottom-left, auto-dismiss after 3 s.
  success,

  /// «Нет связи…» with the wifi-off icon, full width, stays until closed.
  error,
}

/// A shown snackbar; [close] removes it.
class DkSnackbarHandle {
  new _(this._entry);

  final OverlayEntry _entry;
  Timer? _timer;
  bool _open = true;

  /// Whether it is still on screen.
  bool get isOpen => _open;

  /// Removes the snackbar (no-op when already closed).
  void close() {
    if (!_open) return;
    _open = false;
    _timer?.cancel();
    _entry.remove();
    if (identical(_current, this)) _current = null;
  }
}

DkSnackbarHandle? _current;

/// Shows a snackbar, DESIGN.md §4 (one at a time; a new one replaces it).
///
/// error/info: full width (16 from both edges) at [bottom] (default: safe
/// area + 16; the form passes "12 above the bottom bar"). success: compact,
/// bottom-left, at most [maxWidth] wide so it sits **beside** the FAB.
DkSnackbarHandle showDkSnackbar(
  BuildContext context, {
  required String message,
  DkSnackTone tone = DkSnackTone.info,
  String? actionLabel,
  VoidCallback? onAction,
  double? bottom,
  double? maxWidth,
  Duration? duration,
}) {
  _current?.close();
  final overlay = Overlay.of(context);
  late final DkSnackbarHandle handle;
  final entry = OverlayEntry(
    builder: (context) {
      final spacing = context.dkSpacing;
      final offset =
          bottom ?? MediaQuery.paddingOf(context).bottom + spacing.s16;
      final compact = tone == DkSnackTone.success;
      return Positioned(
        left: spacing.s16,
        right: compact ? null : spacing.s16,
        bottom: offset,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
          child: _FadeIn(
            child: Semantics(
              liveRegion: true,
              child: Material(
                type: MaterialType.transparency,
                child: DkSnackbarView(
                  message: message,
                  tone: tone,
                  actionLabel: actionLabel,
                  onAction: onAction,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  handle = DkSnackbarHandle._(entry);
  overlay.insert(entry);
  _current = handle;
  final lifetime =
      duration ?? (tone == DkSnackTone.success ? DkMotion.successSnack : null);
  if (lifetime != null) handle._timer = Timer(lifetime, handle.close);
  return handle;
}

/// The snackbar's visual (no positioning or lifetime): used by
/// [showDkSnackbar] and directly by the showcase and goldens.
class DkSnackbarView extends StatelessWidget {
  /// Creates a snackbar view.
  const new({
    required this.message,
    this.tone = DkSnackTone.info,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  /// Text.
  final String message;

  /// Kind.
  final DkSnackTone tone;

  /// Action label (error/info only).
  final String? actionLabel;

  /// Action.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    if (tone == DkSnackTone.success) return _SuccessSnack(message: message);
    final isError = tone == DkSnackTone.error;
    final colors = context.dkColors;
    final text = context.dkText;
    final spacing = context.dkSpacing;
    final sizes = context.dkSizes;
    final label = actionLabel;
    return Container(
      padding: EdgeInsets.fromLTRB(
        spacing.s16,
        spacing.s8,
        spacing.s8,
        spacing.s8,
      ),
      decoration: BoxDecoration(
        color: colors.inverseSurface,
        borderRadius: BorderRadius.circular(context.dkRadii.lg),
        boxShadow: context.dkElevation.e3,
      ),
      child: Row(
        spacing: spacing.s12,
        children: [
          if (isError)
            Icon(
              DkIcons.offline,
              size: sizes.iconAction,
              color: colors.inverseError,
            ),
          Expanded(
            child: Text(
              message,
              style: text.bodyS.copyWith(color: colors.onInverse),
            ),
          ),
          if (label != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: colors.inverseAccent,
                minimumSize: Size(sizes.tapTargetMin, sizes.textButtonHeight),
                // Action: 15/700 (DESIGN.md §4) = bodyStrong at bodyMd's size.
                textStyle: text.bodyStrong.copyWith(
                  fontSize: text.bodyMd.fontSize,
                ),
              ),
              child: Text(label),
            ),
        ],
      ),
    );
  }
}

class _SuccessSnack extends StatelessWidget {
  const new({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final spacing = context.dkSpacing;
    return Container(
      constraints: BoxConstraints(minHeight: context.dkSizes.buttonHeight),
      padding: EdgeInsetsDirectional.only(start: spacing.s14, end: spacing.s16),
      decoration: BoxDecoration(
        color: colors.inverseSurface,
        borderRadius: BorderRadius.circular(context.dkRadii.lg),
        boxShadow: context.dkElevation.e3,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: spacing.s8,
        children: [
          Icon(
            DkIcons.saved,
            size: context.dkSizes.iconAction,
            color: colors.inverseSuccess,
          ),
          Flexible(
            child: Text(
              message,
              style: context.dkText.label.copyWith(color: colors.onInverse),
            ),
          ),
        ],
      ),
    );
  }
}

class _FadeIn extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: DkMotion.segment,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: child,
    );
  }
}

/// Dialog, DESIGN.md §4: scrim, card r24 padding 24, icon tile 56
/// (errorSoft/error), title, message, stacked full-width buttons.
Future<void> showDkDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  required String primaryLabel,
  required VoidCallback onPrimary,
  String? secondaryLabel,
  VoidCallback? onSecondary,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierColor: context.dkColors.scrim,
    barrierLabel: title,
    pageBuilder: (context, _, _) => DkDialogView(
      icon: icon,
      title: title,
      message: message,
      primaryLabel: primaryLabel,
      onPrimary: onPrimary,
      secondaryLabel: secondaryLabel,
      onSecondary: onSecondary,
    ),
  );
}

/// The dialog's card (no route or scrim): used by [showDkDialog] and
/// directly by the showcase and goldens. Buttons pop the current route
/// first, then run their action.
class DkDialogView extends StatelessWidget {
  /// Creates a dialog card.
  const new({
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.popOnAction = true,
    super.key,
  });

  /// Icon in the error tile.
  final IconData icon;

  /// Title.
  final String title;

  /// Message.
  final String message;

  /// Primary button label.
  final String primaryLabel;

  /// Primary action.
  final VoidCallback onPrimary;

  /// Secondary button label.
  final String? secondaryLabel;

  /// Secondary action.
  final VoidCallback? onSecondary;

  /// Pop the dialog route before running an action (false in previews).
  final bool popOnAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final text = context.dkText;
    final spacing = context.dkSpacing;
    final sizes = context.dkSizes;
    void close(VoidCallback action) {
      if (popOnAction) Navigator.of(context).pop();
      action();
    }

    final secondary = secondaryLabel;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing.s24),
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              padding: EdgeInsets.all(spacing.s24),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(context.dkRadii.xl),
                boxShadow: context.dkElevation.e3,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: spacing.s20,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: ExcludeSemantics(
                        child: Container(
                          width: sizes.dialogIconTile,
                          height: sizes.dialogIconTile,
                          decoration: BoxDecoration(
                            color: colors.errorSoft,
                            borderRadius: BorderRadius.circular(
                              context.dkRadii.lg,
                            ),
                          ),
                          child: Icon(
                            icon,
                            size: sizes.dialogIcon,
                            color: colors.error,
                          ),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: spacing.s8,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: text.titleDialog.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          message,
                          style: text.bodyMd.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: spacing.s8,
                      children: [
                        DkButton(
                          label: primaryLabel,
                          expand: true,
                          onPressed: () => close(onPrimary),
                        ),
                        if (secondary != null && onSecondary != null)
                          DkButton(
                            label: secondary,
                            expand: true,
                            variant: DkButtonVariant.secondary,
                            onPressed: () => close(onSecondary!),
                          ),
                      ],
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
