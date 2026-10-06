import 'package:design_kit/src/theme/dk_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Text field with a visible label above it, helper text and an error line
/// below. 56dp tall. For pickers, set [readOnly] and handle [onTap].
class DkTextField extends StatelessWidget {
  /// Creates a text field.
  const new({
    required this.label,
    this.controller,
    this.hint,
    this.helperText,
    this.errorText,
    this.suffixText,
    this.prefixIcon,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.enabled = true,
    this.focusNode,
    super.key,
  });

  /// Visible label; also the accessible name.
  final String label;

  /// Text controller.
  final TextEditingController? controller;

  /// Placeholder (never a substitute for [label]).
  final String? hint;

  /// Persistent helper text below the field.
  final String? helperText;

  /// Error shown below the field; replaces [helperText].
  final String? errorText;

  /// Trailing unit, e.g. `₸`.
  final String? suffixText;

  /// Leading icon.
  final IconData? prefixIcon;

  /// Keyboard type, e.g. `TextInputType.number`.
  final TextInputType? keyboardType;

  /// Keyboard action button.
  final TextInputAction? textInputAction;

  /// Input formatters, e.g. digits only.
  final List<TextInputFormatter>? inputFormatters;

  /// Change handler.
  final ValueChanged<String>? onChanged;

  /// Tap handler (for read-only picker fields).
  final VoidCallback? onTap;

  /// Disallow typing (value set via [onTap]).
  final bool readOnly;

  /// Whether the field is interactive.
  final bool enabled;

  /// Focus node.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final text = context.dkText;
    final sizes = context.dkSizes;
    final radius = BorderRadius.circular(context.dkRadii.md);

    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: color, width: width),
    );

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.label.copyWith(color: colors.textPrimary)),
          SizedBox(height: context.dkSpacing.s8),
          TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            onTap: onTap,
            readOnly: readOnly,
            enabled: enabled,
            style: text.body.copyWith(color: colors.textPrimary),
            cursorColor: colors.accent,
            decoration: InputDecoration(
              hintText: hint,
              helperText: helperText,
              errorText: errorText,
              errorMaxLines: 3,
              helperMaxLines: 3,
              suffixText: suffixText,
              prefixIcon: prefixIcon == null
                  ? null
                  : Icon(prefixIcon, size: sizes.iconNav),
              filled: true,
              fillColor: enabled ? colors.surface : colors.surfaceMuted,
              constraints: BoxConstraints(minHeight: sizes.buttonHeight),
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.dkSpacing.s16,
                vertical: context.dkSpacing.s16,
              ),
              hintStyle: text.body.copyWith(color: colors.textSecondary),
              helperStyle: text.label.copyWith(color: colors.textSecondary),
              errorStyle: text.label.copyWith(color: colors.error),
              suffixStyle: text.body.copyWith(color: colors.textSecondary),
              prefixIconColor: colors.textSecondary,
              border: border(colors.border, sizes.fieldBorder),
              enabledBorder: border(colors.border, sizes.fieldBorder),
              disabledBorder: border(colors.divider, sizes.fieldBorder),
              focusedBorder: border(colors.accent, sizes.fieldBorderFocused),
              errorBorder: border(colors.error, sizes.fieldBorderFocused),
              focusedErrorBorder: border(
                colors.error,
                sizes.fieldBorderFocused,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One option of a [DkSegmentedControl].
@immutable
class DkSegment<T> {
  /// Creates a segment.
  const new({required this.value, required this.label, this.icon});

  /// Value reported when selected.
  final T value;

  /// Visible label (always shown, icons are supplementary).
  final String label;

  /// Optional icon.
  final IconData? icon;
}

/// Single-choice selector, e.g. payment method `Наличные | Карта`.
///
/// Segments are full 56dp buttons with an 8dp gap (Flutter's `SegmentedButton`
/// draws a 40dp box regardless of `minimumSize`).
class DkSegmentedControl<T> extends StatelessWidget {
  /// Creates a segmented control.
  const new({
    required this.label,
    required this.segments,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  /// Visible group label.
  final String label;

  /// Options.
  final List<DkSegment<T>> segments;

  /// Currently selected value.
  final T selected;

  /// Selection handler; null disables the control.
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final spacing = context.dkSpacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Own node, sized to the text: read as the group's caption.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Semantics(
            container: true,
            child: Text(
              label,
              style: context.dkText.label.copyWith(color: colors.textPrimary),
            ),
          ),
        ),
        SizedBox(height: spacing.s8),
        Row(
          spacing: spacing.s8,
          children: [
            for (final segment in segments)
              Expanded(
                child: _SegmentButton(
                  segment: segment,
                  isSelected: segment.value == selected,
                  onTap: onChanged == null
                      ? null
                      : () => onChanged!(segment.value),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SegmentButton<T> extends StatelessWidget {
  const new({
    required this.segment,
    required this.isSelected,
    required this.onTap,
  });

  final DkSegment<T> segment;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final sizes = context.dkSizes;
    final enabled = onTap != null;
    final foreground = !enabled
        ? colors.textSecondary
        : isSelected
        ? colors.onAccent
        : colors.textPrimary;
    final background = isSelected
        ? (enabled ? colors.accent : colors.surfaceMuted)
        : colors.surface;

    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: isSelected,
        inMutuallyExclusiveGroup: true,
        enabled: enabled,
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.dkRadii.md),
            side: BorderSide(
              color: isSelected && enabled ? colors.accent : colors.border,
              width: sizes.fieldBorder,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: sizes.buttonHeight,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.dkSpacing.s12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (segment.icon != null) ...[
                      Icon(
                        segment.icon,
                        size: sizes.iconField,
                        color: foreground,
                      ),
                      SizedBox(width: context.dkSpacing.s8),
                    ],
                    Flexible(
                      child: Text(
                        segment.label,
                        overflow: TextOverflow.ellipsis,
                        style: context.dkText.bodyStrong.copyWith(
                          color: foreground,
                        ),
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
