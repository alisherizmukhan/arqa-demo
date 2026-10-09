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

  static String _two(int value) => value.toString().padLeft(2, '0');
}
