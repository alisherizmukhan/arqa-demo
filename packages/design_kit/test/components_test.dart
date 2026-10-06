import 'package:design_kit/design_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('DkSummaryTile', () {
    testWidgets('formats money as "3 315 ₸"', (tester) async {
      await tester.pumpWidget(
        wrap(
          const DkSummaryTile.money(
            label: 'Чистыми',
            amount: 3315,
            tone: DkTone.positive,
            emphasis: DkSummaryEmphasis.hero,
          ),
        ),
      );

      expect(find.text('Чистыми'), findsOneWidget);
      expect(find.text('3 315 ₸'), findsOneWidget);
    });

    testWidgets('deduction is shown with a minus sign', (tester) async {
      await tester.pumpWidget(
        wrap(
          const DkSummaryTile.money(
            label: 'Комиссия',
            amount: 585,
            isDeduction: true,
          ),
        ),
      );

      expect(find.text('−585 ₸'), findsOneWidget);
    });

    testWidgets('count has no currency', (tester) async {
      await tester.pumpWidget(
        wrap(const DkSummaryTile.count(label: 'Поездок', count: 2)),
      );

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('label and value are read together', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(const DkSummaryTile.money(label: 'Выручка', amount: 3900)),
      );

      expect(
        tester.getSemantics(find.byType(DkSummaryTile)),
        matchesSemantics(label: 'Выручка\n3 900 ₸'),
      );
      handle.dispose();
    });

    testWidgets('a huge figure scales down instead of overflowing', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const SizedBox(
            width: 120,
            child: DkSummaryTile.money(
              label: 'Выручка',
              amount: 9999999,
              emphasis: DkSummaryEmphasis.hero,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('DkButton', () {
    testWidgets('calls onPressed', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(DkButton(label: 'Сохранить', onPressed: () => taps++)),
      );

      await tester.tap(find.text('Сохранить'));
      expect(taps, 1);
    });

    testWidgets('loading shows a spinner and ignores taps', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        wrap(
          DkButton(
            label: 'Сохранить',
            onPressed: () => taps++,
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('Сохранить'), warnIfMissed: false);
      expect(taps, 0);
      expect(
        tester.getSemantics(find.byType(DkButton)),
        isSemantics(label: 'Сохранить', value: 'Загрузка'),
      );
      handle.dispose();
    });

    testWidgets('is at least 56dp tall', (tester) async {
      await tester.pumpWidget(
        wrap(
          DkButton(
            label: 'OK',
            onPressed: () {},
            variant: DkButtonVariant.text,
            expand: false,
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(TextButton)).height,
        greaterThanOrEqualTo(56),
      );
    });
  });

  group('DkTripTile', () {
    testWidgets('shows time, payment label and amount', (tester) async {
      await tester.pumpWidget(
        wrap(
          const DkTripTile(
            timeRange: '08:10 – 08:32',
            amount: 2400,
            payment: DkPaymentKind.card,
            details: 'комиссия 360 ₸',
          ),
        ),
      );

      expect(find.text('08:10 – 08:32'), findsOneWidget);
      expect(find.text('Карта · комиссия 360 ₸'), findsOneWidget);
      expect(find.text('2 400 ₸'), findsOneWidget);
      expect(find.byIcon(Icons.credit_card), findsOneWidget);
    });

    testWidgets('payment is never conveyed by color alone', (tester) async {
      await tester.pumpWidget(
        wrap(
          const DkTripTile(
            timeRange: '09:05 – 09:20',
            amount: 1500,
            payment: DkPaymentKind.cash,
          ),
        ),
      );

      expect(find.text('Наличные'), findsOneWidget);
      expect(find.byIcon(Icons.payments_outlined), findsOneWidget);
    });
  });

  group('DkDaySwitcher', () {
    testWidgets('arrows and label trigger callbacks', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(
        wrap(
          DkDaySwitcher(
            label: '1 октября',
            onPrevious: () => calls.add('prev'),
            onNext: () => calls.add('next'),
            onPick: () => calls.add('pick'),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Предыдущий день'));
      await tester.tap(find.byTooltip('Следующий день'));
      await tester.tap(find.text('1 октября'));
      expect(calls, ['prev', 'next', 'pick']);
    });

    testWidgets('null onNext disables the forward arrow', (tester) async {
      await tester.pumpWidget(
        wrap(
          DkDaySwitcher(
            label: 'Сегодня',
            onPrevious: () {},
            onNext: null,
            onPick: () {},
          ),
        ),
      );

      final next = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.chevron_right),
          matching: find.byType(IconButton),
        ),
      );
      expect(next.onPressed, isNull);
    });
  });

  group('states', () {
    testWidgets('error state retries', (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        wrap(
          DkErrorState(message: 'Проверьте интернет', onRetry: () => retries++),
        ),
      );

      expect(find.text('Не удалось загрузить'), findsOneWidget);
      await tester.tap(find.text('Повторить'));
      expect(retries, 1);
    });

    testWidgets('empty state with action', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(
          DkEmptyState(
            title: 'Поездок нет',
            actionLabel: 'Добавить поездку',
            onAction: () => taps++,
          ),
        ),
      );

      await tester.tap(find.text('Добавить поездку'));
      expect(taps, 1);
    });

    testWidgets('skeleton is still under reduced motion', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: wrap(const DkSkeleton(height: 24)),
        ),
      );

      // Would time out if the pulse kept running.
      await tester.pumpAndSettle();
      expect(find.byType(DkSkeleton), findsOneWidget);
    });

    testWidgets('skeleton pulses otherwise', (tester) async {
      await tester.pumpWidget(wrap(const DkSkeleton(height: 24)));

      expect(tester.hasRunningAnimations, isTrue);
    });
  });

  group('inputs', () {
    testWidgets('text field shows label and error', (tester) async {
      await tester.pumpWidget(
        wrap(
          const DkTextField(
            label: 'Сумма',
            suffixText: '₸',
            errorText: 'Сумма должна быть больше нуля',
          ),
        ),
      );

      expect(find.text('Сумма'), findsOneWidget);
      expect(find.text('Сумма должна быть больше нуля'), findsOneWidget);
      expect(
        tester.getSize(find.byType(TextField)).height,
        greaterThanOrEqualTo(56),
      );
    });

    testWidgets('segmented control reports the new value', (tester) async {
      DkPaymentKind? picked;
      await tester.pumpWidget(
        wrap(
          DkSegmentedControl<DkPaymentKind>(
            label: 'Оплата',
            segments: [
              for (final kind in DkPaymentKind.values)
                DkSegment(value: kind, label: kind.label, icon: kind.icon),
            ],
            selected: DkPaymentKind.cash,
            onChanged: (value) => picked = value,
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(InkWell).first).height,
        greaterThanOrEqualTo(56),
      );
      await tester.tap(find.text('Карта'));
      expect(picked, DkPaymentKind.card);
    });
  });
}
