import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/domain/entities/trip_rules.dart';
import 'package:driver_diary/features/trips/presentation/models/trip_form.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fixtures.dart';

TripFormResult validate(TripFormInput input) =>
    validateTripForm(input, zone: kz, id: 'new-id');

void main() {
  final complete = TripFormInput(
    day: referenceDay,
    start: (hour: 8, minute: 10),
    end: (hour: 8, minute: 32),
    amountText: '2400',
    commissionText: '360',
  );

  test('a complete form becomes a trip in the driver zone', () {
    final result = validate(complete);

    expect(
      (result as TripFormValid).trip,
      Trip(
        id: 'new-id',
        start: at(8, 10),
        end: at(8, 32),
        amount: 2400,
        payment: PaymentMethod.card,
        commission: 360,
      ),
    );
  });

  test('empty form: every field says what is missing', () {
    final result = validate(TripFormInput(day: referenceDay));

    expect((result as TripFormInvalid).errors, {
      TripField.start: 'Укажите время начала',
      TripField.end: 'Укажите время окончания',
      TripField.amount: 'Укажите сумму',
      TripField.commission: 'Укажите комиссию',
    });
  });

  test('an end time before the start means the next day', () {
    final input = TripFormInput(
      day: referenceDay,
      start: (hour: 23, minute: 50),
      end: (hour: 0, minute: 20),
      amountText: '3200',
      commissionText: '480',
    );

    expect(input.endsNextDay, isTrue);
    final trip = (validate(input) as TripFormValid).trip;
    expect(trip.end, at(0, 20, day: 2));
    expect(kz.dayOf(trip.start), referenceDay);
  });

  test('equal start and end is an error, not a 24h trip', () {
    final input = TripFormInput(
      day: referenceDay,
      start: (hour: 9, minute: 0),
      end: (hour: 9, minute: 0),
      amountText: '1000',
      commissionText: '0',
    );

    expect(input.endsNextDay, isFalse);
    expect((validate(input) as TripFormInvalid).errors, {
      TripField.end: 'Окончание должно быть позже начала',
    });
  });

  test('business rules use the shared messages', () {
    final input = TripFormInput(
      day: referenceDay,
      start: (hour: 8, minute: 10),
      end: (hour: 8, minute: 32),
      amountText: '0',
      commissionText: '360',
    );

    expect((validate(input) as TripFormInvalid).errors, {
      TripField.amount: 'Сумма должна быть больше нуля',
      TripField.commission: 'Комиссия не может быть больше суммы',
    });
  });

  test('non-numeric money is rejected', () {
    final input = TripFormInput(
      day: referenceDay,
      start: (hour: 8, minute: 10),
      end: (hour: 8, minute: 32),
      amountText: '2 400.5',
      commissionText: '360',
    );

    expect(
      (validate(input) as TripFormInvalid).errors[TripField.amount],
      'Введите целое число тенге',
    );
  });

  test('money rules apply before the times are picked', () {
    final input = TripFormInput(
      day: referenceDay,
      amountText: '1000',
      commissionText: '1500',
    );

    expect(
      (validate(input) as TripFormInvalid).errors[TripField.commission],
      'Комиссия не может быть больше суммы',
    );
  });
}
