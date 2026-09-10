import 'package:flutter/material.dart';
import 'pages/share_story_page.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F3EA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B4226),
          primary: const Color(0xFF6B4226),
          surface: const Color(0xFFF8F3EA),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6B4226),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const ShareStoryPage(),
    );
  }
}
