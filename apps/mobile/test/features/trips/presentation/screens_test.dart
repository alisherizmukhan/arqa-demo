import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/presentation/models/trip_form.dart';
import 'package:driver_diary/features/trips/presentation/screens/add_trip_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/fixtures.dart';

void main() {
  String money(int amount) => DkMoney.format(amount);

  /// RichText contents (grouped money is drawn as rich text).
  List<String> texts(WidgetTester tester) => tester
      .widgetList<RichText>(find.byType(RichText))
      .map((t) => t.text.toPlainText())
      .toList();

  group('Day', () {
    testWidgets('renders the reference day (DESIGN.md §5.1)', (tester) async {
      useDevice(tester, phone390);
      await pumpDiary(tester, FakeTripsRepository([t1, t2]));
      await selectDay(tester, referenceDay);

      expect(find.text('Дневник смен'), findsOneWidget);
      expect(find.text('1 октября 2026'), findsOneWidget);
      expect(find.text('Четверг'), findsOneWidget);
      final all = texts(tester);
      expect(all, contains(money(3315)));
      expect(all, contains(money(3900)));
      expect(all, contains(DkMoney.format(-585)));
      expect(all, containsAll(['Наличные · 38%', 'Карта · 62%']));
      expect(find.text('2 поездки · 37 мин'), findsOneWidget);
      expect(find.text('08:10 – 08:32'), findsOneWidget);
      expect(find.text('22 мин · Карта'), findsOneWidget);
      expect(all, contains('комиссия ${money(360)}'));
      expect(find.byType(DkFab), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('empty day: empty state, no summary, no FAB', (tester) async {
      useDevice(tester, phone390);
      await pumpDiary(tester, FakeTripsRepository());
      await tester.pumpAndSettle(); // the loading FAB animates out

      expect(find.text('Сегодня'), findsOneWidget);
      expect(find.text('За этот день поездок нет'), findsOneWidget);
      expect(find.byType(DkSummaryCard), findsNothing);
      expect(find.byType(DkFab), findsNothing);

      await tester.tap(find.text('Добавить поездку'));
      await tester.pumpAndSettle();
      expect(find.text('Новая поездка'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('loading: skeleton with the FAB', (tester) async {
      useDevice(tester, phone390);
      final repository = FakeTripsRepository()..onLoad = (_) => pending();
      await pumpDiary(tester, repository);
      await tester.pump();

      expect(find.byType(DkSkeleton), findsWidgets);
      expect(find.byType(DkFab), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('error: no FAB; «Повторить» loads the day', (tester) async {
      useDevice(tester, phone390);
      final repository = FakeTripsRepository([t1, t2])
        ..onLoad = (_) async => const Err(NetworkFailure());
      await pumpDiary(tester, repository, now: at(12, 0)); // today = Oct 1
      await tester.pumpAndSettle();

      expect(find.text('Не удалось загрузить данные'), findsOneWidget);
      expect(find.byType(DkFab), findsNothing);

      repository.onLoad = null;
      await tester.tap(find.text('Повторить'));
      await tester.pump();
      await tester.pump();
      expect(texts(tester), contains(money(3315)));
      expect(find.byType(DkFab), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('a failed refresh keeps the data and shows a snackbar', (
      tester,
    ) async {
      useDevice(tester, phone390);
      final repository = FakeTripsRepository([t1, t2]);
      await pumpDiary(tester, repository);
      await selectDay(tester, referenceDay);

      repository.onLoad = (_) async => const Err(NetworkFailure());
      await tester.fling(find.text('Поездки'), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1)); // indicator + reload
      await tester.pump(const Duration(seconds: 1));

      expect(texts(tester), contains(money(3315)));
      expect(find.byType(DkSnackbarView), findsOneWidget);
      expect(find.text('Не удалось загрузить данные'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('a new trip: its start day, highlighted ~2 s, snackbar 3 s', (
      tester,
    ) async {
      useDevice(tester, phone390);
      final repository = FakeTripsRepository([t1]);
      await pumpDiary(tester, repository);
      await selectDay(tester, referenceDay);

      await tester.tap(find.byType(DkFab));
      await tester.pumpAndSettle();
      expect(find.text('1 октября 2026'), findsOneWidget); // form subtitle
      await pickTime(tester, 'Начало', 23, 50);
      await pickTime(tester, 'Окончание', 0, 20);
      expect(find.text('+1 день'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), '3000');
      await tester.enterText(find.byType(TextField).at(1), '450');
      await tester.tap(find.text('Сохранить'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Новая поездка'), findsNothing);
      final tile = tester
          .widgetList<DkTripTile>(find.byType(DkTripTile))
          .singleWhere((t) => t.timeRange == '23:50 – 00:20');
      expect(tile.highlighted, isTrue);
      expect(tile.endsNextDay, isTrue);
      expect(find.text('Поездка добавлена'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      expect(
        tester
            .widgetList<DkTripTile>(find.byType(DkTripTile))
            .any((t) => t.highlighted),
        isFalse,
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Поездка добавлена'), findsNothing);
      await disposeApp(tester);
    });
  });

  group('Add trip', () {
    Future<FakeTripsRepository> openForm(
      WidgetTester tester, {
      TripFormInput? input,
      FakeTripsRepository? repository,
    }) async {
      useDevice(tester, phone390);
      final repo = repository ?? FakeTripsRepository();
      await pumpDiary(
        tester,
        repo,
        home: AddTripScreen(
          day: input?.day ?? referenceDay,
          initialInput: input,
        ),
      );
      await tester.pump();
      return repo;
    }

    final valid = TripFormInput(
      day: referenceDay,
      start: (hour: 8, minute: 10),
      end: (hour: 8, minute: 32),
      amountText: '2400',
      commissionText: '360',
    );

    Finder saveButton() => find.ancestor(
      of: find.text('Сохранить'),
      matching: find.byType(DkButton),
    );

    bool saveEnabled(WidgetTester tester) =>
        tester.widget<DkButton>(saveButton()).onPressed != null;

    testWidgets('modal chrome, helpers and duration (§5.6)', (tester) async {
      await openForm(tester, input: valid);

      expect(find.bySemanticsLabel('Закрыть'), findsOneWidget);
      expect(find.text('1 октября 2026'), findsOneWidget);
      expect(find.text('Длительность: 22 мин'), findsOneWidget);
      expect(find.text('Сколько заплатил пассажир'), findsOneWidget);
      expect(texts(tester), contains('На руки с поездки: ${money(2040)}'));
      await disposeApp(tester);
    });

    testWidgets('Save on an empty form: «Заполните поле», Save disabled, '
        'no request', (tester) async {
      final repository = await openForm(tester);

      await tester.tap(find.text('Сохранить'));
      await tester.pump();

      // One message under the time row, one under each money field.
      expect(find.text('Заполните поле'), findsNWidgets(3));
      expect(saveEnabled(tester), isFalse);
      expect(repository.created, isEmpty);
      await disposeApp(tester);
    });

    testWidgets('errors appear when a field loses focus, not while typing', (
      tester,
    ) async {
      await openForm(tester);

      await tester.tap(find.byType(TextField).at(0));
      await tester.enterText(find.byType(TextField).at(0), '0');
      await tester.pump();
      expect(find.text('Сумма должна быть больше 0'), findsNothing);
      expect(saveEnabled(tester), isTrue);

      await tester.tap(find.byType(TextField).at(1));
      await tester.pump();
      expect(find.text('Сумма должна быть больше 0'), findsOneWidget);
      expect(find.text('Заполните поле'), findsNothing, reason: 'untouched');
      expect(saveEnabled(tester), isFalse);

      // Back to the amount: its error clears; the commission, left empty,
      // now shows its own.
      await tester.enterText(find.byType(TextField).at(0), '2400');
      await tester.pump();
      expect(find.text('Сумма должна быть больше 0'), findsNothing);
      expect(find.text('Заполните поле'), findsOneWidget);
      expect(saveEnabled(tester), isFalse);

      await tester.enterText(find.byType(TextField).at(1), '360');
      await tester.pump();
      expect(find.text('Заполните поле'), findsNothing);
      expect(saveEnabled(tester), isTrue);
      await disposeApp(tester);
    });

    testWidgets('end before start beyond 12 h: one error under the time row', (
      tester,
    ) async {
      await openForm(
        tester,
        input: TripFormInput(
          day: referenceDay,
          start: (hour: 9, minute: 20),
          end: (hour: 9, minute: 5),
          amountText: '1000',
          commissionText: '0',
        ),
      );
      await tester.tap(find.text('Сохранить'));
      await tester.pump();

      expect(find.text('Окончание должно быть позже начала'), findsOneWidget);
      expect(find.text('+1 день'), findsNothing);
      final fields = tester.widgetList<DkTimeField>(find.byType(DkTimeField));
      expect(fields.map((f) => f.invalid), [false, true]);
      await disposeApp(tester);
    });

    testWidgets('midnight: badge and the §5.10 helper', (tester) async {
      await openForm(
        tester,
        input: TripFormInput(
          day: referenceDay.addDays(-1),
          start: (hour: 23, minute: 50),
          end: (hour: 0, minute: 20),
          amountText: '3000',
          commissionText: '450',
        ),
      );

      expect(find.text('+1 день'), findsOneWidget);
      expect(
        find.text(
          'Окончание 1 октября · 30 мин. '
          'Поездка попадёт в 30 сентября — день начала.',
        ),
        findsOneWidget,
      );
      await disposeApp(tester);
    });

    testWidgets('saving disables every input', (tester) async {
      final repository = FakeTripsRepository()..onCreate = (_) => pending();
      await openForm(tester, input: valid, repository: repository);

      await tester.tap(find.text('Сохранить'));
      await tester.pump();

      expect(find.text('Сохраняем…'), findsOneWidget);
      for (final field in tester.widgetList<DkTimeField>(
        find.byType(DkTimeField),
      )) {
        expect(field.enabled, isFalse);
      }
      for (final field in tester.widgetList<DkTextField>(
        find.byType(DkTextField),
      )) {
        expect(field.enabled, isFalse);
      }
      expect(
        tester
            .widget<DkSegmentedControl<PaymentMethod>>(
              find.byType(DkSegmentedControl<PaymentMethod>),
            )
            .onChanged,
        isNull,
      );
      await disposeApp(tester);
    });

    testWidgets('no connection: snackbar above the bottom bar; «Повторить» '
        'resends the same id', (tester) async {
      final repository = FakeTripsRepository()
        ..onCreate = (_) async => const Err(NetworkFailure());
      await openForm(tester, input: valid, repository: repository);

      await tester.tap(find.text('Сохранить'));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Нет связи. Повторим отправку — поездка не задвоится.'),
        findsOneWidget,
      );
      final snack = tester.getRect(find.byType(DkSnackbarView));
      final bar = tester.getRect(find.byType(DkBottomBar));
      expect(bar.top - snack.bottom, closeTo(12, 0.5));
      expect(saveEnabled(tester), isTrue);

      repository.onCreate = null;
      await tester.tap(find.text('Повторить'));
      await tester.pump();
      await tester.pump();
      expect(repository.created.map((t) => t.id).toSet(), hasLength(1));
      expect(find.byType(DkSnackbarView), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('server 422 for a field shows under that field', (
      tester,
    ) async {
      final repository = FakeTripsRepository()
        ..onCreate = (_) async => const Err(
          ValidationFailure(
            code: 'commission_exceeds_amount',
            message: 'commission must not exceed amount',
            field: 'commission',
          ),
        );
      await openForm(tester, input: valid, repository: repository);

      await tester.tap(find.text('Сохранить'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Комиссия не может быть больше суммы'), findsOneWidget);
      expect(saveEnabled(tester), isFalse);
      await tester.enterText(find.byType(TextField).at(1), '300');
      await tester.pump();
      expect(find.text('Комиссия не может быть больше суммы'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('409: dialog; «Сохранить как новую поездку» sends a new id', (
      tester,
    ) async {
      final repository = FakeTripsRepository()
        ..onCreate = (_) async => const Err(ConflictFailure());
      await openForm(tester, input: valid, repository: repository);

      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(
        find.text('Эта поездка уже сохранена с другими данными'),
        findsOneWidget,
      );
      expect(
        find.text('Обновите день, чтобы увидеть сохранённую версию.'),
        findsOneWidget,
      );

      repository.onCreate = null;
      await tester.tap(find.text('Сохранить как новую поездку'));
      await tester.pumpAndSettle();
      final ids = repository.created.map((t) => t.id).toList();
      expect(ids, hasLength(2));
      expect(ids.toSet(), hasLength(2));
      await disposeApp(tester);
    });

    testWidgets('409: «Оставить сохранённую» closes the form and reloads', (
      tester,
    ) async {
      useDevice(tester, phone390);
      final repository = FakeTripsRepository()
        ..onCreate = (_) async => const Err(ConflictFailure());
      await pumpDiary(tester, repository);
      await tester.pump();
      await tester.tap(find.text('Добавить поездку'));
      await tester.pumpAndSettle();
      await pickTime(tester, 'Начало', 8, 10);
      await pickTime(tester, 'Окончание', 8, 32);
      await tester.enterText(find.byType(TextField).at(0), '2400');
      await tester.enterText(find.byType(TextField).at(1), '360');
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      final loads = repository.loads;

      await tester.tap(find.text('Оставить сохранённую'));
      await tester.pumpAndSettle();

      expect(find.text('Новая поездка'), findsNothing);
      expect(repository.loads, greaterThan(loads));
      await disposeApp(tester);
    });
  });
}
