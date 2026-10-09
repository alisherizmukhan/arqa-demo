// Regressions from the stage 5 review: the login errors must be visible
// after a real 401 / 429 answer, and the admin's driver filter and day must
// survive a language switch. Both in Russian and Kazakh.
import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/config/app_config.dart';
import 'package:driver_diary/core/l10n/l10n.dart';
import 'package:driver_diary/core/network/auth_interceptor.dart';
import 'package:driver_diary/core/network/dio_client.dart';
import 'package:driver_diary/core/time/calendar_day.dart';
import 'package:driver_diary/features/admin/presentation/screens/admin_screen.dart';
import 'package:driver_diary/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:driver_diary/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:driver_diary/features/trips/presentation/providers/trips_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/account_scenarios.dart';
import '../../helpers/app_harness.dart';
import '../../helpers/fakes.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/http_stub.dart';

AppLocalizations _l10n(String locale) => lookupAppLocalizations(Locale(locale));

void main() {
  for (final locale in ['ru', 'kk']) {
    group('[$locale] login errors from the server', () {
      late StubAdapter http;

      Future<void> signIn(WidgetTester tester) async {
        final dio = createDio(
          const AppConfig(apiUrl: 'http://api', driverZone: kz),
          AuthGate(),
        )..httpClientAdapter = http;
        await pumpDiary(
          tester,
          FakeTripsRepository(),
          user: null,
          locale: locale,
          auth: AuthRepositoryImpl(AuthRemoteDataSource(dio)),
        );
        await tester.pump();
        await tester.enterText(find.byType(TextField).at(0), 'user_1');
        await tester.enterText(find.byType(TextField).at(1), 'secret');
        await tester.pump();
        await tester.tap(find.text(_l10n(locale).signIn).last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      testWidgets('401 invalid_credentials → the text under the password', (
        tester,
      ) async {
        http = StubAdapter(401)
          ..body = apiError('invalid_credentials', 'invalid login or password');

        await signIn(tester);

        expect(find.text(_l10n(locale).errInvalidCredentials), findsOneWidget);
        expect(http.requestHeaders, hasLength(1), reason: 'not retried');
      });

      testWidgets('429 with Retry-After → «too many attempts»', (tester) async {
        http = StubAdapter(429)
          ..body = apiError('rate_limited', 'too many failed login attempts')
          ..headers = {
            'retry-after': ['900'],
          };

        await signIn(tester);

        expect(find.text(_l10n(locale).errRateLimited), findsOneWidget);
        expect(find.text(_l10n(locale).errInvalidCredentials), findsNothing);
        expect(http.requestHeaders, hasLength(1), reason: 'not retried');
      });
    });

    testWidgets('[$locale] admin: driver filter and day survive a language '
        'switch', (tester) async {
      final other = locale == 'ru' ? 'kk' : 'ru';
      useDevice(tester, phone390);
      final trips = FakeTripsRepository(ownedTrips);
      await pumpDiary(
        tester,
        trips,
        user: adminUser,
        now: at(12, 0, day: 2), // today is 2 October
        locale: locale,
        home: const AdminScreen(),
      );
      await tester.pump();

      // The previous day (1 October, the reference trips), driver 2 only.
      await tester.tap(iconButton(_l10n(locale).prevDay));
      await tester.pump();
      final chip = find.text(driver2.displayName).first;
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(find.text(DkMoney.format(4080)), findsOneWidget);

      // Switch the language in the menu and come back.
      // Back to the top of the page, where the header is.
      await tester.drag(find.byType(ListView).first, const Offset(0, 2000));
      await tester.pumpAndSettle();
      await tester.tap(iconButton(_l10n(locale).menu));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(
          other == 'kk' ? _l10n(other).languageKk : _l10n(other).languageRu,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(iconButton(_l10n(other).back));
      await tester.pumpAndSettle();

      expect(find.byType(AdminScreen), findsOneWidget);
      expect(
        containerOf(tester).read(selectedDayProvider),
        CalendarDay(2026, 10, 1),
      );
      expect(find.text(_l10n(other).yesterday), findsOneWidget);
      expect(find.text(DkMoney.format(4080)), findsOneWidget);
      expect(trips.driverFilters.last, driver2.id);
    });
  }
}
