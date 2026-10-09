// DESIGN.md §8 screens in Russian and Kazakh, light and dark (prompt §5):
// Login, Menu, Withdraw, Admin.
// goldenTest registers tests; its Future need not be awaited.
// ignore_for_file: discarded_futures
import 'package:alchemist/alchemist.dart';
import 'package:driver_diary/features/admin/presentation/screens/admin_screen.dart';
import 'package:driver_diary/features/auth/presentation/screens/login_screen.dart';
import 'package:driver_diary/features/menu/presentation/screens/menu_screen.dart';
import 'package:driver_diary/features/withdrawals/presentation/screens/withdraw_screen.dart';

import '../helpers/account_scenarios.dart';
import '../helpers/app_harness.dart';
import '../helpers/fakes.dart';
import '../helpers/golden_app.dart';

void main() {
  for (final locale in ['ru', 'kk']) {
    goldenTest(
      'Login ($locale)',
      fileName: 'login_$locale',
      builder: () => goldenRow(home: () => const LoginScreen(), locale: locale),
    );
    goldenTest(
      'Menu ($locale)',
      fileName: 'menu_$locale',
      builder: () => goldenRow(home: () => const MenuScreen(), locale: locale),
    );
    goldenTest(
      'Withdraw ($locale)',
      fileName: 'withdraw_$locale',
      builder: () => goldenRow(
        home: () => const WithdrawScreen(),
        locale: locale,
        withdrawals: () => FakeWithdrawalsRepository(items: driverHistory()),
      ),
    );
    goldenTest(
      'Admin, all drivers ($locale)',
      fileName: 'admin_$locale',
      builder: () => goldenRow(
        home: () => const AdminScreen(),
        locale: locale,
        user: adminUser,
        trips: () => FakeTripsRepository(ownedTrips),
      ),
    );
    goldenTest(
      'Admin, withdrawals ($locale)',
      fileName: 'admin_withdrawals_$locale',
      builder: () => goldenRow(
        home: () => const AdminScreen(initialTab: AdminTab.withdrawals),
        locale: locale,
        user: adminUser,
        withdrawals: () => FakeWithdrawalsRepository(items: adminRequests()),
      ),
    );
  }
}
