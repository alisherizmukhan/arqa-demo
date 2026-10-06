/// Money formatting, DESIGN.md §3: integer tenge, digit groups and the
/// currency separated by U+202F (narrow no-break space), negatives with the
/// real minus U+2212. `3315 → "3 315 ₸"`, `-585 → "−585 ₸"`.
///
/// Rendering widens every U+202F to ~0.25 em (`DkGroupedText`), so the gaps
/// look like the mockups while the string itself stays U+202F.
abstract final class DkMoney {
  /// Narrow no-break space (U+202F): digit groups and before `₸`.
  static const String separator = ' ';

  /// Tenge sign.
  static const String currency = '₸';

  /// Minus sign (U+2212) for negative amounts (commission in the summary).
  static const String minus = '−';

  /// `3 315 ₸`.
  static String format(int amount) =>
      '${formatNumber(amount)}$separator$currency';

  /// `3 315` (no currency).
  static String formatNumber(int amount) {
    final digits = amount.abs().toString();
    return (amount < 0 ? minus : '') + groupDigits(digits);
  }

  /// Groups a string of ASCII digits in threes: `"2400" → "2 400"`.
  static String groupDigits(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(separator);
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// The ASCII digits of [text] (drops separators, spaces, `₸`, …).
  static String digitsOf(String text) =>
      String.fromCharCodes(text.codeUnits.where((c) => c >= 48 && c <= 57));

  /// Parses user input (`"2 400"`, `"2400 ₸"`) to an int; null when empty.
  static int? parse(String text) {
    final digits = digitsOf(text);
    return digits.isEmpty ? null : int.parse(digits);
  }
}
