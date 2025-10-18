import 'package:flutter/material.dart';
import 'package:office_archiving/constants.dart';

class AppThemes {
  static final ThemeData light = _baseTheme(Brightness.light, seed: kPrimaryColor);

  static final ThemeData dark = _baseTheme(Brightness.dark, seed: kPrimaryColor);

  static final ThemeData yellow = _baseTheme(Brightness.light, seed: Colors.amber);
  static final ThemeData blue = _baseTheme(Brightness.light, seed: Colors.blue);
  static final ThemeData purple = _baseTheme(Brightness.light, seed: Colors.purple);
  static final ThemeData teal = _baseTheme(Brightness.light, seed: Colors.teal);
  static final ThemeData orange = _baseTheme(Brightness.light, seed: Colors.orange);
  static final ThemeData pink = _baseTheme(Brightness.light, seed: Colors.pink);
  static final ThemeData indigo = _baseTheme(Brightness.light, seed: Colors.indigo);

  static ThemeData _baseTheme(Brightness brightness, {required Color seed}) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    final isDark = brightness == Brightness.dark;
    final surface = scheme.surface;
    final onSurface = scheme.onSurface;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: kFontGTSectraFine,
      scaffoldBackgroundColor: isDark ? const Color(0xFF0F1115) : const Color(0xFFFAFAFA),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: surface,
        foregroundColor: onSurface,
        titleTextStyle: TextStyle(
          fontFamily: kFontGTSectraFine,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        margin: EdgeInsets.all(8),
      ).copyWith(
        color: isDark ? const Color(0xFF1A1D22) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: Typography.material2021(platform: TargetPlatform.android)
          .black
          .apply(
            bodyColor: onSurface.withOpacity(isDark ? 0.9 : 0.95),
            displayColor: onSurface,
          )
          .copyWith(
            bodyLarge: TextStyle(height: 1.5, color: onSurface.withOpacity(0.9)),
            titleMedium: TextStyle(fontWeight: FontWeight.w600, color: onSurface),
          ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF15191E) : const Color(0xFFF3F5F7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
