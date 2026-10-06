import 'package:design_kit/design_kit.dart';
import 'package:design_kit_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showcase renders every component', (tester) async {
    // Tall surface so the whole showcase is built without scrolling.
    tester.view
      ..physicalSize = const Size(800, 6000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const App());

    for (final type in [
      DkDaySwitcher,
      DkCard,
      DkSummaryTile,
      DkTripTile,
      DkButton,
      DkTextField,
      DkSegmentedControl<DkPaymentKind>,
      DkSkeleton,
      DkEmptyState,
      DkErrorState,
    ]) {
      expect(find.byType(type), findsWidgets, reason: '$type');
    }
    expect(find.text(DkMoney.format(3315)), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('theme toggle switches to dark', (tester) async {
    await tester.pumpWidget(const App());
    expect(
      Theme.of(tester.element(find.byType(ShowcasePage))).brightness,
      Brightness.light,
    );

    await tester.tap(find.byTooltip('Тёмная тема'));
    // Starts the theme animation, then lets it finish. (No pumpAndSettle:
    // the skeleton pulses forever.)
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      Theme.of(tester.element(find.byType(ShowcasePage))).brightness,
      Brightness.dark,
    );
  });

  for (final theme in ['light', 'dark']) {
    testWidgets('no overflow on a 360dp phone ($theme)', (tester) async {
      tester.view
        ..physicalSize = const Size(360, 6000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        App(
          initialThemeMode: theme == 'dark' ? ThemeMode.dark : ThemeMode.light,
        ),
      );

      expect(tester.takeException(), isNull);
    });
  }
}
