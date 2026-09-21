import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        background: backgroundColor,
        surface: backgroundColor,
        primary: primaryColor,
        secondary: secondaryTextColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.playfairDisplayTextTheme().copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: primaryColor,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: secondaryTextColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: backgroundColor,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        hintStyle: GoogleFonts.inter(
          color: secondaryTextColor.withOpacity(0.5),
        ),
      ),
    );
  }
}
