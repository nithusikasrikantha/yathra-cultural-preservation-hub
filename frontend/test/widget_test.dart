import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('YATHRA app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const YathraApp());

    expect(find.text('Share Your Story'), findsOneWidget);
    expect(find.text('Story Title'), findsOneWidget);
  });
}
