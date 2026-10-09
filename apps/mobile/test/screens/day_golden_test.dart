// DESIGN.md §7: the Day screen, light and dark, with the sample data.
// goldenTest registers tests; its Future need not be awaited.
// ignore_for_file: discarded_futures
import 'package:alchemist/alchemist.dart';
import 'package:driver_diary/features/trips/presentation/screens/day_screen.dart';

import '../helpers/golden_app.dart';

void main() {
  goldenTest(
    'Day screen with the sample data',
    fileName: 'day_screen',
    builder: () => goldenRow(home: () => const DayScreen(), locale: 'ru'),
  );
}
