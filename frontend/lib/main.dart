import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'services/accessibility_preferences_service.dart';

import 'pages/elder/share_story_page.dart';
import 'pages/explore_page.dart';
import 'pages/youth_hub_shell.dart';
import 'pages/youth_profile_page.dart';
import 'pages/youth_saved_posts_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AccessibilityPreferencesService.instance.load();
  runApp(const YathraApp());
}

class YathraApp extends StatelessWidget {
  const YathraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = AccessibilityPreferencesService.instance;
    return AnimatedBuilder(
      animation: preferences,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'YATHRA',
        theme: preferences.highContrastEnabled
            ? AppTheme.highContrastTheme
            : AppTheme.lightTheme,
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/youth-hub': (context) => const YouthHubShell(),
          '/youth-feed': (context) => const YouthHubShell(),
          '/youth-profile': (context) => const YouthProfilePage(),
          '/youth-saved': (context) => const YouthSavedPostsPage(),
          '/share-story': (context) => const ShareStoryPage(),
          '/explore': (context) => const ExplorePage(),
        },
        home: const SplashScreen(),
      ),
    );
  }
}
