import 'dart:async';

import 'package:design_kit/design_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Pumps an empty kit screen and returns a context under its Overlay.
Future<BuildContext> pumpContext(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(
    wrap(
      Builder(
        builder: (context) {
          captured = context;
          return const SizedBox();
        },
      ),
    ),
  );
  return captured;
}

List<String> richTexts(WidgetTester tester) => tester
    .widgetList<RichText>(find.byType(RichText))
    .map((t) => t.text.toPlainText())
    .toList();

/// A day in October 2026.
DateTime oct(int day) => DateTime(2026, 10, day);

void main() {
  group('DkButton', () {
    testWidgets('calls onPressed; min height 56 (text: 48)', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              DkButton(label: 'Сохранить', onPressed: () => taps++),
              DkButton(
                label: 'Повторить',
                variant: DkButtonVariant.text,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Сохранить'));
      expect(taps, 1);
      final buttons = find.byType(DkButton);
      expect(tester.getSize(buttons.first).height, 56);
      expect(tester.getSize(buttons.last).height, 48);
    });

    testWidgets('keeps its height in a bottom bar (bounded height)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DkTheme.light(),
          home: Scaffold(
            body: const Placeholder(),
            bottomNavigationBar: DkButton(
              label: 'Добавить поездку',
              expand: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(DkButton)).height, 56);
      expect(tester.getSize(find.byType(Placeholder)).height, greaterThan(0));
    });

    testWidgets('loading shows a spinner and ignores taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(
          DkButton(
            label: 'Сохраняем…',
            isLoading: true,
            onPressed: () => taps++,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('Сохраняем…'), warnIfMissed: false);
      expect(taps, 0);
    });

    testWidgets('disabled uses disabledFill and textDisabled', (tester) async {
      await tester.pumpWidget(wrap(const DkButton(label: 'Сохранить')));

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(DkButton),
          matching: find.byType(Material),
        ),
      );
      expect(material.color, DkColors.light.disabledFill);
      final label = tester.widget<Text>(find.text('Сохранить'));
      expect(label.style!.color, DkColors.light.textDisabled);
    });
  });

  group('DkSummaryCard / DkPaymentCard', () {
    testWidgets('reference day 2026-10-01', (tester) async {
      await tester.pumpWidget(
        wrap(
          const Column(
            children: [
              DkSummaryCard(
                net: 3315,
                revenue: 3900,
                commission: 585,
                tripsCount: 2,
              ),
              DkPaymentCard(cash: 1500, card: 2400),
            ],
          ),
        ),
      );

      final texts = richTexts(tester);
      expect(texts, contains('3 315 ₸'));
      expect(texts, contains('3 900 ₸'));
      expect(texts, contains('−585 ₸'));
      expect(texts, contains('Наличные · 38%'));
      expect(texts, contains('Карта · 62%'));
      expect(find.bySemanticsLabel('Наличные 38%, карта 62%'), findsOneWidget);
    });

    testWidgets('no split and no percentages at zero revenue', (tester) async {
      await tester.pumpWidget(wrap(const DkPaymentCard(cash: 0, card: 0)));

      expect(find.byType(DkSplitBar), findsNothing);
      expect(find.textContaining('%'), findsNothing);
    });
  });

  group('DkTripTile', () {
    testWidgets('shows +1 for a trip ending the next day', (tester) async {
      await tester.pumpWidget(
        wrap(
          const DkTripTile(
            timeRange: '23:50 – 00:20',
            endsNextDay: true,
            meta: '30 мин · Наличные',
            amount: '3 000 ₸',
            commission: 'комиссия 450 ₸',
            method: DkPaymentMethod.cash,
          ),
        ),
      );

      expect(find.text('+1'), findsOneWidget);
      expect(find.text('30 мин · Наличные'), findsOneWidget);
      expect(
        tester.getSize(find.byType(DkTripTile)).height,
        greaterThanOrEqualTo(72),
      );
    });

    for (final scale in [1.0, 1.3]) {
      testWidgets('maximum amounts fit a 360 dp phone at text scale $scale', (
        tester,
      ) async {
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: wrap(
              SizedBox(
                width: 328, // 360 dp minus the screen gutters
                child: DkTripTile(
                  timeRange: '23:50 – 00:20',
                  endsNextDay: true,
                  meta: '30 мин · Наличные',
                  amount: DkMoney.format(10000000),
                  commission: 'комиссия ${DkMoney.format(9999999)}',
                  method: DkPaymentMethod.cash,
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('highlighted row uses accentSoft', (tester) async {
      await tester.pumpWidget(
        wrap(
          const DkTripTile(
            timeRange: '08:10 – 08:32',
            endsNextDay: false,
            meta: '22 мин · Карта',
            amount: '2 400 ₸',
            commission: 'комиссия 360 ₸',
            method: DkPaymentMethod.card,
            highlighted: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final box = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(
        (box.decoration! as BoxDecoration).color,
        DkColors.light.accentSoft,
      );
    });
  });

  group('DkDaySwitcher', () {
    testWidgets('today: «Сегодня» + date, next disabled', (tester) async {
      var next = 0;
      await tester.pumpWidget(
        wrap(
          DkDaySwitcher(
            date: oct(6),
            today: oct(6),
            onPrev: () {},
            onNext: () => next++,
            onPickDate: () {},
          ),
        ),
      );

      expect(find.text('Сегодня'), findsOneWidget);
      expect(find.text('6 октября 2026'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Следующий день'));
      expect(next, 0);
    });

    testWidgets('past day: date + weekday; callbacks fire', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(
        wrap(
          DkDaySwitcher(
            date: oct(1),
            today: oct(6),
            onPrev: () => calls.add('prev'),
            onNext: () => calls.add('next'),
            onPickDate: () => calls.add('pick'),
          ),
        ),
      );

      expect(find.text('1 октября 2026'), findsOneWidget);
      expect(find.text('Четверг'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Предыдущий день'));
      await tester.tap(find.bySemanticsLabel('Следующий день'));
      await tester.tap(find.bySemanticsLabel('Выбрать дату, 1 октября 2026'));
      expect(calls, ['prev', 'next', 'pick']);
    });
  });

  group('inputs', () {
    testWidgets('error replaces helper and shows the message', (tester) async {
      final controller = DkMoneyEditingController(amount: 0);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        wrap(
          DkTextField.money(
            label: 'Сумма',
            controller: controller,
            helper: 'Сколько заплатил пассажир',
            errorText: 'Сумма должна быть больше 0',
          ),
        ),
      );

      expect(find.text('Сумма должна быть больше 0'), findsOneWidget);
      expect(find.text('Сколько заплатил пассажир'), findsNothing);
      expect(find.byIcon(DkIcons.alert), findsOneWidget);
    });

    testWidgets('time field with +1 day badge never overflows', (tester) async {
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 173,
            child: DkTimeField(
              label: 'Окончание',
              value: '00:20',
              onTap: () {},
              trailing: const DkBadge('+1 день'),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('00:20'), findsOneWidget);
      expect(find.text('+1 день'), findsOneWidget);
    });

    testWidgets('segmented control reports the tapped value', (tester) async {
      DkPaymentMethod? picked;
      await tester.pumpWidget(
        wrap(
          DkSegmentedControl<DkPaymentMethod>(
            segments: [
              for (final m in DkPaymentMethod.values)
                DkSegment(value: m, label: m.label, icon: m.icon),
            ],
            selected: DkPaymentMethod.card,
            onChanged: (value) => picked = value,
          ),
        ),
      );

      await tester.tap(find.text('Наличные'));
      expect(picked, DkPaymentMethod.cash);
    });
  });

  group('feedback', () {
    testWidgets('error snackbar stays; success closes after 3 s', (
      tester,
    ) async {
      final context = await pumpContext(tester);

      var retried = 0;
      final error = showDkSnackbar(
        context,
        message: 'Нет связи. Повторим отправку — поездка не задвоится.',
        tone: DkSnackTone.error,
        actionLabel: 'Повторить',
        onAction: () => retried++,
      );
      await tester.pump(const Duration(seconds: 10));
      expect(error.isOpen, isTrue);
      await tester.tap(find.text('Повторить'));
      expect(retried, 1);

      final success = showDkSnackbar(
        context,
        message: 'Поездка добавлена',
        tone: DkSnackTone.success,
      );
      expect(error.isOpen, isFalse, reason: 'one snackbar at a time');
      await tester.pump(const Duration(seconds: 3));
      expect(success.isOpen, isFalse);
    });

    testWidgets('dialog runs the chosen action and closes', (tester) async {
      final context = await pumpContext(tester);
      final picked = <String>[];

      unawaited(
        showDkDialog(
          context,
          icon: DkIcons.alert,
          title: 'Эта поездка уже сохранена с другими данными',
          message: 'Обновите день, чтобы увидеть сохранённую версию.',
          primaryLabel: 'Оставить сохранённую',
          onPrimary: () => picked.add('keep'),
          secondaryLabel: 'Сохранить как новую поездку',
          onSecondary: () => picked.add('new'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сохранить как новую поездку'));
      await tester.pumpAndSettle();

      expect(picked, ['new']);
      expect(find.text('Оставить сохранённую'), findsNothing);
    });
  });

  group('states', () {
    testWidgets('empty and error states', (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              DkEmptyState(
                title: 'За этот день поездок нет',
                actionLabel: 'Добавить поездку',
                onAction: () {},
              ),
              DkErrorState(
                title: 'Не удалось загрузить данные',
                onRetry: () => retries++,
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Повторить'));
      expect(retries, 1);
      expect(find.byIcon(DkIcons.empty), findsOneWidget);
      expect(find.byIcon(DkIcons.loadError), findsOneWidget);
    });

    testWidgets('skeleton pulses; still under reduced motion', (tester) async {
      await tester.pumpWidget(wrap(const DkSkeleton.tripTile()));
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: wrap(const DkSkeleton.summaryCard()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DkSkeleton), findsOneWidget);
    });
  });
}
