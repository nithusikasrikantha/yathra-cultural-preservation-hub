import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

import 'pages/share_story_page.dart';
import 'pages/youth_hub_shell.dart';
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
        '/youth-hub': (context) => const YouthHubShell(),
        '/youth-feed': (context) => const YouthHubShell(),
        '/youth-profile': (context) => const YouthProfilePage(),
        '/youth-saved': (context) => const YouthSavedPostsPage(),
        '/share-story': (context) => const ShareStoryPage(),
      },
      home: const SplashScreen(),
    );
  }
}
