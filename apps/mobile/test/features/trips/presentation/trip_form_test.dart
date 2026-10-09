import 'package:driver_diary/core/l10n/l10n.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/domain/entities/trip_rules.dart';
import 'package:driver_diary/features/trips/presentation/error_messages.dart';
import 'package:driver_diary/features/trips/presentation/models/trip_form.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fixtures.dart';

TripFormResult validate(TripFormInput input) =>
    validateTripForm(input, zone: kz, id: 'new-id');

final AppLocalizations _ru = lookupAppLocalizations(const Locale('ru'));

/// The form's errors as the Russian texts shown under the fields.
Map<TripField, String> texts(TripFormResult result) => {
  for (final MapEntry(:key, :value)
      in (result as TripFormInvalid).errors.entries)
    key: validationMessage(_ru, value),
};

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

  test('empty form: every field says «Заполните поле»', () {
    final result = validate(TripFormInput(day: referenceDay));

    expect(texts(result), {
      TripField.start: 'Заполните поле',
      TripField.end: 'Заполните поле',
      TripField.amount: 'Заполните поле',
      TripField.commission: 'Заполните поле',
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
    expect(input.duration, const Duration(minutes: 30));
    expect(input.endDay, referenceDay.addDays(1));
    final trip = (validate(input) as TripFormValid).trip;
    expect(trip.end, at(0, 20, day: 2));
    expect(kz.dayOf(trip.start), referenceDay);
  });

  test('an end before the start that makes the trip > 12 h is an error', () {
    // Mockup 08: 09:20 → 09:05 would be 23 h 45 min.
    final input = TripFormInput(
      day: referenceDay,
      start: (hour: 9, minute: 20),
      end: (hour: 9, minute: 5),
      amountText: '1000',
      commissionText: '0',
    );

    expect(texts(validate(input)), {
      TripField.end: 'Окончание должно быть позже начала',
    });
  });

  test('exactly 12 h is allowed, 12 h 1 min is not', () {
    TripFormInput ending(int hour, int minute) => TripFormInput(
      day: referenceDay,
      start: (hour: 8, minute: 0),
      end: (hour: hour, minute: minute),
      amountText: '1000',
      commissionText: '0',
    );

    expect(validate(ending(20, 0)), isA<TripFormValid>());
    expect(validate(ending(20, 1)), isA<TripFormInvalid>());
  });

  test('equal start and end means 24 h: an error', () {
    final input = TripFormInput(
      day: referenceDay,
      start: (hour: 9, minute: 0),
      end: (hour: 9, minute: 0),
      amountText: '1000',
      commissionText: '0',
    );

    expect(input.endsNextDay, isTrue);
    expect(texts(validate(input)), {
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

    expect(texts(validate(input)), {
      TripField.amount: 'Сумма должна быть больше 0',
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
      texts(validate(input))[TripField.amount],
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
      texts(validate(input))[TripField.commission],
      'Комиссия не может быть больше суммы',
    );
  });

  test('the amount rule does not wait for the commission', () {
    final input = TripFormInput(day: referenceDay, amountText: '0');

    expect(
      texts(validate(input))[TripField.amount],
      'Сумма должна быть больше 0',
    );
    expect(texts(validate(input))[TripField.commission], 'Заполните поле');
  });

  test('net is shown only for valid sums; grouped input is parsed', () {
    TripFormInput sums(String amount, String commission) => TripFormInput(
      day: referenceDay,
      amountText: amount,
      commissionText: commission,
    );

    expect(sums('2 400', '360').net, 2040);
    expect(sums('2400', '').net, isNull);
    expect(sums('1000', '1500').net, isNull);
    expect(sums('0', '0').net, isNull);
  });
}
