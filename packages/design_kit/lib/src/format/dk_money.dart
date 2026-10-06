/// Money formatting for display: integer tenge only, e.g. `3 315 ₸`.
///
/// Groups are separated by a no-break space (U+00A0), as in the Russian
/// locale, and the sign is a no-break space away from the number, so a figure
/// never wraps across lines. Negative values use the minus sign (U+2212).
abstract final class DkMoney {
  /// No-break space used between digit groups and before the currency sign.
  static const String nbsp = ' ';

  /// Tenge sign.
  static const String currency = '₸';

  static const String _minus = '−';

  /// Formats [amount] (whole tenge) as `3 315 ₸`.
  static String format(int amount) => '${formatNumber(amount)}$nbsp$currency';

  /// Formats [amount] with digit grouping but without the currency sign.
  static String formatNumber(int amount) {
    final digits = amount.abs().toString();
    final buffer = StringBuffer(amount < 0 ? _minus : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(nbsp);
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
