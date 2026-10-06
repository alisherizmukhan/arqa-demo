import 'package:driver_diary/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app starts', (tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('Дневник смены'), findsOneWidget);
  });
}
