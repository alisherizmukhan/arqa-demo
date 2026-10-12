/// Language-neutral formatting, DESIGN.md §3: clock times, time ranges and
/// split percentages. Dates, durations and plurals depend on the language,
/// so the app formats them with its localizations.
abstract final class DkFormat {
  /// `08:05` (24 h).
  static String clock(int hour, int minute) => '${_two(hour)}:${_two(minute)}';

  /// `08:10 – 08:32` (en dash with spaces).
  static String timeRange(String start, String end) => '$start – $end';

  /// Cash/card shares in whole percent that sum to 100 (largest remainder).
  /// Null when there is no revenue (the split is hidden then).
  static ({int cash, int card})? splitPercent(int cash, int card) {
    final total = cash + card;
    if (total <= 0) return null;
    final cashExact = cash * 100 / total;
    var cashPct = cashExact.floor();
    var cardPct = (card * 100 / total).floor();
    final missing = 100 - cashPct - cardPct;
    if (missing > 0) {
      final cashRemainder = cashExact - cashExact.floor();
      final cardRemainder = card * 100 / total - cardPct;
      if (cashRemainder >= cardRemainder) {
        cashPct += missing;
      } else {
        cardPct += missing;
      }
    }
    return (cash: cashPct, card: cardPct);
  }

  /// A distance, DESIGN.md §9: under 1 000 m in metres (`850 м`), else in
  /// kilometres with one decimal and a comma (`7,4 км`). The units come from
  /// the app's localizations; a no-break space keeps number and unit together.
  static String distance(
    int metres, {
    required String metresUnit,
    required String kilometresUnit,
  }) {
    if (metres < 1000) return '$metres$_noBreak$metresUnit';
    final tenths = (metres / 100).round();
    return '${tenths ~/ 10},${tenths % 10}$_noBreak$kilometresUnit';
  }

  /// Tenge per kilometre, rounded to a whole tenge (`324`); null without a
  /// distance.
  static int? perKilometre(int amount, int metres) =>
      metres <= 0 ? null : (amount * 1000 / metres).round();

  /// U+00A0 between a number and its unit.
  static const String _noBreak = '\u00A0';

  static String _two(int value) => value.toString().padLeft(2, '0');
}
