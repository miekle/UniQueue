import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Edit these to change colors app-wide.
class AppColors {
  AppColors._();

  /// Primary brand (buttons, links, accents).
  static const Color primary = Color(0xFF0F6F44);

  /// Filled button label color.
  static const Color onPrimary = Colors.white;

  /// Screen backgrounds.
  static const Color scaffold = Color.fromARGB(255, 250, 250, 250);

  /// Main body text.
  static const Color onSurface = Color(0xFF000000);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 13, 95, 65),
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          surface: AppColors.scaffold,
          onSurface: AppColors.onSurface,
        ),
    scaffoldBackgroundColor: AppColors.scaffold,
    textTheme: GoogleFonts.lexendDecaTextTheme(),
    primaryTextTheme: GoogleFonts.lexendDecaTextTheme(
      ThemeData.light().primaryTextTheme,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color.fromARGB(255, 106, 107, 110),
      ),
    ),
  );

  return base;
}
