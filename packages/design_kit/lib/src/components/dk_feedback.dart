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
/// area + 16; the form passes "12 above the bottom bar").
///
/// success: compact, bottom-left. With [fabSize] (the FAB at the bottom
/// right) it sits **beside** the FAB when it fits (12 dp gap), otherwise —
/// narrow screens, large text — full width **above** the FAB. Never overlaps.
DkSnackbarHandle showDkSnackbar(
  BuildContext context, {
  required String message,
  DkSnackTone tone = DkSnackTone.info,
  String? actionLabel,
  VoidCallback? onAction,
  double? bottom,
  Size? fabSize,
  Duration? duration,
}) {
  _current?.close();
  final overlay = Overlay.of(context);
  // The entry lives on the navigator's overlay, above routes pushed later
  // (dialogs, pickers). Show it only while its own screen is on top; the
  // overlay rebuilds its entries whenever routes change.
  final route = ModalRoute.of(context);
  late final DkSnackbarHandle handle;
  final entry = OverlayEntry(
    builder: (context) {
      if (route != null && !route.isCurrent) return const SizedBox.shrink();
      final spacing = context.dkSpacing;
      final safeBottom = MediaQuery.paddingOf(context).bottom;
      final compact = tone == DkSnackTone.success;
      var offset = bottom ?? safeBottom + spacing.s16;
      var right = compact ? null : spacing.s16;
      var maxWidth = double.infinity;
      if (compact && fabSize != null) {
        final width = MediaQuery.sizeOf(context).width;
        final beside =
            width - spacing.s16 - spacing.s12 - fabSize.width - spacing.s16;
        if (dkSuccessSnackbarWidth(context, message) <= beside) {
          maxWidth = beside;
        } else {
          right = spacing.s16;
          offset = safeBottom + spacing.s16 + fabSize.height + spacing.s12;
        }
      }
      return Positioned(
        left: spacing.s16,
        right: right,
        bottom: offset,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
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

/// Natural width of the compact success snackbar for [message] (paddings +
/// icon + gap + text at the current text scale).
double dkSuccessSnackbarWidth(BuildContext context, String message) {
  final spacing = context.dkSpacing;
  final painter = TextPainter(
    text: TextSpan(text: message, style: context.dkText.label),
    textDirection: TextDirection.ltr,
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return spacing.s14 +
      context.dkSizes.iconAction +
      spacing.s8 +
      width +
      spacing.s16;
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

/// The dialog never grows wider than this (tablets, landscape).
const double _dialogMaxWidth = 400;

/// Dialog, DESIGN.md §4: scrim, card r24 padding 24, centred icon tile 56
/// (errorSoft/error), centred title and message, stacked full-width buttons.
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _dialogMaxWidth),
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
                      Center(
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
                        spacing: spacing.s8,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              style: text.titleDialog.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            message,
                            textAlign: TextAlign.center,
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
      ),
    );
  }
}
