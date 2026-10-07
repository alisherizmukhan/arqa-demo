import 'package:design_kit/design_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every interactive component on one screen.
class _Gallery extends StatefulWidget {
  const new();

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _amount = DkMoneyEditingController(amount: 2400);

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    return Scaffold(
      floatingActionButton: DkFab(
        label: 'Поездка',
        icon: DkIcons.add,
        onPressed: () {},
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(spacing.s16),
          children: <Widget>[
            DkDaySwitcher(
              date: oct(1),
              today: oct(6),
              onPrev: () {},
              onNext: () {},
              onPickDate: () {},
            ),
            const DkSummaryCard(
              net: 3315,
              revenue: 3900,
              commission: 585,
              tripsCount: 2,
            ),
            const DkPaymentCard(cash: 1500, card: 2400),
            DkWordmark(trailing: DkTodayButton(onPressed: () {})),
            DkListHeader(
              title: 'Поездки',
              trailing: '2 поездки · 37 мин',
              action: DkIconButton(
                icon: DkIcons.sort,
                label: 'Сортировка: сначала ранние',
                onPressed: () {},
              ),
            ),
            const DkOptionsSheet<int>(
              title: 'Сортировка',
              options: [
                (value: 0, label: 'Сначала ранние'),
                (value: 1, label: 'Сначала поздние'),
              ],
              selected: 0,
            ),
            const DkTripList(
              children: [
                DkTripTile(
                  timeRange: '08:10 – 08:32',
                  endsNextDay: false,
                  meta: '22 мин · Карта',
                  amount: '2 400 ₸',
                  commission: 'комиссия 360 ₸',
                  method: DkPaymentMethod.card,
                ),
              ],
            ),
            DkButton(label: 'Сохранить', expand: true, onPressed: () {}),
            DkButton(
              label: 'Сохранить как новую поездку',
              variant: DkButtonVariant.secondary,
              onPressed: () {},
            ),
            DkTimeField(
              label: 'Окончание',
              value: '00:20',
              onTap: () {},
              trailing: const DkBadge('+1 день'),
            ),
            DkTextField.money(label: 'Сумма', controller: _amount),
            DkSegmentedControl<DkPaymentMethod>(
              label: 'Способ оплаты',
              segments: [
                for (final m in DkPaymentMethod.values)
                  DkSegment(value: m, label: m.label, icon: m.icon),
              ],
              selected: DkPaymentMethod.card,
              onChanged: (_) {},
            ),
            DkErrorState(title: 'Не удалось загрузить данные', onRetry: () {}),
          ].expand((w) => [w, SizedBox(height: spacing.s16)]).toList(),
        ),
      ),
    );
  }
}

/// A day in October 2026.
DateTime oct(int day) => DateTime(2026, 10, day);

void main() {
  for (final (name, theme) in [
    ('light', DkTheme.light()),
    ('dark', DkTheme.dark()),
  ]) {
    testWidgets('$name: meets Flutter accessibility guidelines', (
      tester,
    ) async {
      // Guidelines inspect painted pixels: the whole gallery must be visible.
      tester.view
        ..physicalSize = const Size(800, 2600)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(theme: theme, home: const _Gallery()),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  }
}
