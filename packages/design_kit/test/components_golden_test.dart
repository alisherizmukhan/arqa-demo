// Goldens for the DESIGN.md §7 component list, light and dark.
// goldenTest registers tests; its Future need not be awaited.
// ignore_for_file: discarded_futures
import 'package:alchemist/alchemist.dart';
import 'package:design_kit/design_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

/// A scenario per theme, 390 dp wide (the mockups' frame).
GoldenTestGroup _themes(Widget Function() child, {double width = 390}) {
  return GoldenTestGroup(
    columns: 2,
    children: [
      for (final (name, theme) in [
        ('light', DkTheme.light()),
        ('dark', DkTheme.dark()),
      ])
        GoldenTestScenario(
          name: name,
          constraints: BoxConstraints.tightFor(width: width),
          child: themed(theme, child()),
        ),
    ],
  );
}

DkTripTile _trip({
  required String start,
  required String end,
  required String meta,
  required int amount,
  required int commission,
  required DkPaymentMethod method,
  bool endsNextDay = false,
  bool highlighted = false,
}) => DkTripTile(
  timeRange: DkFormat.timeRange(start, end),
  endsNextDay: endsNextDay,
  meta: meta,
  amount: DkMoney.format(amount),
  commission: 'комиссия ${DkMoney.format(commission)}',
  method: method,
  highlighted: highlighted,
);

class _Fields extends StatefulWidget {
  const new();

  @override
  State<_Fields> createState() => _FieldsState();
}

class _FieldsState extends State<_Fields> {
  final _default = DkMoneyEditingController(amount: 360);
  final _focused = DkMoneyEditingController(amount: 2400);
  final _error = DkMoneyEditingController(amount: 0);

  @override
  void dispose() {
    _default.dispose();
    _focused.dispose();
    _error.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    spacing: context.dkSpacing.s20,
    children: [
      DkTextField.money(
        label: 'Комиссия',
        controller: _default,
        helper: 'На руки с поездки: ${DkMoney.format(2040)}',
      ),
      DkTextField.money(
        label: 'Сумма',
        controller: _focused,
        helper: 'Сколько заплатил пассажир',
        autofocus: true,
      ),
      DkTextField.money(
        label: 'Сумма',
        controller: _error,
        errorText: 'Сумма должна быть больше 0',
      ),
    ],
  );
}

/// A day in October 2026.
DateTime oct(int day) => DateTime.utc(2026, 10, day);

void main() {
  setUpAll(loadKitFonts);

  goldenTest(
    'DkSummaryCard, reference day',
    fileName: 'summary_card',
    builder: () => _themes(
      () => const DkSummaryCard(
        net: 3315,
        revenue: 3900,
        commission: 585,
        tripsCount: 2,
      ),
    ),
  );

  goldenTest(
    'DkTripTile: card, cash, +1, highlighted',
    fileName: 'trip_tiles',
    builder: () => _themes(
      () => DkTripList(
        children: [
          _trip(
            start: '08:10',
            end: '08:32',
            meta: '22 мин · Карта',
            amount: 2400,
            commission: 360,
            method: DkPaymentMethod.card,
          ),
          _trip(
            start: '09:05',
            end: '09:20',
            meta: '15 мин · Наличные',
            amount: 1500,
            commission: 225,
            method: DkPaymentMethod.cash,
          ),
          _trip(
            start: '23:50',
            end: '00:20',
            meta: '30 мин · Наличные',
            amount: 3000,
            commission: 450,
            method: DkPaymentMethod.cash,
            endsNextDay: true,
          ),
          _trip(
            start: '22:10',
            end: '22:35',
            meta: '25 мин · Карта',
            amount: 2000,
            commission: 300,
            method: DkPaymentMethod.card,
            highlighted: true,
          ),
        ],
      ),
    ),
  );

  // One file per theme: only one field in a widget tree can hold focus.
  for (final (name, theme) in [
    ('light', DkTheme.light()),
    ('dark', DkTheme.dark()),
  ]) {
    goldenTest(
      'DkTextField: default, focused, error ($name)',
      fileName: 'text_fields_$name',
      pumpBeforeTest: (tester) async {
        await tester.pump();
        await tester.pump();
      },
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: name,
            constraints: const BoxConstraints.tightFor(width: 390),
            child: themed(theme, const _Fields()),
          ),
        ],
      ),
    );
  }

  goldenTest(
    'DkButton matrix: variants × enabled/disabled/loading',
    fileName: 'buttons',
    // The loading spinner never settles: capture one fixed frame mid-turn.
    pumpBeforeTest: (tester) => tester.pump(const Duration(milliseconds: 600)),
    builder: () => _themes(
      width: 760,
      () => Builder(
        builder: (context) => Column(
          spacing: context.dkSpacing.s12,
          children: [
            for (final variant in DkButtonVariant.values)
              Row(
                spacing: context.dkSpacing.s8,
                children: [
                  Expanded(
                    child: DkButton(
                      label: 'Сохранить',
                      variant: variant,
                      onPressed: () {},
                    ),
                  ),
                  Expanded(
                    child: DkButton(label: 'Сохранить', variant: variant),
                  ),
                  Expanded(
                    child: DkButton(
                      label: 'Сохраняем…',
                      variant: variant,
                      isLoading: true,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    ),
  );

  goldenTest(
    'DkDaySwitcher: a date and «Сегодня»',
    fileName: 'day_switcher',
    builder: () => _themes(
      () => Builder(
        builder: (context) => Column(
          spacing: context.dkSpacing.s12,
          children: [
            DkDaySwitcher(
              date: oct(1),
              today: oct(6),
              onPrev: () {},
              onNext: () {},
              onPickDate: () {},
            ),
            DkDaySwitcher(
              date: oct(6),
              today: oct(6),
              onPrev: () {},
              onNext: () {},
              onPickDate: () {},
            ),
          ],
        ),
      ),
    ),
  );
}
