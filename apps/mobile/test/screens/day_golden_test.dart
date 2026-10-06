// DESIGN.md §7: the Day screen, light and dark, with the sample data.
// goldenTest registers tests; its Future need not be awaited.
// ignore_for_file: discarded_futures
import 'package:alchemist/alchemist.dart';
import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/providers.dart';
import 'package:driver_diary/features/trips/presentation/providers/trips_providers.dart';
import 'package:driver_diary/features/trips/presentation/screens/day_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/app_harness.dart';
import '../helpers/fixtures.dart';

void main() {
  goldenTest(
    'Day screen with the sample data',
    fileName: 'day_screen',
    builder: () => GoldenTestGroup(
      columns: 2,
      children: [
        for (final (name, theme) in [
          ('light', DkTheme.light()),
          ('dark', DkTheme.dark()),
        ])
          GoldenTestScenario(
            name: name,
            constraints: BoxConstraints.tight(phone390.size),
            child: Theme(
              data: theme,
              child: ProviderScope(
                overrides: [
                  tripsRepositoryProvider.overrideWithValue(
                    FakeTripsRepository([t1, t2]),
                  ),
                  driverZoneProvider.overrideWithValue(kz),
                  // «Today» is the sample day, 2026-10-01.
                  clockProvider.overrideWithValue(() => at(12, 0)),
                ],
                retry: (_, _) => null,
                child: const DayScreen(),
              ),
            ),
          ),
      ],
    ),
  );
}
