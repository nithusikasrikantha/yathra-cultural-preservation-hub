import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/config/api_config.dart';
import 'package:frontend/models/story.dart';
import 'package:frontend/widgets/social_story_card.dart';

void main() {
  testWidgets('feed displays uploaded banner and metadata on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: SocialStoryCard(
                authorName: 'Sanjeevan',
                onTap: () => opened++,
                story: Story(
                  id: 'story',
                  title: 'Village Harvest',
                  category: 'Traditional Story',
                  language: 'Tamil',
                  storyText: 'A memory from our village.',
                  aiSummary: 'An approved preview of village memories.',
                  summaryStatus: 'approved',
                  bannerImage: '/uploads/banner.jpg',
                  additionalImages: const ['/uploads/one.jpg'],
                  location: 'Jaffna',
                  timePeriod: 'My childhood',
                  createdAt: DateTime.now().subtract(const Duration(hours: 3)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    final provider =
        tester.widget<Image>(find.byType(Image)).image as NetworkImage;
    expect(provider.url, '${ApiConfig.baseUrl}/uploads/banner.jpg');
    expect(find.text('2 photos'), findsOneWidget);
    expect(find.text('Jaffna'), findsOneWidget);
    expect(
      find.text('An approved preview of village memories.'),
      findsOneWidget,
    );
    expect(find.text('A memory from our village.'), findsNothing);
    expect(
      tester.getTopLeft(find.byType(Image)).dy,
      lessThan(tester.getTopLeft(find.text('Traditional Story')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Traditional Story')).dy,
      lessThan(tester.getTopLeft(find.text('Village Harvest')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Village Harvest')).dy,
      lessThan(
        tester
            .getTopLeft(find.text('An approved preview of village memories.'))
            .dy,
      ),
    );
    expect(find.text('3h ago'), findsOneWidget);
    await tester.ensureVisible(find.text('Like'));
    await tester.tap(find.text('Like'));
    await tester.pump();
    expect(find.text('Liked'), findsOneWidget);
    expect(opened, 0);
    await tester.tap(find.text('Comment'));
    expect(opened, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text only stories render without a blank image area', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SocialStoryCard(
            onTap: () {},
            story: const Story(
              id: 'text',
              title: 'A proverb',
              category: 'Proverb',
              language: 'Tamil',
              storyText: 'Wisdom from our elders.',
            ),
          ),
        ),
      ),
    );
    expect(find.byType(Image), findsNothing);
    expect(find.text('A proverb'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
