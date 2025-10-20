import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:office_archiving/theme/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme {
  system,
  light,
  dark,
  midnight,
  midnightAurora,
  glacierBlue,
  royalRed,
  rubyBloom,
  victorianGold,
  sunsetAmber,
  champagneGlow,
  platinumSilver,
  onyxGraphite,
  jadeForest,
  emeraldLuxe,
  pearlMoon,
}

class ThemeCubit extends Cubit<AppTheme> {
  static const _prefKey = 'app_theme';

  ThemeCubit({AppTheme? initial}) : super(initial ?? AppTheme.midnight) {
    if (initial == null) {
      _loadTheme();
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    emit(theme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, theme.name);
  }

  void cycle() {
    const values = AppTheme.values;
    final nextIndex = (values.indexOf(state) + 1) % values.length;
    // Persist as well
    setTheme(values[nextIndex]);
  }

  ThemeData themeDataFor(BuildContext context) {
    switch (state) {
      case AppTheme.system:
        final brightness = MediaQuery.of(context).platformBrightness;
        return brightness == Brightness.dark ? AppThemes.dark : AppThemes.light;
      case AppTheme.light:
        return AppThemes.light;
      case AppTheme.dark:
        return AppThemes.dark;
      case AppTheme.midnight:
        return AppThemes.midnight;
      case AppTheme.midnightAurora:
        return AppThemes.midnightAurora;
      case AppTheme.glacierBlue:
        return AppThemes.glacierBlue;
      case AppTheme.royalRed:
        return AppThemes.royalRed;
      case AppTheme.rubyBloom:
        return AppThemes.rubyBloom;
      case AppTheme.victorianGold:
        return AppThemes.victorianGold;
      case AppTheme.sunsetAmber:
        return AppThemes.sunsetAmber;
      case AppTheme.champagneGlow:
        return AppThemes.champagneGlow;
      case AppTheme.platinumSilver:
        return AppThemes.platinumSilver;
      case AppTheme.onyxGraphite:
        return AppThemes.onyxGraphite;
      case AppTheme.jadeForest:
        return AppThemes.jadeForest;
      case AppTheme.emeraldLuxe:
        return AppThemes.emeraldLuxe;
      case AppTheme.pearlMoon:
        return AppThemes.pearlMoon;
    }
  }

  // Legacy getter - defaults to light theme for system
  ThemeData get themeData {
    switch (state) {
      case AppTheme.system:
        return AppThemes.light; // Fallback when no context available
      case AppTheme.light:
        return AppThemes.light;
      case AppTheme.dark:
        return AppThemes.dark;
      case AppTheme.midnight:
        return AppThemes.midnight;
      case AppTheme.midnightAurora:
        return AppThemes.midnightAurora;
      case AppTheme.glacierBlue:
        return AppThemes.glacierBlue;
      case AppTheme.royalRed:
        return AppThemes.royalRed;
      case AppTheme.rubyBloom:
        return AppThemes.rubyBloom;
      case AppTheme.victorianGold:
        return AppThemes.victorianGold;
      case AppTheme.sunsetAmber:
        return AppThemes.sunsetAmber;
      case AppTheme.champagneGlow:
        return AppThemes.champagneGlow;
      case AppTheme.platinumSilver:
        return AppThemes.platinumSilver;
      case AppTheme.onyxGraphite:
        return AppThemes.onyxGraphite;
      case AppTheme.jadeForest:
        return AppThemes.jadeForest;
      case AppTheme.emeraldLuxe:
        return AppThemes.emeraldLuxe;
      case AppTheme.pearlMoon:
        return AppThemes.pearlMoon;
    }
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null) {
      try {
        final parsed = AppTheme.values.firstWhere((e) => e.name == saved);
        emit(parsed);
        return;
      } catch (_) {
        emit(_legacyThemeFromString(saved));
      }
    }
  }

  AppTheme _legacyThemeFromString(String value) {
    switch (value) {
      case 'blue':
      case 'indigo':
      case 'oceanBlue':
        return AppTheme.midnightAurora;
      case 'teal':
      case 'forestGreen':
        return AppTheme.jadeForest;
      case 'emerald':
      case 'emeraldLuxe':
        return AppTheme.emeraldLuxe;
      case 'purple':
      case 'royalPurple':
        return AppTheme.royalRed;
      case 'pink':
      case 'roseGold':
        return AppTheme.rubyBloom;
      case 'coral':
      case 'sunsetOrange':
        return AppTheme.sunsetAmber;
      case 'yellow':
      case 'orange':
        return AppTheme.champagneGlow;
      default:
        return AppTheme.midnight;
    }
  }
}
