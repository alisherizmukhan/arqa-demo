import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/features/trips/presentation/models/trip_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/fixtures.dart';

void main() {
  final valid = TripFormInput(
    day: referenceDay,
    start: (hour: 8, minute: 10),
    end: (hour: 8, minute: 32),
    amountText: '2400',
    commissionText: '360',
  );

  Future<FakeTripsRepository> openForm(
    WidgetTester tester, {
    TripFormInput? input,
    FakeTripsRepository? repository,
  }) async {
    useDevice(tester, phone390);
    final repo = repository ?? FakeTripsRepository();
    await pumpFormOverHost(tester, repo, input: input);
    expect(find.text('Новая поездка'), findsOneWidget);
    return repo;
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Сохранить'));
    await tester.pump();
    await tester.pump();
  }

  bool formOpen() => find.text('Новая поездка').evaluate().isNotEmpty;

  group('offline: automatic resend (§5.9)', () {
    const offline = 'Нет связи. Повторим отправку — поездка не задвоится.';

    testWidgets('snackbar after the first failure; resends at 2, 4, 8, 30, '
        '30 s with the same id', (tester) async {
      final repository = FakeTripsRepository()
        ..onCreate = (_) async => const Err(NetworkFailure());
      await openForm(tester, input: valid, repository: repository);

      await save(tester);
      expect(repository.created, hasLength(1));
      expect(find.text(offline), findsOneWidget);

      for (final (seconds, total) in [
        (2, 2),
        (4, 3),
        (8, 4),
        (30, 5),
        (30, 6),
      ]) {
        await tester.pump(Duration(seconds: seconds) - Durations.short1);
        expect(repository.created, hasLength(total - 1), reason: 'too early');
        await tester.pump(Durations.short1);
        expect(repository.created, hasLength(total));
      }
      expect(repository.created.map((t) => t.id).toSet(), hasLength(1));
      expect(find.byType(DkSnackbarView), findsOneWidget, reason: 'one');
      await disposeApp(tester);
    });

    testWidgets('a background resend keeps the form editable', (tester) async {
      var calls = 0;
      final repository = FakeTripsRepository()
        ..onCreate = (_) {
          calls++;
          return calls == 1
              ? Future.value(const Err(NetworkFailure()))
              : pending();
        };
      await openForm(tester, input: valid, repository: repository);

      await save(tester);
      await tester.pump(const Duration(seconds: 2));
      expect(calls, 2, reason: 'the resend is in flight');

      expect(find.text('Сохранить'), findsOneWidget);
      expect(find.text('Сохраняем…'), findsNothing);
      for (final field in tester.widgetList<DkTextField>(
        find.byType(DkTextField),
      )) {
        expect(field.enabled, isTrue);
      }
      await disposeApp(tester);
    });

    testWidgets('«Повторить» resends now and restarts the schedule', (
      tester,
    ) async {
      final repository = FakeTripsRepository()
        ..onCreate = (_) async => const Err(NetworkFailure());
      await openForm(tester, input: valid, repository: repository);

      await save(tester); // 1
      await tester.pump(const Duration(seconds: 2)); // 2
      await tester.pump(const Duration(seconds: 4)); // 3
      expect(repository.created, hasLength(3));

      await tester.tap(find.text('Повторить'));
      await tester.pump();
      await tester.pump();
      expect(repository.created, hasLength(4));

      // Next resend after 2 s again, not 8 s.
      await tester.pump(const Duration(seconds: 2));
      expect(repository.created, hasLength(5));
      expect(repository.created.map((t) => t.id).toSet(), hasLength(1));
      await disposeApp(tester);
    });

    testWidgets('success on a resend closes the snackbar and the form', (
      tester,
    ) async {
      final repository = FakeTripsRepository()
        ..onCreate = (_) async => const Err(NetworkFailure());
      await openForm(tester, input: valid, repository: repository);

      await save(tester);
      repository.onCreate = null; // back online
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(formOpen(), isFalse);
      expect(find.byType(DkSnackbarView), findsNothing);
      expect(repository.trips, hasLength(1));
      expect(find.textContaining('host: Trip'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets(
      'editing after a failure stops resending; Save sends a new id',
      (tester) async {
        final repository = FakeTripsRepository()
          ..onCreate = (_) async => const Err(NetworkFailure());
        await openForm(tester, input: valid, repository: repository);

        await save(tester);
        await tester.enterText(find.byType(TextField).at(1), '300');
        await tester.pump();
        expect(find.byType(DkSnackbarView), findsNothing);

        await tester.pump(const Duration(minutes: 1));
        expect(repository.created, hasLength(1), reason: 'no resends');

        repository.onCreate = null;
        await save(tester);
        await tester.pumpAndSettle();
        final ids = repository.created.map((t) => t.id).toList();
        expect(ids, hasLength(2));
        expect(ids.toSet(), hasLength(2));
        expect(repository.created.last.commission, 300);
        await disposeApp(tester);
      },
    );

    testWidgets('closing the form stops resending', (tester) async {
      final repository = FakeTripsRepository()
        ..onCreate = (_) async => const Err(NetworkFailure());
      await openForm(tester, input: valid, repository: repository);

      await save(tester);
      await tester.tap(find.bySemanticsLabel('Закрыть'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Закрыть').last); // confirm discard
      await tester.pumpAndSettle();
      expect(formOpen(), isFalse);

      await tester.pump(const Duration(minutes: 1));
      expect(repository.created, hasLength(1));
      expect(find.byType(DkSnackbarView), findsNothing);
      await disposeApp(tester);
    });
  });

  group('only connection errors, timeouts and 5xx are resent', () {
    const offline = 'Нет связи. Повторим отправку — поездка не задвоится.';

    for (final (name, failure) in [
      ('timeout', const NetworkFailure('receiveTimeout')),
      ('503', const ServerFailure(statusCode: 503)),
      ('500', const ServerFailure(statusCode: 500)),
    ]) {
      testWidgets('$name: resent with the same id', (tester) async {
        final repository = FakeTripsRepository()
          ..onCreate = (_) async => Err(failure);
        await openForm(tester, input: valid, repository: repository);

        await save(tester);
        await tester.pump(const Duration(seconds: 2));
        expect(repository.created, hasLength(2));
        expect(repository.created.map((t) => t.id).toSet(), hasLength(1));
        expect(find.text('Повторить'), findsOneWidget);
        await disposeApp(tester);
      });
    }

    for (final (name, failure, expected) in [
      (
        '422',
        const ValidationFailure(
          code: 'commission_exceeds_amount',
          message: 'commission must not exceed amount',
          field: 'commission',
        ),
        'Комиссия не может быть больше суммы',
      ),
      (
        '409',
        const ConflictFailure(),
        'Эта поездка уже сохранена с другими данными',
      ),
      (
        '400',
        const ServerFailure(statusCode: 400),
        'Что-то пошло не так. Попробуйте ещё раз.',
      ),
      (
        '401',
        const ServerFailure(statusCode: 401),
        'Что-то пошло не так. Попробуйте ещё раз.',
      ),
    ]) {
      testWidgets('$name: never resent, no «Нет связи»', (tester) async {
        final repository = FakeTripsRepository()
          ..onCreate = (_) async => Err(failure);
        await openForm(tester, input: valid, repository: repository);

        await save(tester);
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text(expected), findsOneWidget);
        expect(find.text(offline), findsNothing);
        expect(find.text('Повторить'), findsNothing);

        await tester.pump(const Duration(minutes: 2));
        expect(repository.created, hasLength(1));
        await disposeApp(tester);
      });
    }
  });

  group('closing with unsaved input (§5.6)', () {
    testWidgets('an untouched form closes at once', (tester) async {
      await openForm(tester);

      await tester.tap(find.bySemanticsLabel('Закрыть'));
      await tester.pumpAndSettle();
      expect(formOpen(), isFalse);
      await disposeApp(tester);
    });

    testWidgets('✕ asks; «Продолжить ввод» keeps the input', (tester) async {
      await openForm(tester);
      await tester.enterText(find.byType(TextField).at(0), '2400');
      await tester.pump();

      await tester.tap(find.bySemanticsLabel('Закрыть'));
      await tester.pumpAndSettle();
      expect(find.text('Закрыть без сохранения?'), findsOneWidget);

      await tester.tap(find.text('Продолжить ввод'));
      await tester.pumpAndSettle();
      expect(formOpen(), isTrue);
      expect(
        tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
        '2 400',
      );
      await disposeApp(tester);
    });

    testWidgets('system back asks too; «Закрыть» discards', (tester) async {
      await openForm(tester);
      await tester.tap(find.text('Наличные'));
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Закрыть без сохранения?'), findsOneWidget);

      await tester.tap(find.text('Закрыть').last);
      await tester.pumpAndSettle();
      expect(formOpen(), isFalse);
      expect(find.text('host: null'), findsOneWidget);
      await disposeApp(tester);
    });
  });

  testWidgets('Save stays pinned right above the keyboard', (tester) async {
    await openForm(tester, input: valid);

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();

    final bar = tester.getRect(find.byType(DkBottomBar));
    expect(bar.bottom, closeTo(844 - 300, 0.5));
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });
  testWidgets('the offline snackbar follows Save when the keyboard closes', (
    tester,
  ) async {
    final repository = FakeTripsRepository()
      ..onCreate = (_) async => const Err(NetworkFailure());
    await openForm(tester, input: valid, repository: repository);
    double gap() =>
        tester.getRect(find.byType(DkBottomBar)).top -
        tester.getRect(find.byType(DkSnackbarView)).bottom;

    // Saved while the keyboard is still open: the error arrives before it
    // has gone down.
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();
    await save(tester);
    expect(gap(), closeTo(12, 0.5));

    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump();
    final bar = tester.getRect(find.byType(DkBottomBar));
    expect(bar.bottom, 844);
    expect(gap(), closeTo(12, 0.5));
    await disposeApp(tester);
  });
}
