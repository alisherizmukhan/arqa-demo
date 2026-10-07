import 'package:driver_diary/features/trips/domain/entities/trip.dart';

/// How the Day screen orders its trips. [timeAscending] is the default.
enum TripOrder {
  timeAscending,
  timeDescending,
  amountDescending,
  amountAscending;

  /// [trips] in this order. Ties (same start or same amount) keep start
  /// order, then id, so the list never jumps between rebuilds.
  List<Trip> sort(List<Trip> trips) {
    int byStart(Trip a, Trip b) {
      final start = a.start.compareTo(b.start);
      return start != 0 ? start : a.id.compareTo(b.id);
    }

    int compare(Trip a, Trip b) => switch (this) {
      timeAscending => byStart(a, b),
      timeDescending => byStart(b, a),
      amountDescending => switch (b.amount.compareTo(a.amount)) {
        0 => byStart(a, b),
        final order => order,
      },
      amountAscending => switch (a.amount.compareTo(b.amount)) {
        0 => byStart(a, b),
        final order => order,
      },
    };

    return [...trips]..sort(compare);
  }
}
