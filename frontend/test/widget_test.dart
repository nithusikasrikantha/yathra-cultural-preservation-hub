import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('YathraApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const YathraApp());
    expect(find.text('Share Your Story'), findsOneWidget);
  });
}
