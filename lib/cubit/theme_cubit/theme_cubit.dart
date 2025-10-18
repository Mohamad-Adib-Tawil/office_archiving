import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:office_archiving/theme/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme { 
  system, light, dark, yellow, blue, purple, teal, orange, pink, indigo, coral,
  // New gradient themes
  oceanBlue, sunsetOrange, forestGreen, royalPurple, roseGold
}

class ThemeCubit extends Cubit<AppTheme> {
  static const _prefKey = 'app_theme';

  ThemeCubit({AppTheme? initial}) : super(initial ?? AppTheme.indigo) {
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
      case AppTheme.yellow:
        return AppThemes.yellow;
      case AppTheme.blue:
        return AppThemes.blue;
      case AppTheme.purple:
        return AppThemes.purple;
      case AppTheme.teal:
        return AppThemes.teal;
      case AppTheme.orange:
        return AppThemes.orange;
      case AppTheme.pink:
        return AppThemes.pink;
      case AppTheme.indigo:
        return AppThemes.indigo;
      case AppTheme.coral:
        return AppThemes.coral;
      case AppTheme.oceanBlue:
        return AppThemes.oceanBlue;
      case AppTheme.sunsetOrange:
        return AppThemes.sunsetOrange;
      case AppTheme.forestGreen:
        return AppThemes.forestGreen;
      case AppTheme.royalPurple:
        return AppThemes.royalPurple;
      case AppTheme.roseGold:
        return AppThemes.roseGold;
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
      case AppTheme.yellow:
        return AppThemes.yellow;
      case AppTheme.blue:
        return AppThemes.blue;
      case AppTheme.purple:
        return AppThemes.purple;
      case AppTheme.teal:
        return AppThemes.teal;
      case AppTheme.orange:
        return AppThemes.orange;
      case AppTheme.pink:
        return AppThemes.pink;
      case AppTheme.indigo:
        return AppThemes.indigo;
      case AppTheme.coral:
        return AppThemes.coral;
      case AppTheme.oceanBlue:
        return AppThemes.oceanBlue;
      case AppTheme.sunsetOrange:
        return AppThemes.sunsetOrange;
      case AppTheme.forestGreen:
        return AppThemes.forestGreen;
      case AppTheme.royalPurple:
        return AppThemes.royalPurple;
      case AppTheme.roseGold:
        return AppThemes.roseGold;
    }
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null) {
      final parsed = AppTheme.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => AppTheme.indigo,
      );
      emit(parsed);
    }
  }
}
