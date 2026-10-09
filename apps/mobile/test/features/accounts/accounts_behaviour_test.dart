import 'dart:io';

import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/config/app_config.dart';
import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/l10n/locale_providers.dart';
import 'package:driver_diary/features/admin/presentation/screens/admin_screen.dart';
import 'package:driver_diary/features/auth/presentation/providers/session_providers.dart';
import 'package:driver_diary/features/auth/presentation/screens/login_screen.dart';
import 'package:driver_diary/features/menu/presentation/screens/menu_screen.dart';
import 'package:driver_diary/features/trips/presentation/screens/day_screen.dart';
import 'package:driver_diary/features/withdrawals/domain/entities/withdrawal.dart';
import 'package:driver_diary/features/withdrawals/presentation/screens/withdraw_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/account_scenarios.dart';
import '../../helpers/app_harness.dart';
import '../../helpers/fakes.dart';
import '../../helpers/fixtures.dart';

Future<void> _signIn(WidgetTester tester, String login, String password) async {
  await tester.enterText(find.byType(TextField).at(0), login);
  await tester.enterText(find.byType(TextField).at(1), password);
  await tester.pump();
  await tester.tap(find.text('Войти'));
  await tester.pump();
  await tester.pump();
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  group('session', () {
    testWidgets('no saved token: the login screen', (tester) async {
      await pumpDiary(tester, FakeTripsRepository(), user: null);
      await tester.pump();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Вход'), findsOneWidget);
    });

    testWidgets('a driver signs in → Day screen; the token is stored', (
      tester,
    ) async {
      final tokens = MemoryTokenStore();
      await pumpDiary(
        tester,
        FakeTripsRepository([t1, t2]),
        user: null,
        tokens: tokens,
      );
      await tester.pump();

      await _signIn(tester, 'user_1', 'password_1');

      expect(dayScreen, findsOneWidget);
      expect(tokens.token, 'token-user_1');
    });

    testWidgets('an admin signs in → Admin screen', (tester) async {
      await pumpDiary(tester, FakeTripsRepository(), user: null);
      await tester.pump();

      await _signIn(tester, 'admin', 'admin');

      expect(find.byType(AdminScreen), findsOneWidget);
      expect(dayScreen, findsNothing);
    });

    testWidgets('wrong password: the error under the field, cleared on edit', (
      tester,
    ) async {
      await pumpDiary(tester, FakeTripsRepository(), user: null);
      await tester.pump();

      await _signIn(tester, 'user_1', 'nope');
      expect(find.text('Неверный логин или пароль'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(1), 'nope2');
      await tester.pump();
      expect(find.text('Неверный логин или пароль'), findsNothing);
    });

    testWidgets('429 and a blocked account have their own texts', (
      tester,
    ) async {
      final auth = FakeAuthRepository()
        ..onLogin = (login, _) async => login == 'many'
            ? const Err(RateLimitedFailure())
            : const Err(ForbiddenFailure(code: 'account_disabled'));
      await pumpDiary(tester, FakeTripsRepository(), user: null, auth: auth);
      await tester.pump();

      await _signIn(tester, 'many', 'x');
      expect(
        find.text('Слишком много попыток. Попробуйте через 15 минут.'),
        findsOneWidget,
      );
      await _signIn(tester, 'blocked', 'x');
      expect(
        find.text('Аккаунт заблокирован. Обратитесь в парк.'),
        findsOneWidget,
      );
    });

    testWidgets('offline: the «Нет связи» snackbar', (tester) async {
      final auth = FakeAuthRepository()
        ..onLogin = (_, _) async => const Err(NetworkFailure());
      await pumpDiary(tester, FakeTripsRepository(), user: null, auth: auth);
      await tester.pump();

      await _signIn(tester, 'user_1', 'password_1');

      expect(find.text('Нет связи. Проверьте интернет.'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets(
      'Enter on the login moves to the password; Enter there signs in',
      (tester) async {
        final auth = FakeAuthRepository();
        await pumpDiary(tester, FakeTripsRepository(), user: null, auth: auth);
        await tester.pump();

        await tester.enterText(find.byType(TextField).at(0), 'user_1');
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pump();
        final password = tester.widget<TextField>(find.byType(TextField).at(1));
        expect(password.focusNode!.hasFocus, isTrue);

        await tester.enterText(find.byType(TextField).at(1), 'password_1');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
        await tester.pump();

        expect(auth.logins, ['user_1']);
        expect(dayScreen, findsOneWidget);
      },
    );

    testWidgets('a 401 anywhere: back to login with «Сессия завершена»', (
      tester,
    ) async {
      final tokens = MemoryTokenStore('token-user_1');
      await pumpDiary(tester, FakeTripsRepository([t1]), tokens: tokens);
      await tester.tap(iconButton('Меню'));
      await tester.pumpAndSettle();
      expect(find.byType(MenuScreen), findsOneWidget);

      await containerOf(tester).read(sessionProvider.notifier).expire();
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(MenuScreen), findsNothing);
      expect(find.text('Сессия завершена. Войдите снова.'), findsOneWidget);
      expect(tokens.token, isNull);
      await disposeApp(tester);
    });

    testWidgets('a saved token the server no longer accepts → login', (
      tester,
    ) async {
      await pumpDiary(
        tester,
        FakeTripsRepository(),
        auth: FakeAuthRepository(), // nobody signed in on the "server"
      );
      await tester.pump();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Сессия завершена. Войдите снова.'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('offline at start: «Повторить» checks the session again', (
      tester,
    ) async {
      var online = false;
      final auth = FakeAuthRepository(signedIn: driver1)
        ..onMe = () async =>
            online ? const Ok(driver1) : const Err(NetworkFailure());
      await pumpDiary(tester, FakeTripsRepository(), auth: auth);
      await tester.pump();
      expect(find.text('Не удалось загрузить'), findsOneWidget);

      online = true;
      await tester.tap(find.text('Повторить'));
      await tester.pump();
      await tester.pump();

      expect(dayScreen, findsOneWidget);
    });

    testWidgets('logout: confirm, the server call, the login screen', (
      tester,
    ) async {
      final auth = FakeAuthRepository(signedIn: driver1);
      final tokens = MemoryTokenStore('token-user_1');
      await pumpDiary(
        tester,
        FakeTripsRepository(),
        auth: auth,
        tokens: tokens,
      );
      await tester.tap(iconButton('Меню'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Выйти'));
      await tester.pumpAndSettle();
      expect(find.text('Выйти из аккаунта?'), findsOneWidget);

      await tester.tap(find.text('Выйти').last);
      await tester.pumpAndSettle();

      expect(auth.logouts, 1);
      expect(tokens.token, isNull);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Сессия завершена. Войдите снова.'), findsNothing);
    });

    testWidgets('another account after logout never sees cached days', (
      tester,
    ) async {
      final trips = FakeTripsRepository([t1, t2]);
      await pumpDiary(tester, trips, now: at(12, 0));
      await tester.pump();
      final before = trips.loads;

      await containerOf(tester).read(sessionProvider.notifier).signOut();
      await tester.pumpAndSettle();
      await _signIn(tester, 'user_2', 'password_2');
      await tester.pump();

      expect(dayScreen, findsOneWidget);
      expect(trips.loads, greaterThan(before));
    });
  });

  group('language', () {
    testWidgets('the switch on the login screen applies at once and is kept', (
      tester,
    ) async {
      final locales = MemoryLocaleStore('ru');
      await pumpDiary(
        tester,
        FakeTripsRepository(),
        user: null,
        locales: locales,
      );
      await tester.pump();
      expect(find.text('Вход'), findsOneWidget);

      await tester.tap(find.text('Қазақша'));
      await tester.pumpAndSettle();

      expect(find.text('Жүйеге кіру'), findsOneWidget);
      expect(find.text('Логин'), findsOneWidget);
      expect(find.text('Құпиясөз'), findsOneWidget);
      expect(locales.code, 'kk');
    });

    testWidgets('the menu switch changes the Day screen too', (tester) async {
      await pumpDiary(tester, FakeTripsRepository([t1, t2]), now: at(12, 0));
      await tester.tap(iconButton('Меню'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Қазақша'));
      await tester.pumpAndSettle();
      expect(find.text('Мәзір'), findsOneWidget);
      await tester.tap(iconButton('Артқа'));
      await tester.pumpAndSettle();

      expect(find.text('Бүгін'), findsOneWidget);
      expect(find.text('2026\u00A0ж. 1 қазан'), findsOneWidget);
      expect(find.text('Сапарлар'), findsOneWidget);
      expect(find.text('2 сапар · 37 мин'), findsOneWidget);
    });

    for (final (device, expected) in [
      (const Locale('kk', 'KZ'), 'Жүйеге кіру'),
      (const Locale('ru', 'RU'), 'Вход'),
      (const Locale('en', 'US'), 'Вход'),
    ]) {
      test('no saved choice, phone in $device → $expected', () {
        final container = ProviderContainer(
          overrides: [
            localeStoreProvider.overrideWithValue(MemoryLocaleStore()),
            deviceLocalesProvider.overrideWithValue([device]),
          ],
        );
        addTearDown(container.dispose);
        final code = container.read(appLocaleProvider).languageCode;
        expect(code, device.languageCode == 'kk' ? 'kk' : 'ru');
      });
    }
  });

  group('menu', () {
    testWidgets('driver: profile, «Вывод средств» with the balance, version', (
      tester,
    ) async {
      await pumpDiary(tester, FakeTripsRepository(), home: const MenuScreen());
      await _settle(tester);

      expect(find.text('Водитель 1'), findsOneWidget);
      expect(find.text('@user_1 · Водитель'), findsOneWidget);
      expect(find.text('Вывод средств'), findsOneWidget);
      expect(find.text('Доступно 1\u202F815\u202F₸'), findsOneWidget);
      expect(find.text('Версия ${AppConfig.version}'), findsOneWidget);
    });

    testWidgets('admin: no «Вывод средств»', (tester) async {
      await pumpDiary(
        tester,
        FakeTripsRepository(),
        user: adminUser,
        home: const MenuScreen(),
      );
      await _settle(tester);

      expect(find.text('@admin · Администратор'), findsOneWidget);
      expect(find.text('Вывод средств'), findsNothing);
    });

    test('the version in the menu is the pubspec version', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final version = RegExp(
        r'^version: (\S+)\+',
        multiLine: true,
      ).firstMatch(pubspec)!.group(1);
      expect(AppConfig.version, version);
    });
  });

  group('withdraw', () {
    Future<FakeWithdrawalsRepository> open(
      WidgetTester tester, {
      FakeWithdrawalsRepository? withdrawals,
    }) async {
      final repo =
          withdrawals ?? FakeWithdrawalsRepository(items: driverHistory());
      await pumpDiary(
        tester,
        FakeTripsRepository(),
        withdrawals: repo,
        home: const WithdrawScreen(),
      );
      await _settle(tester);
      return repo;
    }

    testWidgets('balance, deductions with U+2212, history with statuses', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('815\u202F₸'), findsWidgets);
      expect(find.text('\u2212585\u202F₸'), findsOneWidget);
      expect(find.text('\u22121\u202F000\u202F₸'), findsOneWidget);
      expect(find.text('Не больше 815\u202F₸'), findsOneWidget);
      expect(find.text('В обработке'), findsOneWidget);
      expect(find.text('Выплачено'), findsOneWidget);
      expect(find.text('Отклонено'), findsOneWidget);
      expect(find.text('Неверные реквизиты'), findsOneWidget);
      expect(find.text('8 октября 2026, 18:05'), findsOneWidget);
    });

    testWidgets('validation: more than available, zero; «Всё» fills', (
      tester,
    ) async {
      await open(tester);

      await tester.enterText(find.byType(TextField), '2000');
      await tester.pump();
      expect(find.text('Сумма больше доступной'), findsOneWidget);
      expect(tapEnabled(tester, 'Вывести'), isFalse);

      await tester.enterText(find.byType(TextField), '0');
      await tester.pump();
      expect(find.text('Сумма должна быть больше 0'), findsOneWidget);

      await tester.tap(find.text('Всё'));
      await tester.pump();
      expect(find.text('Сумма больше доступной'), findsNothing);
      expect(tapEnabled(tester, 'Вывести'), isTrue);
    });

    testWidgets('success: one request, the row highlighted, the snackbar', (
      tester,
    ) async {
      final repo = await open(tester);

      await tester.enterText(find.byType(TextField), '300');
      await tester.pump();
      await tester.tap(find.text('Вывести'));
      await _settle(tester);

      expect(repo.creates, hasLength(1));
      expect(repo.creates.single.amount, 300);
      expect(find.text('Заявка на вывод создана'), findsOneWidget);
      expect(find.text('Не больше 515\u202F₸'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Заявка на вывод создана'), findsNothing);
    });

    testWidgets('offline: snackbar at once, resends with the same id', (
      tester,
    ) async {
      var online = false;
      final repo = FakeWithdrawalsRepository(items: driverHistory());
      repo.onCreate = (id, amount) async {
        if (!online) return const Err(NetworkFailure());
        repo.onCreate = null;
        return await repo.create(id: id, amount: amount);
      };
      await open(tester, withdrawals: repo);

      await tester.enterText(find.byType(TextField), '300');
      await tester.pump();
      await tester.tap(find.text('Вывести'));
      await tester.pump();
      expect(
        find.text('Нет связи. Повторим запрос — деньги не уйдут дважды.'),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 2)); // automatic resend
      await tester.pump();
      online = true;
      await tester.tap(find.text('Повторить'));
      await _settle(tester);

      final ids = {for (final c in repo.creates) c.id};
      expect(repo.creates.length, greaterThanOrEqualTo(3));
      expect(ids, hasLength(1), reason: 'every resend reuses the id');
      expect(repo.items.where((w) => w.id == ids.single), hasLength(1));
      expect(find.text('Заявка на вывод создана'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('editing the amount after a failure gives a new id', (
      tester,
    ) async {
      final repo = FakeWithdrawalsRepository(items: driverHistory())
        ..onCreate = (_, _) async => const Err(NetworkFailure());
      await open(tester, withdrawals: repo);

      await tester.enterText(find.byType(TextField), '300');
      await tester.pump();
      await tester.tap(find.text('Вывести'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '200');
      await tester.pump();
      expect(
        find.text('Нет связи. Повторим запрос — деньги не уйдут дважды.'),
        findsNothing,
      );
      await tester.tap(find.text('Вывести'));
      await tester.pump();

      expect(repo.creates.map((c) => c.amount), [300, 200]);
      expect(repo.creates[0].id, isNot(repo.creates[1].id));
      await disposeApp(tester);
    });

    testWidgets('409: the dialog, then the history reloads', (tester) async {
      final repo = FakeWithdrawalsRepository(items: driverHistory())
        ..onCreate = (_, _) async =>
            const Err(ConflictFailure('conflict', 'withdrawal_conflict'));
      await open(tester, withdrawals: repo);

      await tester.enterText(find.byType(TextField), '300');
      await tester.pump();
      await tester.tap(find.text('Вывести'));
      await tester.pumpAndSettle();

      expect(
        find.text('Эта заявка уже отправлена с другой суммой'),
        findsOneWidget,
      );
      await tester.tap(find.text('Понятно'));
      await tester.pumpAndSettle();
      expect(find.byType(WithdrawScreen), findsOneWidget);
    });

    testWidgets('the server says too much: the field error', (tester) async {
      final repo = FakeWithdrawalsRepository(items: driverHistory())
        ..onCreate = (_, _) async => const Err(
          ValidationFailure(
            code: 'insufficient_funds',
            message: 'm',
            field: 'amount',
          ),
        );
      await open(tester, withdrawals: repo);

      await tester.enterText(find.byType(TextField), '300');
      await tester.pump();
      await tester.tap(find.text('Вывести'));
      await _settle(tester);

      expect(find.text('Сумма больше доступной'), findsOneWidget);
    });

    testWidgets('nothing to withdraw: no field, the button disabled', (
      tester,
    ) async {
      await open(
        tester,
        withdrawals: FakeWithdrawalsRepository(
          cardTotal: 1000,
          commissionTotal: 1300,
        ),
      );

      expect(find.text('Сейчас нечего выводить.'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(tapEnabled(tester, 'Вывести'), isFalse);
      expect(find.text('Заявок на вывод пока не было.'), findsOneWidget);
    });
  });

  group('admin', () {
    Future<FakeWithdrawalsRepository> open(
      WidgetTester tester, {
      AdminTab tab = AdminTab.trips,
      FakeAdminRepository? admin,
      FakeTripsRepository? trips,
    }) async {
      final repo = FakeWithdrawalsRepository(items: adminRequests());
      await pumpDiary(
        tester,
        trips ?? FakeTripsRepository(ownedTrips),
        user: adminUser,
        now: at(12, 0),
        withdrawals: repo,
        admin: admin,
        home: AdminScreen(initialTab: tab),
      );
      await _settle(tester);
      return repo;
    }

    testWidgets(
      'all drivers: the reference totals and a driver line per trip',
      (tester) async {
        await open(tester);

        expect(find.text('7\u202F395\u202F₸'), findsOneWidget);
        expect(find.text('4 поездки · 1 ч 37 мин'), findsOneWidget);
        expect(find.text('Водитель 1'), findsNWidgets(3)); // chip + 2 rows
        expect(find.text('Водитель 2'), findsNWidgets(3));
        expect(find.byType(DkFab), findsNothing);
      },
    );

    testWidgets('one driver: driver_id is sent, no driver lines', (
      tester,
    ) async {
      final trips = FakeTripsRepository(ownedTrips);
      await open(tester, trips: trips);

      await tester.tap(find.text('Водитель 2').first);
      await _settle(tester);

      expect(trips.driverFilters, contains('u2'));
      expect(find.text('4\u202F080\u202F₸'), findsOneWidget);
      expect(find.text('Водитель 2'), findsOneWidget); // the chip only
    });

    testWidgets('approve: the request becomes paid, the snackbar', (
      tester,
    ) async {
      final repo = await open(tester, tab: AdminTab.withdrawals);
      expect(find.text('Водитель 2 · 9 окт., 22:34'), findsOneWidget);

      await tester.tap(find.text('Выплатить').first);
      await _settle(tester);

      expect(repo.decisions, ['a-2:paid']);
      expect(find.text('Отмечено как выплачено'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('reject needs a reason; it is sent trimmed', (tester) async {
      final repo = await open(tester, tab: AdminTab.withdrawals);

      await tester.tap(find.text('Отклонить').first);
      await tester.pumpAndSettle();
      expect(
        find.text('Отклонить заявку на 1\u202F000\u202F₸?'),
        findsOneWidget,
      );
      expect(
        find.text('Водитель 2 увидит причину в истории выводов.'),
        findsOneWidget,
      );
      expect(tapEnabled(tester, 'Отклонить', last: true), isFalse);

      await tester.enterText(find.byType(TextField), '  Неверные реквизиты ');
      await tester.pump();
      await tester.tap(find.text('Отклонить').last);
      await _settle(tester);

      expect(repo.decisions, ['a-2:rejected:Неверные реквизиты']);
      expect(find.text('Заявка отклонена'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets(
      'drivers: balances; block via the sheet; demo accounts say so',
      (tester) async {
        final admin = FakeAdminRepository();
        await open(tester, tab: AdminTab.drivers, admin: admin);
        expect(find.text('@user_2'), findsOneWidget);

        await tester.tap(find.text('Водитель 2'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Заблокировать'));
        await _settle(tester);
        expect(find.text('Водитель заблокирован'), findsOneWidget);
        expect(find.text('@user_2 · заблокирован'), findsOneWidget);

        admin.onSetActive = (_, {required active}) async =>
            const Err(ConflictFailure('demo', 'demo_account_protected'));
        await tester.tap(find.text('Водитель 1'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Заблокировать'));
        await _settle(tester);
        expect(
          find.text(
            'Демо-аккаунт защищён: его нельзя заблокировать или сбросить его '
            'сессии.',
          ),
          findsOneWidget,
        );
        await disposeApp(tester);
      },
    );

    testWidgets('revoke sessions asks first', (tester) async {
      final admin = FakeAdminRepository();
      await open(tester, tab: AdminTab.drivers, admin: admin);

      await tester.tap(find.text('Водитель 2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сбросить все сессии'));
      await tester.pumpAndSettle();
      expect(find.text('Сбросить все сессии?'), findsOneWidget);
      expect(find.text('Водитель выйдет на всех устройствах'), findsOneWidget);

      await tester.tap(find.text('Сбросить'));
      await _settle(tester);
      expect(admin.revoked, ['u2']);
      expect(find.text('Сессии сброшены'), findsOneWidget);
      await disposeApp(tester);
    });
  });

  testWidgets('Day header: the menu button opens the menu', (tester) async {
    await pumpDiary(tester, FakeTripsRepository([t1, t2]));
    expect(find.byType(DayScreen), findsOneWidget);

    await tester.tap(iconButton('Меню'));
    await tester.pumpAndSettle();

    expect(find.byType(MenuScreen), findsOneWidget);
    await tester.tap(iconButton('Назад'));
    await tester.pumpAndSettle();
    expect(find.byType(DayScreen), findsOneWidget);
  });

  test('withdraw amount rules', () {
    const balance = Balance(
      available: 815,
      cardTotal: 2400,
      commissionTotal: 585,
      withdrawnTotal: 1000,
    );
    expect(
      validateWithdrawAmount(null, balance),
      WithdrawAmountError.notPositive,
    );
    expect(validateWithdrawAmount(0, balance), WithdrawAmountError.notPositive);
    expect(
      validateWithdrawAmount(816, balance),
      WithdrawAmountError.insufficient,
    );
    expect(validateWithdrawAmount(815, balance), isNull);
  });
}
