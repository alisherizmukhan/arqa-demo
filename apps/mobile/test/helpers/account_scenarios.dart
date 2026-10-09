import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/features/admin/presentation/screens/admin_screen.dart';
import 'package:driver_diary/features/auth/presentation/screens/login_screen.dart';
import 'package:driver_diary/features/menu/presentation/screens/menu_screen.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/withdrawals/domain/entities/withdrawal.dart';
import 'package:driver_diary/features/withdrawals/presentation/screens/withdraw_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';
import 'fakes.dart';
import 'fixtures.dart';
import 'scenarios.dart';

/// The reference trips with their drivers (the admin's «Все водители»).
final List<Trip> ownedTrips = [
  for (final t in [t1, t2]) _owned(t, driver1.id),
  for (final t in [u2t1, u2t2]) _owned(t, driver2.id),
];

Trip _owned(Trip t, String driverId) => Trip(
  id: t.id,
  start: t.start,
  end: t.end,
  amount: t.amount,
  payment: t.payment,
  commission: t.commission,
  driverId: driverId,
);

Withdrawal _withdrawal(
  String id,
  int amount,
  DateTime createdAt, {
  WithdrawalStatus status = WithdrawalStatus.pending,
  String driverId = 'u1',
  String? reason,
}) => Withdrawal(
  id: id,
  driverId: driverId,
  amount: amount,
  status: status,
  createdAt: createdAt,
  rejectReason: reason,
);

/// user_1's history: 1 000 ₸ withdrawn (400 pending + 600 paid), 500
/// rejected; 815 ₸ left of 1 815 ₸.
List<Withdrawal> driverHistory() => [
  _withdrawal(
    'w-paid',
    600,
    DateTime.utc(2026, 10, 5, 9, 20),
    status: WithdrawalStatus.paid,
  ),
  _withdrawal(
    'w-rejected',
    500,
    DateTime.utc(2026, 10, 6, 4, 40),
    status: WithdrawalStatus.rejected,
    reason: 'Неверные реквизиты',
  ),
  _withdrawal('w-pending', 400, DateTime.utc(2026, 10, 8, 13, 5)),
];

/// Requests from both drivers, for the admin.
List<Withdrawal> adminRequests() => [
  _withdrawal(
    'a-paid',
    800,
    DateTime.utc(2026, 10, 7, 11),
    status: WithdrawalStatus.paid,
  ),
  _withdrawal('a-1', 500, DateTime.utc(2026, 10, 9, 7, 10)),
  _withdrawal('a-2', 1000, oct9, driverId: 'u2'),
];

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _withdraw(
  WidgetTester tester,
  FakeWithdrawalsRepository withdrawals, {
  int? amount,
}) async {
  await pumpDiary(
    tester,
    FakeTripsRepository(),
    withdrawals: withdrawals,
    home: WithdrawScreen(initialAmount: amount),
  );
  await _settle(tester);
}

Future<void> _admin(
  WidgetTester tester, {
  AdminTab tab = AdminTab.trips,
  FakeWithdrawalsRepository? withdrawals,
}) async {
  await pumpDiary(
    tester,
    FakeTripsRepository(ownedTrips),
    user: adminUser,
    now: at(12, 0),
    withdrawals:
        withdrawals ?? FakeWithdrawalsRepository(items: adminRequests()),
    home: AdminScreen(initialTab: tab),
  );
  await _settle(tester);
}

/// The §8 screens: login, menu, withdraw, admin. Run in [scenarioLocale].
final accountScenarios = <Scenario>[
  (
    id: 'a01_login',
    run: (tester) async {
      await pumpDiary(tester, FakeTripsRepository(), user: null);
      await _settle(tester);
    },
  ),
  (
    id: 'a02_login_wrong_password',
    run: (tester) async {
      await pumpDiary(tester, FakeTripsRepository(), user: null);
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(0), 'user_1');
      await tester.enterText(find.byType(TextField).at(1), 'secret');
      await tester.tap(find.text(tr.signIn).last);
      await _settle(tester);
    },
  ),
  (
    id: 'a03_login_rate_limited',
    run: (tester) async {
      final auth = FakeAuthRepository()
        ..onLogin = (_, _) async => const Err(RateLimitedFailure());
      await pumpDiary(tester, FakeTripsRepository(), user: null, auth: auth);
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(0), 'user_1');
      await tester.enterText(find.byType(TextField).at(1), 'secret');
      await tester.tap(find.text(tr.signIn).last);
      await _settle(tester);
    },
  ),
  (
    id: 'a04_login_offline',
    run: (tester) async {
      final auth = FakeAuthRepository()
        ..onLogin = (_, _) async => const Err(NetworkFailure());
      await pumpDiary(tester, FakeTripsRepository(), user: null, auth: auth);
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(0), 'user_1');
      await tester.enterText(find.byType(TextField).at(1), 'password_1');
      await tester.tap(find.text(tr.signIn).last);
      await _settle(tester);
    },
  ),
  (
    id: 'a05_session_ended',
    run: (tester) async {
      await pumpDiary(
        tester,
        FakeTripsRepository(),
        user: null,
        home: const LoginScreen(sessionEnded: true),
      );
      await _settle(tester);
    },
  ),
  (
    id: 'a06_day_header',
    run: (tester) async {
      await pumpDiary(tester, FakeTripsRepository([t1, t2]));
      await selectDay(tester, referenceDay);
    },
  ),
  (
    id: 'a07_menu_driver',
    run: (tester) async {
      await pumpDiary(
        tester,
        FakeTripsRepository(),
        withdrawals: FakeWithdrawalsRepository(),
        home: const MenuScreen(),
      );
      await _settle(tester);
    },
  ),
  (
    id: 'a08_menu_admin',
    run: (tester) async {
      await pumpDiary(
        tester,
        FakeTripsRepository(),
        user: adminUser,
        home: const MenuScreen(),
      );
      await _settle(tester);
    },
  ),
  (
    id: 'a09_menu_logout_dialog',
    run: (tester) async {
      await pumpDiary(tester, FakeTripsRepository(), home: const MenuScreen());
      await _settle(tester);
      await tester.tap(find.text(tr.logout));
      await tester.pumpAndSettle();
    },
  ),
  (
    id: 'a10_withdraw',
    run: (tester) =>
        _withdraw(tester, FakeWithdrawalsRepository(items: driverHistory())),
  ),
  (
    id: 'a11_withdraw_too_much',
    run: (tester) => _withdraw(
      tester,
      FakeWithdrawalsRepository(items: driverHistory()),
      amount: 2000,
    ),
  ),
  (
    id: 'a12_withdraw_nothing',
    run: (tester) => _withdraw(
      tester,
      FakeWithdrawalsRepository(cardTotal: 1000, commissionTotal: 1300),
    ),
  ),
  (
    id: 'a13_withdraw_offline',
    run: (tester) async {
      final withdrawals = FakeWithdrawalsRepository(items: driverHistory())
        ..onCreate = (_, _) async => const Err(NetworkFailure());
      await _withdraw(tester, withdrawals, amount: 300);
      await tester.tap(find.text(tr.withdrawButton));
      await _settle(tester);
    },
  ),
  (
    id: 'a14_withdraw_created',
    run: (tester) async {
      await _withdraw(
        tester,
        FakeWithdrawalsRepository(items: driverHistory()),
        amount: 300,
      );
      await tester.tap(find.text(tr.withdrawButton));
      await _settle(tester);
    },
  ),
  (
    id: 'a15_withdraw_conflict',
    run: (tester) async {
      final withdrawals = FakeWithdrawalsRepository(items: driverHistory())
        ..onCreate = (_, _) async =>
            const Err(ConflictFailure('conflict', 'withdrawal_conflict'));
      await _withdraw(tester, withdrawals, amount: 300);
      await tester.tap(find.text(tr.withdrawButton));
      await tester.pumpAndSettle();
    },
  ),
  (id: 'a16_admin_trips_all', run: _admin),
  (
    id: 'a17_admin_trips_driver',
    run: (tester) async {
      await _admin(tester);
      await tester.tap(find.text(driver2.displayName).first);
      await _settle(tester);
    },
  ),
  (
    id: 'a18_admin_withdrawals',
    run: (tester) => _admin(tester, tab: AdminTab.withdrawals),
  ),
  (
    id: 'a19_admin_reject_dialog',
    run: (tester) async {
      await _admin(tester, tab: AdminTab.withdrawals);
      await tester.tap(find.text(tr.reject).first);
      await tester.pumpAndSettle();
    },
  ),
  (
    id: 'a20_admin_drivers',
    run: (tester) => _admin(tester, tab: AdminTab.drivers),
  ),
  (
    id: 'a21_admin_driver_sheet',
    run: (tester) async {
      await _admin(tester, tab: AdminTab.drivers);
      await tester.tap(find.text(driver2.displayName));
      await tester.pumpAndSettle();
    },
  ),
];
