import 'package:design_kit/src/format/dk_grouped_text.dart';
import 'package:design_kit/src/format/dk_money.dart';
import 'package:design_kit/src/format/dk_money_input.dart';
import 'package:design_kit/src/theme/dk_context.dart';
import 'package:design_kit/src/tokens/dk_colors.dart';
import 'package:design_kit/src/tokens/dk_dimensions.dart';
import 'package:design_kit/src/tokens/dk_icons.dart';
import 'package:design_kit/src/tokens/dk_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _FieldState { normal, focused, error, disabled }

/// Prefix icon: textTertiary; `error` with the border and label (mockup 08,
/// DESIGN.md §4).
Color _prefixColor(DkColors colors, _FieldState state) =>
    state == _FieldState.error ? colors.error : colors.textTertiary;

/// Label → field frame → helper or error row, DESIGN.md §4 (DkTextField).
class _FieldShell extends StatelessWidget {
  const new({
    required this.label,
    required this.state,
    required this.child,
    this.helper,
    this.errorText,
  });

  final String label;
  final _FieldState state;
  final Widget child;
  final String? helper;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final text = context.dkText;
    final sizes = context.dkSizes;
    final spacing = context.dkSpacing;

    final (borderColor, borderWidth) = switch (state) {
      _FieldState.normal => (colors.border, sizes.fieldBorder),
      _FieldState.focused => (colors.accent, sizes.fieldBorderFocused),
      _FieldState.error => (colors.error, sizes.fieldBorderFocused),
      _FieldState.disabled => (colors.divider, sizes.fieldBorder),
    };
    final labelColor = switch (state) {
      _FieldState.focused => colors.accent,
      _FieldState.error => colors.error,
      _ => colors.textSecondary,
    };
    final message = errorText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: text.label.copyWith(color: labelColor)),
        SizedBox(height: spacing.s8),
        Container(
          constraints: BoxConstraints(minHeight: sizes.fieldHeight),
          // 16 minus the border: 15 at 1 px, 14 at 2 px, so text never jumps.
          padding: EdgeInsets.symmetric(horizontal: spacing.s16 - borderWidth),
          alignment: AlignmentDirectional.centerStart,
          decoration: BoxDecoration(
            color: state == _FieldState.disabled
                ? colors.surfaceMuted
                : colors.surface,
            borderRadius: BorderRadius.circular(context.dkRadii.md),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: state == _FieldState.focused
                ? [
                    BoxShadow(
                      color: colors.accentSoft,
                      spreadRadius: sizes.focusRing,
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
        if (message != null || helper != null) ...[
          SizedBox(height: spacing.s6),
          DkFieldMessage(text: message ?? helper!, isError: message != null),
        ],
      ],
    );
  }
}

/// The line under a field (or under a row of fields): a `caption` helper in
/// textTertiary, or an error with the circle-alert icon (`captionStrong`,
/// error), DESIGN.md §4. Money inside renders with the wide group gaps.
class DkFieldMessage extends StatelessWidget {
  /// Creates a helper (or, with [isError], an error) line.
  const new({required this.text, this.isError = false, super.key});

  /// The message.
  final String text;

  /// Error styling with the icon.
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final textTheme = context.dkText;
    final spacing = context.dkSpacing;
    return Padding(
      padding: EdgeInsetsDirectional.only(start: spacing.s4),
      child: isError
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  DkIcons.alert,
                  size: context.dkSizes.iconInline,
                  color: colors.error,
                ),
                SizedBox(width: spacing.s6),
                Expanded(
                  child: DkGroupedText(
                    text,
                    style: textTheme.captionStrong.copyWith(
                      color: colors.error,
                    ),
                  ),
                ),
              ],
            )
          : DkGroupedText(
              text,
              style: textTheme.caption.copyWith(color: colors.textTertiary),
            ),
    );
  }
}

/// Text field, DESIGN.md §4: default / focused (2 px accent + 4 px
/// accentSoft ring) / error (2 px error + icon row) / disabled. Min height 56.
///
/// [DkTextField.money] is the money variant (`moneyL`, «₸» suffix, digits
/// grouped with U+202F while typing). The time variant is [DkTimeField].
class DkTextField extends StatefulWidget {
  /// Creates a text field.
  const new({
    required this.label,
    required this.controller,
    this.helper,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.trailing,
    this.style,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.obscureText = false,
    this.autofillHints,
    super.key,
  });

  /// Money variant. Pair it with a [DkMoneyEditingController].
  const new money({
    required this.label,
    required DkMoneyEditingController this.controller,
    this.helper,
    this.errorText,
    this.trailing,
    this.hint,
    this.textInputAction,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    super.key,
  }) : prefixIcon = null,
       obscureText = false,
       autofillHints = null,
       suffix = DkMoney.currency,
       style = null,
       keyboardType = TextInputType.number,
       inputFormatters = const [DkMoneyInputFormatter()];

  /// Visible label; also the accessible name.
  final String label;

  /// Text controller.
  final TextEditingController controller;

  /// Helper below the field (`caption`, textTertiary).
  final String? helper;

  /// Error below the field; replaces [helper] and turns the field red.
  final String? errorText;

  /// Leading icon (20, textTertiary; `error` in the error state).
  final IconData? prefixIcon;

  /// Trailing unit, e.g. «₸» (20/700, textTertiary).
  final String? suffix;

  /// Trailing widget, e.g. `DkBadge('+1 день')`.
  final Widget? trailing;

  /// Input text style (default `body`; money: `moneyL`).
  final TextStyle? style;

  /// Placeholder.
  final String? hint;

  /// Keyboard type.
  final TextInputType? keyboardType;

  /// Input formatters.
  final List<TextInputFormatter>? inputFormatters;

  /// Keyboard action.
  final TextInputAction? textInputAction;

  /// Whether the field is interactive.
  final bool enabled;

  /// Focus on first build.
  final bool autofocus;

  /// External focus node (e.g. for "validate on blur").
  final FocusNode? focusNode;

  /// Change handler.
  final ValueChanged<String>? onChanged;

  /// Keyboard action pressed (Enter).
  final ValueChanged<String>? onSubmitted;

  /// Hide the text (passwords).
  final bool obscureText;

  /// Autofill hints (login, password).
  final Iterable<String>? autofillHints;

  @override
  State<DkTextField> createState() => _DkTextFieldState();
}

class _DkTextFieldState extends State<DkTextField> {
  FocusNode? _ownFocusNode;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(DkTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_onFocusChange);
      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final text = context.dkText;
    final sizes = context.dkSizes;
    final isMoney =
        widget.inputFormatters?.any((f) => f is DkMoneyInputFormatter) ?? false;
    final state = !widget.enabled
        ? _FieldState.disabled
        : widget.errorText != null
        ? _FieldState.error
        : _focusNode.hasFocus
        ? _FieldState.focused
        : _FieldState.normal;
    final base = widget.style ?? (isMoney ? text.moneyL : text.body);

    return MergeSemantics(
      child: _FieldShell(
        label: widget.label,
        state: state,
        helper: widget.helper,
        errorText: widget.errorText,
        child: Row(
          children: [
            if (widget.prefixIcon case final icon?) ...[
              Icon(
                icon,
                size: sizes.iconField,
                color: _prefixColor(colors, state),
              ),
              SizedBox(width: context.dkSpacing.s10),
            ],
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                autofocus: widget.autofocus,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                inputFormatters: widget.inputFormatters,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                obscureText: widget.obscureText,
                enableSuggestions: !widget.obscureText,
                autocorrect: !widget.obscureText,
                autofillHints: widget.autofillHints,
                cursorColor: colors.accent,
                style: base.copyWith(
                  color: widget.enabled
                      ? colors.textPrimary
                      : colors.textSecondary,
                ),
                decoration: InputDecoration.collapsed(
                  hintText: widget.hint,
                  hintStyle: base.copyWith(color: colors.textTertiary),
                ),
              ),
            ),
            if (widget.suffix case final suffix?)
              Text(
                suffix,
                style: _suffixStyle.copyWith(color: colors.textTertiary),
              ),
            if (widget.trailing case final trailing?) ...[
              SizedBox(width: context.dkSpacing.s8),
              // Its own node, so a trailing button (the password eye) stays
              // reachable by screen readers instead of merging into the field.
              Semantics(container: true, child: trailing),
            ],
          ],
        ),
      ),
    );
  }
}

/// «₸» suffix of money fields: 20/700 (DESIGN.md §4).
final TextStyle _suffixStyle = dkTextStyle(
  size: 20,
  lineHeight: 28,
  weight: FontWeight.w700,
);

/// Time field (the DkTextField time variant, DESIGN.md §4): clock prefix,
/// `fieldTime` style, opens a picker via [onTap]. With a [trailing] badge the
/// clock icon is hidden so both fit one line; at large text scales the badge
/// moves below the time (the field grows), the time itself never wraps.
class DkTimeField extends StatelessWidget {
  /// Creates a time field.
  const new({
    required this.label,
    required this.value,
    required this.onTap,
    required this.emptyValueLabel,
    this.helper,
    this.errorText,
    this.trailing,
    this.enabled = true,
    this.invalid = false,
    this.placeholder = '––:––',
    super.key,
  });

  /// Visible label.
  final String label;

  /// `08:10`, or null when not picked yet.
  final String? value;

  /// Opens the time picker.
  final VoidCallback onTap;

  /// Helper below the field.
  final String? helper;

  /// Error below the field.
  final String? errorText;

  /// Trailing widget, e.g. `DkBadge('+1 день')`.
  final Widget? trailing;

  /// Whether the field is interactive.
  final bool enabled;

  /// Error styling without a message under this field: for a row of fields
  /// that shares one `DkFieldMessage` (DESIGN.md §5.7, time row).
  final bool invalid;

  /// Shown when [value] is null.
  final String placeholder;

  /// Accessible reading of an empty value.
  final String emptyValueLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final sizes = context.dkSizes;
    final spacing = context.dkSpacing;
    final state = !enabled
        ? _FieldState.disabled
        : errorText != null || invalid
        ? _FieldState.error
        : _FieldState.normal;
    final shown = value;

    return Semantics(
      button: true,
      enabled: enabled,
      label:
          '$label, ${shown ?? emptyValueLabel}'
          '${errorText == null ? '' : ', $errorText'}',
      excludeSemantics: true,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(context.dkRadii.md),
        child: _FieldShell(
          label: label,
          state: state,
          helper: helper,
          errorText: errorText,
          child: Row(
            children: [
              // With a trailing badge («+1 день») the clock icon is hidden so
              // time and badge fit one line at 360 dp (approved deviation).
              if (trailing == null) ...[
                Icon(
                  DkIcons.time,
                  size: sizes.iconField,
                  color: _prefixColor(colors, state),
                ),
                SizedBox(width: spacing.s10),
              ],
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: spacing.s8,
                  runSpacing: spacing.s4,
                  children: [
                    Text(
                      shown ?? placeholder,
                      style: context.dkText.fieldTime.copyWith(
                        color: shown == null
                            ? colors.textTertiary
                            : enabled
                            ? colors.textPrimary
                            : colors.textSecondary,
                      ),
                    ),
                    ?trailing,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small accent label, e.g. «+1 день». DESIGN.md §4: min 24 high, radius sm.
class DkBadge extends StatelessWidget {
  /// Creates a badge.
  const new(this.text, {super.key});

  /// Badge text.
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    return Container(
      constraints: BoxConstraints(minHeight: context.dkSpacing.s24),
      padding: EdgeInsets.symmetric(horizontal: context.dkSpacing.s8),
      // No `alignment`: it would make the badge fill the line it sits on
      // (and push itself below the time). The 24 line height centres it.
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(context.dkRadii.sm),
      ),
      child: Text(
        text,
        style: context.dkText.badge.copyWith(color: colors.accent),
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

  /// Visible label.
  final String label;

  /// Optional icon (20).
  final IconData? icon;
}

/// Segmented control, DESIGN.md §4: track `segmentTrack` (r14, padding 4),
/// thumb `segmentThumb` (r10, shadow `thumb`) sliding in 200 ms ease-out.
/// A null [onChanged] disables it.
class DkSegmentedControl<T> extends StatelessWidget {
  /// Creates a segmented control.
  const new({
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.label,
    super.key,
  });

  /// Options.
  final List<DkSegment<T>> segments;

  /// Selected value.
  final T selected;

  /// Selection handler; null disables the control.
  final ValueChanged<T>? onChanged;

  /// Optional label above, styled like a field label.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final spacing = context.dkSpacing;
    final sizes = context.dkSizes;
    final gap = spacing.s4;
    final index = segments.indexWhere((s) => s.value == selected);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final track = Container(
      constraints: BoxConstraints(minHeight: sizes.segmentedHeight),
      padding: EdgeInsets.all(spacing.s4),
      decoration: BoxDecoration(
        color: colors.segmentTrack,
        borderRadius: BorderRadius.circular(context.dkRadii.segmentTrack),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width =
              (constraints.maxWidth - gap * (segments.length - 1)) /
              segments.length;
          return Stack(
            children: [
              if (index >= 0)
                AnimatedPositioned(
                  duration: reduceMotion ? Duration.zero : DkMotion.segment,
                  curve: DkMotion.segmentCurve,
                  left: index * (width + gap),
                  width: width,
                  top: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.segmentThumb,
                      borderRadius: BorderRadius.circular(
                        context.dkRadii.segment,
                      ),
                      boxShadow: context.dkElevation.thumb,
                    ),
                  ),
                ),
              Row(
                spacing: gap,
                children: [
                  for (final segment in segments)
                    Expanded(
                      child: _SegmentButton<T>(
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
        },
      ),
    );

    final caption = label;
    if (caption == null) return track;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          caption,
          style: context.dkText.label.copyWith(color: colors.textSecondary),
        ),
        SizedBox(height: spacing.s8),
        track,
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
    final text = context.dkText;
    final enabled = onTap != null;
    final color = isSelected && enabled
        ? colors.textPrimary
        : colors.textSecondary;
    // Unselected: 16/600 (DESIGN.md §4) = bodyStrong at weight 600.
    final style = isSelected
        ? text.bodyStrong
        : text.bodyStrong.copyWith(
            fontWeight: FontWeight.w600,
            fontVariations: const [FontVariation.weight(600)],
          );

    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: isSelected,
      enabled: enabled,
      label: segment.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.dkRadii.segment),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                context.dkSizes.segmentedHeight - context.dkSpacing.s4 * 2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (segment.icon case final icon?) ...[
                Icon(icon, size: context.dkSizes.iconField, color: color),
                SizedBox(width: context.dkSpacing.s8),
              ],
              Flexible(
                child: Text(
                  segment.label,
                  textAlign: TextAlign.center,
                  style: style.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
