import 'package:design_kit/design_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every interactive component on one screen.
class _Gallery extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(context.dkSpacing.md),
          children: <Widget>[
            DkDaySwitcher(
              label: '1 октября',
              onPrevious: () {},
              onNext: () {},
              onPick: () {},
            ),
            const DkSummaryTile.money(
              label: 'Чистыми',
              amount: 3315,
              tone: DkTone.positive,
              emphasis: DkSummaryEmphasis.hero,
            ),
            DkTripTile(
              timeRange: '08:10 – 08:32',
              amount: 2400,
              payment: DkPaymentKind.card,
              onTap: () {},
            ),
            DkButton(label: 'Добавить поездку', onPressed: () {}),
            DkButton(
              label: 'Отмена',
              onPressed: () {},
              variant: DkButtonVariant.secondary,
            ),
            const DkTextField(label: 'Сумма', suffixText: '₸'),
            DkSegmentedControl<DkPaymentKind>(
              label: 'Оплата',
              segments: [
                for (final kind in DkPaymentKind.values)
                  DkSegment(value: kind, label: kind.label),
              ],
              selected: DkPaymentKind.cash,
              onChanged: (_) {},
            ),
            DkErrorState(onRetry: () {}),
          ].expand((w) => [w, SizedBox(height: context.dkSpacing.md)]).toList(),
        ),
      ),
    );
  }
}

void main() {
  for (final (name, theme) in [
    ('light', DkTheme.light()),
    ('dark', DkTheme.dark()),
  ]) {
    testWidgets('$name: meets Flutter accessibility guidelines', (
      tester,
    ) async {
      // The guidelines inspect painted pixels, so the whole gallery must be
      // on screen; off-screen rows keep semantics nodes but are not painted.
      tester.view
        ..physicalSize = const Size(800, 2400)
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
