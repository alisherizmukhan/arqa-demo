import 'package:design_kit/design_kit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A button that opens a sheet and shows what it returned.
class _Opener<T> extends StatefulWidget {
  const new(this.open);

  final Future<T?> Function(BuildContext context) open;

  @override
  State<_Opener<T>> createState() => _OpenerState<T>();
}

class _OpenerState<T> extends State<_Opener<T>> {
  String result = 'none';

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () async {
          final value = await widget.open(context);
          setState(() => result = '$value');
        },
        child: Text('open · $result'),
      ),
    ),
  );
}

void main() {
  Future<void> pumpOpener<T>(
    WidgetTester tester,
    Future<T?> Function(BuildContext context) open,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: DkTheme.light(), home: _Opener<T>(open)),
    );
    await tester.tap(find.textContaining('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('time picker: wheel value, «Готово» returns it', (tester) async {
    await pumpOpener<({int hour, int minute})>(
      tester,
      (context) => showDkTimePicker(
        doneLabel: 'Готово',
        context,
        hour: 8,
        minute: 10,
        title: 'Начало поездки',
      ),
    );
    expect(find.text('Начало поездки'), findsOneWidget);
    final wheel = tester.widget<CupertinoDatePicker>(
      find.byType(CupertinoDatePicker),
    );
    expect(wheel.use24hFormat, isTrue);
    expect(wheel.initialDateTime, DateTime(2000, 1, 1, 8, 10));
    wheel.onDateTimeChanged(DateTime(2000, 1, 1, 23, 50));
    await tester.tap(find.text('Готово'));
    await tester.pumpAndSettle();
    expect(find.text('open · (hour: 23, minute: 50)'), findsOneWidget);
  });

  testWidgets('date picker: clamps to the range; «Сегодня» picks lastDate', (
    tester,
  ) async {
    await pumpOpener<DateTime>(
      tester,
      (context) => showDkDatePicker(
        title: 'Выберите дату',
        doneLabel: 'Готово',
        context,
        initialDate: DateTime(2026, 10, 9),
        firstDate: DateTime(2000),
        lastDate: DateTime(2026, 10, 6, 15, 30),
        todayLabel: 'Сегодня',
      ),
    );
    final wheel = tester.widget<CupertinoDatePicker>(
      find.byType(CupertinoDatePicker),
    );
    expect(wheel.initialDateTime, DateTime(2026, 10, 6));
    expect(wheel.maximumDate, DateTime(2026, 10, 6));
    wheel.onDateTimeChanged(DateTime(2026, 9));
    await tester.pump();
    await tester.tap(find.text('Сегодня'));
    await tester.pump();
    await tester.tap(find.text('Готово'));
    await tester.pumpAndSettle();
    expect(find.text('open · 2026-10-06 00:00:00.000'), findsOneWidget);
  });

  testWidgets('a dismissed picker returns null', (tester) async {
    await pumpOpener<DateTime>(
      tester,
      (context) => showDkDatePicker(
        title: 'Выберите дату',
        doneLabel: 'Готово',
        context,
        initialDate: DateTime(2026, 10),
        firstDate: DateTime(2000),
        lastDate: DateTime(2026, 10, 6),
      ),
    );
    await tester.tapAt(const Offset(20, 20)); // the scrim
    await tester.pumpAndSettle();
    expect(find.text('open · null'), findsOneWidget);
  });

  testWidgets('options sheet: check on the current one, tap returns', (
    tester,
  ) async {
    await pumpOpener<int>(
      tester,
      (context) => showDkOptionsSheet<int>(
        context,
        title: 'Сортировка',
        options: const [
          (value: 0, label: 'Ранние'),
          (value: 1, label: 'Поздние'),
        ],
        selected: 0,
      ),
    );
    final check = find.byIcon(DkIcons.check);
    expect(check, findsOneWidget);
    expect(
      tester.getCenter(check).dy,
      closeTo(tester.getCenter(find.text('Ранние')).dy, 1),
    );
    await tester.tap(find.text('Поздние'));
    await tester.pumpAndSettle();
    expect(find.text('open · 1'), findsOneWidget);
  });

  testWidgets('icon button: 48×48, spoken label, accent when active', (
    tester,
  ) async {
    var taps = 0;
    Widget button({required bool active}) => MaterialApp(
      theme: DkTheme.light(),
      home: Scaffold(
        body: Center(
          child: DkIconButton(
            icon: DkIcons.sort,
            label: 'Сортировка',
            active: active,
            onPressed: () => taps++,
          ),
        ),
      ),
    );
    await tester.pumpWidget(button(active: false));
    expect(tester.getSize(find.byType(DkIconButton)), const Size(48, 48));
    final idle = tester.widget<Icon>(find.byIcon(DkIcons.sort)).color;
    await tester.tap(find.bySemanticsLabel('Сортировка'));
    expect(taps, 1);

    await tester.pumpWidget(button(active: true));
    final active = tester.widget<Icon>(find.byIcon(DkIcons.sort)).color;
    expect(active, DkColors.light.accent);
    expect(idle, DkColors.light.textPrimary);
  });

  testWidgets('today button: 48 high, label, tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: DkTheme.light(),
        home: Scaffold(
          body: DkWordmark(
            title: 'Дневник смен',
            trailing: DkTodayButton(label: 'Сегодня', onPressed: () => taps++),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(DkTodayButton)).height, 48);
    await tester.tap(find.bySemanticsLabel('Сегодня'));
    expect(taps, 1);
  });

  testWidgets('dialog: icon, title and message are centred', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: DkTheme.light(),
        home: Scaffold(
          body: DkDialogView(
            icon: DkIcons.alert,
            title: 'Закрыть без сохранения?',
            message: 'Введённые данные поездки не сохранятся.',
            primaryLabel: 'Продолжить ввод',
            onPrimary: () {},
            popOnAction: false,
          ),
        ),
      ),
    );
    final card = tester.getRect(
      find
          .ancestor(
            of: find.text('Закрыть без сохранения?'),
            matching: find.byType(Container),
          )
          .first,
    );
    for (final part in [
      find.byIcon(DkIcons.alert),
      find.text('Закрыть без сохранения?'),
      find.text('Введённые данные поездки не сохранятся.'),
    ]) {
      expect(tester.getCenter(part).dx, closeTo(card.center.dx, 0.5));
    }
  });
}
