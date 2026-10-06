import 'package:meta/meta.dart';

/// How the passenger paid.
enum PaymentMethod { cash, card }

/// A trip. Money is whole tenge (`int`); [start]/[end] are UTC instants.
@immutable
final class Trip {
  const new({
    required this.id,
    required this.start,
    required this.end,
    required this.amount,
    required this.payment,
    required this.commission,
  });

  /// Client-generated UUID v4; doubles as the idempotency key.
  final String id;
  final DateTime start;
  final DateTime end;
  final int amount;
  final PaymentMethod payment;
  final int commission;

  int get net => amount - commission;

  /// Everything but the id; instants compare by moment, not by notation.
  bool hasSamePayload(Trip other) =>
      start.isAtSameMomentAs(other.start) &&
      end.isAtSameMomentAs(other.end) &&
      amount == other.amount &&
      payment == other.payment &&
      commission == other.commission;

  Trip withId(String newId) => Trip(
    id: newId,
    start: start,
    end: end,
    amount: amount,
    payment: payment,
    commission: commission,
  );

  @override
  bool operator ==(Object other) =>
      other is Trip && other.id == id && hasSamePayload(other);

  @override
  int get hashCode =>
      Object.hash(id, start.toUtc(), end.toUtc(), amount, payment, commission);

  @override
  String toString() =>
      'Trip($id, ${start.toUtc().toIso8601String()}, $amount ${payment.name})';
}
