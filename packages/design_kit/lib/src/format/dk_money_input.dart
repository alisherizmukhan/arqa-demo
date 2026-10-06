import 'package:design_kit/src/format/dk_grouped_text.dart';
import 'package:design_kit/src/format/dk_money.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Keeps money input grouped with U+202F while typing: digits only, at most
/// [maxDigits], leading zeros dropped (a single `0` stays so "0" can be
/// validated). The caret keeps its place among the *digits*, so inserting,
/// deleting and pasting never land it inside a gap.
///
/// Deleting a separator alone (Backspace right after a gap, Delete right
/// before one) removes the neighbouring digit instead — otherwise the gap
/// would just reappear and the key would do nothing.
class DkMoneyInputFormatter extends TextInputFormatter {
  /// Creates the formatter.
  const new({this.maxDigits = 8});

  /// Maximum number of digits.
  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = DkMoney.digitsOf(newValue.text);
    var caretDigits = _digitsBefore(newValue.text, newValue.selection.end);

    final oldDigits = DkMoney.digitsOf(oldValue.text);
    final removedOnlySeparator =
        digits == oldDigits && newValue.text.length < oldValue.text.length;
    if (removedOnlySeparator) {
      final isBackspace =
          newValue.selection.end < oldValue.selection.end ||
          oldValue.selection.end > newValue.selection.end;
      final at = _digitsBefore(oldValue.text, newValue.selection.end);
      if (isBackspace && at > 0) {
        digits = digits.replaceRange(at - 1, at, '');
        caretDigits = at - 1;
      } else if (!isBackspace && at < digits.length) {
        digits = digits.replaceRange(at, at + 1, '');
        caretDigits = at;
      }
    }

    if (digits.length > maxDigits) return oldValue;
    final stripped = digits.replaceFirst(RegExp('^0+(?=.)'), '');
    caretDigits -= digits.length - stripped.length;
    digits = stripped;

    final text = DkMoney.groupDigits(digits);
    final offset = _offsetAfterDigits(
      text,
      caretDigits.clamp(0, digits.length),
    );
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

/// Controller of the money field: draws the grouped text with the same
/// spans as `DkMoneyText`, and keeps a collapsed caret off the inside of a
/// gap: arrow keys and taps step over the separator in one move.
class DkMoneyEditingController extends TextEditingController {
  /// Creates a controller, optionally with an initial [amount].
  new({int? amount})
    : super(text: amount == null ? '' : DkMoney.groupDigits('$amount'));

  /// The amount typed so far, or null when the field is empty.
  int? get amount => DkMoney.parse(text);

  @override
  set value(TextEditingValue newValue) {
    super.value = _skipSeparator(value, newValue);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    required bool withComposing,
    TextStyle? style,
  }) {
    final effective = style ?? const TextStyle();
    return TextSpan(
      style: effective,
      children: dkGroupedSpans(text, effective),
    );
  }

  /// A collapsed caret right after a separator (between the gap and the next
  /// digit) is moved: forward past the next digit when moving right, back in
  /// front of the gap otherwise. The two positions around a gap are one stop.
  static TextEditingValue _skipSeparator(
    TextEditingValue old,
    TextEditingValue next,
  ) {
    final selection = next.selection;
    if (!selection.isValid || !selection.isCollapsed) return next;
    final offset = selection.baseOffset;
    final text = next.text;
    if (offset <= 0 || offset > text.length) return next;
    if (text[offset - 1] != DkMoney.separator) return next;
    final movingRight =
        old.text == text &&
        old.selection.isCollapsed &&
        old.selection.baseOffset == offset - 1;
    final target = movingRight && offset < text.length
        ? offset + 1
        : offset - 1;
    return next.copyWith(selection: TextSelection.collapsed(offset: target));
  }
}

int _digitsBefore(String text, int offset) {
  final end = offset.clamp(0, text.length);
  return DkMoney.digitsOf(text.substring(0, end)).length;
}

/// Offset just after the [count]-th digit (0 → start). Lands in front of a
/// gap, never between a gap and a digit.
int _offsetAfterDigits(String text, int count) {
  if (count <= 0) return 0;
  var seen = 0;
  for (var i = 0; i < text.length; i++) {
    final c = text.codeUnitAt(i);
    if (c >= 48 && c <= 57) {
      seen++;
      if (seen == count) return i + 1;
    }
  }
  return text.length;
}
