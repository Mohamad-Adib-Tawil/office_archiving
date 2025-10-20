import 'package:flutter/material.dart';
import 'package:office_archiving/constants.dart';

class AppThemes {
  static final ThemeData light = _buildTheme(
    brightness: Brightness.light,
    seed: kPrimaryColor,
    surfaceLight: const Color(0xFFF6F7FB),
  );

  static final ThemeData dark = _buildTheme(
    brightness: Brightness.dark,
    seed: kPrimaryColor,
    surfaceDark: const Color(0xFF0E1218),
  );

  static final ThemeData midnight = _buildTheme(
    brightness: Brightness.dark,
    seed: const Color(0xFF0B2239),
    secondary: const Color(0xFF15375C),
    tertiary: const Color(0xFF3A6EA5),
    surfaceDark: const Color(0xFF0B1725),
  );

  static final ThemeData midnightAurora = _buildTheme(
    brightness: Brightness.dark,
    seed: const Color(0xFF10394F),
    secondary: const Color(0xFF1B5E78),
    tertiary: const Color(0xFF34A0A4),
    surfaceDark: const Color(0xFF102431),
  );

  static final ThemeData glacierBlue = _buildTheme(
    brightness: Brightness.light,
    seed: const Color(0xFF2F6DE1),
    secondary: const Color(0xFF6EA8FE),
    tertiary: const Color(0xFF133E87),
    surfaceLight: const Color(0xFFF2F6FF),
  );

  static final ThemeData royalRed = _buildTheme(
    brightness: Brightness.light,
    seed: const Color(0xFF8B0F24),
    secondary: const Color(0xFFD7263D),
    tertiary: const Color(0xFF5C0011),
    surfaceLight: const Color(0xFFFDF7F8),
  );

  static final ThemeData rubyBloom = _buildTheme(
    brightness: Brightness.light,
    seed: const Color(0xFFC2185B),
    secondary: const Color(0xFFFF7597),
    tertiary: const Color(0xFF8C1737),
    surfaceLight: const Color(0xFFFDF3F6),
  );

  static final ThemeData victorianGold = _buildTheme(
    brightness: Brightness.light,
    seed: const Color(0xFFC6A15B),
    secondary: const Color(0xFFE7C888),
    tertiary: const Color(0xFF8C6D2F),
    surfaceLight: const Color(0xFFFBF5EA),
  );

  static final ThemeData sunsetAmber = _buildTheme(
    brightness: Brightness.light,
    seed: const Color(0xFFFF8C42),
    secondary: const Color(0xFFFFB347),
    tertiary: const Color(0xFFCC5A1C),
    surfaceLight: const Color(0xFFFFF7EF),
  );

  static final ThemeData champagneGlow = _buildTheme(
    brightness: Brightness.light,
    seed: const Color(0xFFF2D16B),
    secondary: const Color(0xFFFFE8A3),
    tertiary: const Color(0xFFBFA14A),
    surfaceLight: const Color(0xFFFFFBF1),
  );

  static final ThemeData platinumSilver = _buildTheme(
    brightness: Brightness.light,
    seed: const Color(0xFFB0BEC5),
    secondary: const Color(0xFFCFD8DC),
    tertiary: const Color(0xFF7B8795),
    surfaceLight: const Color(0xFFF6F7F8),
  );

  static final ThemeData onyxGraphite = _buildTheme(
    brightness: Brightness.dark,
    seed: const Color(0xFF1C1F26),
    secondary: const Color(0xFF2A3039),
    tertiary: const Color(0xFF4E5968),
    surfaceDark: const Color(0xFF151920),
  );

  static final ThemeData jadeForest = _buildTheme(
    brightness: Brightness.dark,
    seed: const Color(0xFF0F3D2E),
    secondary: const Color(0xFF1E6050),
    tertiary: const Color(0xFF2E8A6D),
    surfaceDark: const Color(0xFF0E201A),
  );

  static final ThemeData emeraldLuxe = _buildTheme(
    brightness: Brightness.light,
    seed: const Color(0xFF2BB673),
    secondary: const Color(0xFF1E9E64),
    tertiary: const Color(0xFF0B6B44),
    surfaceLight: const Color(0xFFF1F9F4),
  );

  static final ThemeData pearlMoon = _buildTheme(
    brightness: Brightness.light,
    seed: const Color(0xFFECE5D9),
    secondary: const Color(0xFFFFFFFF),
    tertiary: const Color(0xFFC9C0B1),
    surfaceLight: const Color(0xFFFCFAF7),
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color seed,
    Color? secondary,
    Color? tertiary,
    Color? surfaceLight,
    Color? surfaceDark,
  }) {
    final isDark = brightness == Brightness.dark;

    var scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    scheme = scheme.copyWith(
      secondary: secondary ?? scheme.secondary,
      tertiary: tertiary ?? scheme.tertiary,
    );

    final backgroundSurface = isDark
        ? (surfaceDark ?? const Color(0xFF10151C))
        : (surfaceLight ?? const Color(0xFFF8F9FB));

    scheme = scheme.copyWith(
      surface: backgroundSurface,
      background: backgroundSurface,
      onSurface:
          isDark ? Colors.white.withOpacity(0.92) : scheme.onSurface,
      onPrimary: isDark ? Colors.white : scheme.onPrimary,
    );

    final cardColor = isDark
        ? Color.alphaBlend(Colors.white.withOpacity(0.06), backgroundSurface)
        : Colors.white;
    final inputFill = isDark
        ? Color.alphaBlend(Colors.white.withOpacity(0.04), backgroundSurface)
        : const Color(0xFFF3F5F7);

    final baseTypography = isDark
        ? Typography.material2021(platform: TargetPlatform.android).white
        : Typography.material2021(platform: TargetPlatform.android).black;

    final onSurface = scheme.onSurface;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: kFontGTSectraFine,
      scaffoldBackgroundColor: backgroundSurface,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: backgroundSurface,
        foregroundColor: onSurface,
        titleTextStyle: TextStyle(
          fontFamily: kFontGTSectraFine,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: baseTypography
          .apply(
            bodyColor:
                isDark ? Colors.white.withOpacity(0.9) : onSurface,
            displayColor: onSurface,
          )
          .copyWith(
            titleMedium:
                TextStyle(fontWeight: FontWeight.w600, color: onSurface),
          ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white10 : scheme.outlineVariant,
        thickness: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
