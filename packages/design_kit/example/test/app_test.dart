import 'package:design_kit/design_kit.dart';
import 'package:design_kit_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpTall(
    WidgetTester tester,
    Widget app, {
    double width = 800,
  }) async {
    // Tall surface so the whole showcase is built without scrolling.
    tester.view
      ..physicalSize = Size(width, 9000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app);
    await tester.pump();
  }

  testWidgets('showcase renders every component', (tester) async {
    await pumpTall(tester, const App());

    for (final type in [
      DkButton,
      DkFab,
      DkDaySwitcher,
      DkSegmentedControl<DkPaymentMethod>,
      DkSummaryCard,
      DkSummaryTile,
      DkPaymentCard,
      DkSplitBar,
      DkTripTile,
      DkTripList,
      DkListHeader,
      DkSkeleton,
      DkTextField,
      DkTimeField,
      DkBadge,
      DkEmptyState,
      DkErrorState,
      DkSnackbarView,
      DkDialogView,
      DkWordmark,
      DkModalAppBar,
      DkBottomBar,
    ]) {
      expect(find.byType(type), findsWidgets, reason: '$type');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('theme toggle switches to dark', (tester) async {
    await tester.pumpWidget(const App());
    final page = find.byType(ShowcasePage);
    expect(Theme.of(tester.element(page)).brightness, Brightness.light);

    await tester.tap(find.byTooltip('Тёмная тема'));
    // Starts the theme animation, then lets it finish. (No pumpAndSettle:
    // skeletons pulse forever.)
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(Theme.of(tester.element(page)).brightness, Brightness.dark);
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final tab in [0, 1]) {
      testWidgets('no overflow on a 360dp phone (${mode.name}, tab $tab)', (
        tester,
      ) async {
        await pumpTall(
          tester,
          App(initialThemeMode: mode, initialTab: tab),
          width: 360,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
