import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundColor = Color(0xFFF5F0E6);
  static const Color primaryColor = Color(0xFF2D1B14);
  static const Color accentColor = Color(0xFFD8CAB8);
  static const Color secondaryTextColor = Color(0xFF6B584E);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        surface: backgroundColor,
        primary: primaryColor,
        secondary: secondaryTextColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: Typography.material2021().black.copyWith(
        displayLarge: const TextStyle(
          fontFamily: 'serif',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
        headlineMedium: const TextStyle(
          fontFamily: 'serif',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
        bodyLarge: const TextStyle(
          fontFamily: 'sans-serif',
          fontSize: 16,
          color: primaryColor,
        ),
        bodyMedium: const TextStyle(
          fontFamily: 'sans-serif',
          fontSize: 14,
          color: secondaryTextColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: backgroundColor,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontFamily: 'sans-serif',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(
          fontFamily: 'sans-serif',
          color: secondaryTextColor.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  static ThemeData get highContrastTheme {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: Colors.black,
          brightness: Brightness.light,
        ).copyWith(
          primary: Colors.black,
          onPrimary: Colors.white,
          secondary: const Color(0xFF004D40),
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
          error: const Color(0xFF9B0000),
          onError: Colors.white,
        );
    return lightTheme.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.white,
      dividerTheme: const DividerThemeData(color: Colors.black, thickness: 1.5),
      inputDecorationTheme: lightTheme.inputDecorationTheme.copyWith(
        fillColor: Colors.white,
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 1.5),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
        hintStyle: const TextStyle(color: Colors.black54),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.black, width: 1.5),
        ),
      ),
    );
  }
}
