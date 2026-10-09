import 'package:driver_diary/core/time/calendar_day.dart';
import 'package:driver_diary/core/time/driver_zone.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/domain/repositories/trips_repository.dart';
import 'package:mocktail/mocktail.dart';

const DriverZone kz = DriverZone.kazakhstan;
final referenceDay = CalendarDay(2026, 10, 1);

/// Instant at local [hour]:[minute] (+05:00) on 2026-10-[day].
DateTime at(int hour, int minute, {int day = 1}) =>
    kz.instantAt(CalendarDay(2026, 10, day), hour, minute);

/// The assignment's reference trips for 2026-10-01.
final t1 = Trip(
  id: 't1',
  start: at(8, 10),
  end: at(8, 32),
  amount: 2400,
  payment: PaymentMethod.card,
  commission: 360,
);
final t2 = Trip(
  id: 't2',
  start: at(9, 5),
  end: at(9, 20),
  amount: 1500,
  payment: PaymentMethod.cash,
  commission: 225,
);

/// user_2's reference trips on 2026-10-01 (seed ids u2-t1, u2-t2).
final u2t1 = Trip(
  id: 'u2-t1',
  start: at(10, 0),
  end: at(10, 40),
  amount: 3000,
  payment: PaymentMethod.card,
  commission: 450,
);
final u2t2 = Trip(
  id: 'u2-t2',
  start: at(12, 15),
  end: at(12, 35),
  amount: 1800,
  payment: PaymentMethod.cash,
  commission: 270,
);

Trip trip({
  String id = 'trip-1',
  DateTime? start,
  Duration duration = const Duration(minutes: 20),
  int amount = 2000,
  PaymentMethod payment = PaymentMethod.card,
  int commission = 300,
}) {
  final s = start ?? at(10, 0);
  return Trip(
    id: id,
    start: s,
    end: s.add(duration),
    amount: amount,
    payment: payment,
    commission: commission,
  );
}

class MockTripsRepository extends Mock implements TripsRepository;

void registerFallbacks() {
  registerFallbackValue(referenceDay);
  registerFallbackValue(kz);
  registerFallbackValue(t1);
}
