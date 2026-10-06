import 'package:design_kit/design_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const _gap = ' ';

void main() {
  late DkMoneyEditingController controller;

  setUp(() => controller = DkMoneyEditingController());
  tearDown(() => controller.dispose());

  Future<void> pumpField(WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(DkTextField.money(label: 'Сумма', controller: controller)),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
  }

  /// Simulates the platform reporting a new editing value (what typing,
  /// deleting and pasting all do); input formatters run on it.
  Future<void> edit(WidgetTester tester, String text, int caret) async {
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: caret),
      ),
    );
    await tester.pump();
  }

  testWidgets('typing 2400 groups as "2 400" with the caret at the end', (
    tester,
  ) async {
    await pumpField(tester);

    for (final digits in ['2', '24', '240', '2400']) {
      // The platform reports the previous (grouped) text plus one digit.
      final typed = controller.text + digits.substring(digits.length - 1);
      await edit(tester, typed, typed.length);
    }

    expect(controller.text, '2${_gap}400');
    expect(controller.selection, const TextSelection.collapsed(offset: 5));
    expect(controller.amount, 2400);
  });

  testWidgets('Backspace across the gap regroups and keeps the caret', (
    tester,
  ) async {
    await pumpField(tester);
    await edit(tester, '12400', 5); // "12 400"
    expect(controller.text, '12${_gap}400');

    // Caret "12 4|00" (offset 4); Backspace removes the 4.
    controller.selection = const TextSelection.collapsed(offset: 4);
    await edit(tester, '12${_gap}00', 3);
    expect(controller.text, '1${_gap}200');
    expect(controller.selection.baseOffset, 3, reason: '"1 2|00"');

    // Backspace again crosses the gap and removes the 2.
    await edit(tester, '1${_gap}00', 2);
    expect(controller.text, '100');
    expect(controller.selection.baseOffset, 1, reason: '"1|00"');
  });

  test('deleting only the separator removes the neighbouring digit', () {
    const formatter = DkMoneyInputFormatter();
    TextEditingValue value(String text, int caret) => TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: caret),
    );

    // Backspace with the caret right after the gap ("12 |400").
    final back = formatter.formatEditUpdate(
      value('12${_gap}400', 3),
      value('12400', 2),
    );
    expect(back.text, '1${_gap}400');
    expect(back.selection.baseOffset, 1);

    // Delete with the caret right before the gap ("12| 400").
    final forward = formatter.formatEditUpdate(
      value('12${_gap}400', 2),
      value('12400', 2),
    );
    expect(forward.text, '1${_gap}200');
    expect(forward.selection.baseOffset, 3);
  });

  testWidgets('Delete right before the gap deletes the digit after it', (
    tester,
  ) async {
    await pumpField(tester);
    await edit(tester, '2400', 4); // "2 400"
    controller.selection = const TextSelection.collapsed(offset: 1);

    // Forward delete at "2| 400" removes the separator only.
    await edit(tester, '2400', 1);

    expect(controller.text, '200');
    expect(controller.selection.baseOffset, 1);
  });

  testWidgets('arrow keys step over the gap in one press', (tester) async {
    await pumpField(tester);
    await edit(tester, '2400', 4); // "2 400"
    controller.selection = const TextSelection.collapsed(offset: 1); // "2| 400"

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(controller.selection.baseOffset, 3, reason: '"2 4|00"');

    // Left from "2 4|00" stops once, in front of the gap ("2| 400"):
    // the two positions around a gap are a single stop.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(controller.selection.baseOffset, 1, reason: '"2| 400"');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(controller.selection.baseOffset, 0, reason: '"|2 400"');
  });

  testWidgets('paste keeps digits only and regroups', (tester) async {
    await pumpField(tester);

    await edit(tester, '12 345 ₸', 8);

    expect(controller.text, '12${_gap}345');
    expect(controller.amount, 12345);
    expect(controller.selection.baseOffset, 6);
  });

  testWidgets('leading zeros drop, a single 0 stays, length is capped', (
    tester,
  ) async {
    await pumpField(tester);

    await edit(tester, '0', 1);
    expect(controller.text, '0');
    await edit(tester, '007', 3);
    expect(controller.text, '7');
    await edit(tester, '123456789', 9); // 9 digits > 8: rejected
    expect(controller.text, '7');
  });

  testWidgets('field draws the same widened gap as DkMoneyText', (
    tester,
  ) async {
    await pumpField(tester);
    await edit(tester, '2400', 4);

    final span = controller.buildTextSpan(
      context: tester.element(find.byType(TextField)),
      style: const TextStyle(fontSize: 22),
      withComposing: false,
    );
    final display = TextSpan(
      style: const TextStyle(fontSize: 22),
      children: dkGroupedSpans('2${_gap}400', const TextStyle(fontSize: 22)),
    );
    expect(span.toPlainText(), '2${_gap}400', reason: 'string unchanged');
    expect(span.children, display.children);
  });
}
