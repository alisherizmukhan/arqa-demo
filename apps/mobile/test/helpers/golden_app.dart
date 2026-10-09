import 'package:alchemist/alchemist.dart';
import 'package:driver_diary/app.dart';
import 'package:driver_diary/core/l10n/locale_providers.dart';
import 'package:driver_diary/core/providers.dart';
import 'package:driver_diary/features/admin/presentation/admin_providers.dart';
import 'package:driver_diary/features/auth/domain/entities/app_user.dart';
import 'package:driver_diary/features/auth/presentation/providers/session_providers.dart';
import 'package:driver_diary/features/trips/presentation/providers/trips_providers.dart';
import 'package:driver_diary/features/withdrawals/presentation/providers/withdrawals_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_harness.dart';
import 'fakes.dart';
import 'fixtures.dart';

/// One golden row: [home] in light and dark, at 390×844, in [locale], with
/// fake data, signed in as [user].
GoldenTestGroup goldenRow({
  required Widget Function() home,
  required String locale,
  AppUser user = driver1,
  FakeTripsRepository Function()? trips,
  FakeWithdrawalsRepository Function()? withdrawals,
  DateTime? now,
}) => GoldenTestGroup(
  columns: 2,
  children: [
    for (final (name, mode) in [
      ('light', ThemeMode.light),
      ('dark', ThemeMode.dark),
    ])
      GoldenTestScenario(
        name: '$locale $name',
        constraints: BoxConstraints.tight(phone390.size),
        child: ProviderScope(
          overrides: [
            tripsRepositoryProvider.overrideWithValue(
              trips?.call() ?? FakeTripsRepository([t1, t2]),
            ),
            driverZoneProvider.overrideWithValue(kz),
            // «Today» is the sample day, 2026-10-01.
            clockProvider.overrideWithValue(() => now ?? at(12, 0)),
            authRepositoryProvider.overrideWithValue(
              FakeAuthRepository(signedIn: user),
            ),
            tokenStoreProvider.overrideWithValue(
              MemoryTokenStore('token-${user.login}'),
            ),
            localeStoreProvider.overrideWithValue(MemoryLocaleStore(locale)),
            withdrawalsRepositoryProvider.overrideWithValue(
              withdrawals?.call() ?? FakeWithdrawalsRepository(),
            ),
            adminRepositoryProvider.overrideWithValue(FakeAdminRepository()),
          ],
          retry: (_, _) => null,
          child: App(home: home(), themeMode: mode),
        ),
      ),
  ],
);
