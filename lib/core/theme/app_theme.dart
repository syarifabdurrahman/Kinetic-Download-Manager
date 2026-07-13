import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color surface = Color(0xFF0b1326);
  static const Color surfaceDim = Color(0xFF0b1326);
  static const Color surfaceBright = Color(0xFF31394d);
  static const Color surfaceContainerLowest = Color(0xFF060e20);
  static const Color surfaceContainerLow = Color(0xFF131b2e);
  static const Color surfaceContainer = Color(0xFF171f33);
  static const Color surfaceContainerHigh = Color(0xFF222a3d);
  static const Color surfaceContainerHighest = Color(0xFF2d3449);
  static const Color onSurface = Color(0xFFdae2fd);
  static const Color onSurfaceVariant = Color(0xFFc1c6d7);
  static const Color inverseSurface = Color(0xFFdae2fd);
  static const Color inverseOnSurface = Color(0xFF283044);
  static const Color outline = Color(0xFF8b90a0);
  static const Color outlineVariant = Color(0xFF414755);
  static const Color surfaceTint = Color(0xFFadc6ff);
  static const Color primary = Color(0xFFadc6ff);
  static const Color onPrimary = Color(0xFF002e69);
  static const Color primaryContainer = Color(0xFF4b8eff);
  static const Color onPrimaryContainer = Color(0xFF00285c);
  static const Color secondary = Color(0xFFc2c1ff);
  static const Color onSecondary = Color(0xFF1c0b9f);
  static const Color secondaryContainer = Color(0xFF3834b6);
  static const Color onSecondaryContainer = Color(0xFFb2b1ff);
  static const Color tertiary = Color(0xFF00dce6);
  static const Color onTertiary = Color(0xFF00373a);
  static const Color tertiaryContainer = Color(0xFF00a0a9);
  static const Color onTertiaryContainer = Color(0xFF002f32);
  static const Color error = Color(0xFFffb4ab);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000a);
  static const Color onErrorContainer = Color(0xFFffdad6);
  static const Color background = Color(0xFF0b1326);
  static const Color onBackground = Color(0xFFdae2fd);
  static const Color surfaceVariant = Color(0xFF2d3449);

  static var textTheme = GoogleFonts.plusJakartaSansTextTheme(
    const TextTheme(
      displayLarge: TextStyle(
        fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -0.02,
      ),
      headlineLarge: TextStyle(
        fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.01,
      ),
      titleMedium: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w600,
      ),
      bodyMedium: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w400,
      ),
      labelSmall: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.05,
      ),
    ),
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: surface, primary: primary, secondary: secondary,
        tertiary: tertiary, error: error, outline: outline,
      ),
      textTheme: textTheme.apply(bodyColor: onSurface, displayColor: onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: false,
        titleTextStyle: textTheme.headlineLarge?.copyWith(fontSize: 24),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainer, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryContainer, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryContainer, width: 1),
        ),
        hintStyle: const TextStyle(color: onSurfaceVariant),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent, elevation: 0,
        selectedItemColor: primary, unselectedItemColor: outline,
      ),
    );
  }
}
