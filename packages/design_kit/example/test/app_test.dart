import 'package:design_kit_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app starts', (tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('Design kit'), findsOneWidget);
  });
}
