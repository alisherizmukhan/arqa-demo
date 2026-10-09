import 'package:design_kit/design_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('password field hides the text until the eye is tapped', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'password_1');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      wrap(
        DkPasswordField(
          label: 'Пароль',
          controller: controller,
          showLabel: 'Показать пароль',
          hideLabel: 'Скрыть пароль',
        ),
      ),
    );

    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isTrue,
    );
    await tester.tap(find.bySemanticsLabel('Показать пароль'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isFalse,
    );
    expect(find.bySemanticsLabel('Скрыть пароль'), findsOneWidget);
  });

  testWidgets('list group: dividers between rows, none before an attachment', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const DkListGroup(
          children: [
            DkListRow(title: 'Вывод средств', icon: DkIcons.wallet),
            DkListRow(title: 'Язык', icon: DkIcons.languages),
            DkListAttachment(child: Text('switch')),
          ],
        ),
      ),
    );

    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets('a tappable row shows a chevron and reports taps', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(DkListRow(title: 'Вывод средств', onTap: () => taps++)),
    );

    expect(find.byIcon(DkIcons.next), findsOneWidget);
    await tester.tap(find.text('Вывод средств'));
    expect(taps, 1);
  });

  testWidgets('status chips: icon and text per status', (tester) async {
    await tester.pumpWidget(
      wrap(
        const Column(
          children: [
            DkStatusChip(kind: DkStatusKind.pending, label: 'В обработке'),
            DkStatusChip(kind: DkStatusKind.paid, label: 'Выплачено'),
            DkStatusChip(kind: DkStatusKind.rejected, label: 'Отклонено'),
          ],
        ),
      ),
    );

    for (final (icon, label) in [
      (DkIcons.pending, 'В обработке'),
      (DkIcons.saved, 'Выплачено'),
      (DkIcons.rejected, 'Отклонено'),
    ]) {
      expect(find.byIcon(icon), findsOneWidget);
      expect(find.text(label), findsOneWidget);
    }
    final paid = tester.widget<Icon>(find.byIcon(DkIcons.saved));
    expect(paid.color, DkColors.light.success);
  });

  testWidgets('filter chips report the tapped value', (tester) async {
    int? picked;
    await tester.pumpWidget(
      wrap(
        DkFilterChips<int>(
          options: const [
            (value: 0, label: 'Все водители'),
            (value: 2, label: 'Водитель 2'),
          ],
          selected: 0,
          onChanged: (v) => picked = v,
        ),
      ),
    );

    await tester.tap(find.text('Водитель 2'));
    expect(picked, 2);
    expect(tester.getSize(find.text('Водитель 2')).height, lessThan(40));
  });

  testWidgets('dialog: content slot and a disabled primary button', (
    tester,
  ) async {
    var primary = 0;
    await tester.pumpWidget(
      wrap(
        DkDialogView(
          icon: DkIcons.rejected,
          title: 'Отклонить заявку?',
          message: 'Причина видна водителю.',
          content: const Text('reason field'),
          primaryLabel: 'Отклонить',
          primaryEnabled: false,
          onPrimary: () => primary++,
          popOnAction: false,
        ),
      ),
    );

    expect(find.text('reason field'), findsOneWidget);
    await tester.tap(find.text('Отклонить'));
    expect(primary, 0);
  });

  testWidgets('language switch keeps 48 dp tap targets', (tester) async {
    await tester.pumpWidget(
      wrap(
        DkLanguageSwitch(
          languages: const [
            (code: 'ru', name: 'Русский'),
            (code: 'kk', name: 'Қазақша'),
          ],
          selected: 'ru',
          onChanged: (_) {},
        ),
      ),
    );

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    expect(tester.getSize(find.byType(DkSegmentedControl<String>)).height, 56);
  });

  testWidgets('balance card deductions use U+2212, not a hyphen', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const DkBalanceCard(
          label: 'Доступно к выводу',
          amount: 815,
          tiles: [
            (label: 'Безнал', amount: 2400, deduction: false),
            (label: 'Комиссия', amount: 585, deduction: true),
            (label: 'Выведено', amount: 1000, deduction: true),
          ],
        ),
      ),
    );

    final texts = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((r) => r.text.toPlainText())
        .toList();
    expect(texts, contains('\u2212585\u202F₸'));
    expect(texts, contains('\u22121\u202F000\u202F₸'));
    expect(texts, contains('2\u202F400\u202F₸'));
    expect(texts.where((t) => t.contains('-')), isEmpty);
  });

  testWidgets(
    'withdrawal row: amount in moneyM when prominent, one-line subtitle',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          const DkWithdrawalTile(
            amount: 1000,
            prominent: true,
            subtitle:
                'Водитель 2 · 9 окт., 22:34, a very long subtitle '
                'that must stay on one line',
            status: DkStatusChip(
              kind: DkStatusKind.pending,
              label: 'В обработке',
            ),
          ),
        ),
      );

      final amount = tester.widget<RichText>(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText() == '1\u202F000\u202F₸',
        ),
      );
      // Text.rich wraps the money span in the default style; check the span.
      final span = (amount.text as TextSpan).children!.first as TextSpan;
      expect(span.style?.fontSize, DkTypography.standard.moneyM.fontSize);
      final subtitle = tester.widget<RichText>(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().startsWith('Водитель 2'),
        ),
      );
      expect(subtitle.maxLines, 1);
    },
  );

  testWidgets('trip row: the driver has its own line', (tester) async {
    await tester.pumpWidget(
      wrap(
        const DkTripTile(
          nextDayLabel: 'следующий день',
          timeRange: '08:10 – 08:32',
          endsNextDay: false,
          meta: '22 мин · Карта',
          amount: '2\u202F400\u202F₸',
          commission: 'комиссия 360\u202F₸',
          method: DkPaymentMethod.card,
          driver: 'Водитель 1',
        ),
      ),
    );

    final meta = tester.getRect(find.text('22 мин · Карта'));
    final driver = tester.getRect(find.text('Водитель 1'));
    expect(driver.top, greaterThanOrEqualTo(meta.bottom));
  });
}
