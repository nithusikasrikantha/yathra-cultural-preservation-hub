import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/pages/elder/story_details_page.dart';

void main() {
  testWidgets('gallery appears before reactions and opens a swipeable viewer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: StoryDetailsPage(
          storyData: {
            'title': 'Harvest',
            'storyText': 'A village memory.',
            'bannerImage': '/uploads/banner.jpg',
            'additionalImages': [
              '/uploads/one.jpg',
              '/uploads/two.jpg',
              '/uploads/three.jpg',
              '/uploads/four.jpg',
              '/uploads/five.jpg',
            ],
          },
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('1 / 6'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-350, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 6'), findsOneWidget);
    await tester.ensureVisible(find.text('Archival Gallery (5)'));
    expect(
      tester.getTopLeft(find.text('Archival Gallery (5)')).dy,
      lessThan(tester.getTopLeft(find.text('24 Likes')).dy),
    );
    await tester.ensureVisible(find.text('Tap to expand'));
    await tester.tap(find.text('Tap to expand'));
    await tester.pumpAndSettle();
    expect(find.text('5 / 6'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets('story details renders and posts with full width button theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
        home: const StoryDetailsPage(
          storyData: {
            'title': 'Village harvest',
            'storyText': 'Our family gathered for the harvest.',
          },
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Village harvest'), findsOneWidget);
    expect(find.text('Our family gathered for the harvest.'), findsOneWidget);

    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(
      find.byType(TextField),
      'I remember this tradition.',
    );
    await tester.ensureVisible(find.text('Post'));
    await tester.tap(find.text('Post'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('I remember this tradition.'), findsOneWidget);
    expect(find.text('3 Comments'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });
}
