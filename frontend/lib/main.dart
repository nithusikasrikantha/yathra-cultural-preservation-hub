import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

import 'pages/share_story_page.dart';
import 'pages/youth_feed_page.dart';
import 'pages/youth_profile_page.dart';
import 'pages/youth_saved_posts_page.dart';

void main() {
  runApp(const YathraApp());
}

class YathraApp extends StatelessWidget {
  const YathraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'YATHRA',
      theme: AppTheme.lightTheme,
      routes: {
        '/youth-feed': (context) => const YouthFeedPage(),
        '/youth-profile': (context) => const YouthProfilePage(),
        '/youth-saved': (context) => const YouthSavedPostsPage(),
        '/share-story': (context) => const ShareStoryPage(),
      },
      home: const SplashScreen(),
    );
  }
}
