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
  static const _prefPrimaryKey = 'custom_primary_color';

  Color? _customPrimary;
  Color? get customPrimary => _customPrimary;

  // ValueNotifier للتحديث الفوري للألوان المخصصة
  final ValueNotifier<Color?> customPrimaryNotifier = ValueNotifier<Color?>(null);

  ThemeCubit({AppTheme? initial}) : super(initial ?? AppTheme.midnight) {
    if (initial == null) {
      _loadTheme();
    }
    _loadCustomPrimary();
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
    ThemeData base;
    switch (state) {
      case AppTheme.system:
        final brightness = MediaQuery.of(context).platformBrightness;
        base = brightness == Brightness.dark ? AppThemes.dark : AppThemes.light;
        break;
      case AppTheme.light:
        base = AppThemes.light;
        break;
      case AppTheme.dark:
        base = AppThemes.dark;
        break;
      case AppTheme.midnight:
        base = AppThemes.midnight;
        break;
      case AppTheme.midnightAurora:
        base = AppThemes.midnightAurora;
        break;
      case AppTheme.glacierBlue:
        base = AppThemes.glacierBlue;
        break;
      case AppTheme.royalRed:
        base = AppThemes.royalRed;
        break;
      case AppTheme.rubyBloom:
        base = AppThemes.rubyBloom;
        break;
      case AppTheme.victorianGold:
        base = AppThemes.victorianGold;
        break;
      case AppTheme.sunsetAmber:
        base = AppThemes.sunsetAmber;
        break;
      case AppTheme.champagneGlow:
        base = AppThemes.champagneGlow;
        break;
      case AppTheme.platinumSilver:
        base = AppThemes.platinumSilver;
        break;
      case AppTheme.onyxGraphite:
        base = AppThemes.onyxGraphite;
        break;
      case AppTheme.jadeForest:
        base = AppThemes.jadeForest;
        break;
      case AppTheme.emeraldLuxe:
        base = AppThemes.emeraldLuxe;
        break;
      case AppTheme.pearlMoon:
        base = AppThemes.pearlMoon;
        break;
    }
    if (_customPrimary != null) {
      final cs = base.colorScheme;
      final modified = cs.copyWith(
        primary: _customPrimary,
        // keep onPrimary readable
      );
      base = base.copyWith(colorScheme: modified,
        appBarTheme: base.appBarTheme.copyWith(foregroundColor: modified.onSurface),
      );
    }
    return base;
  }

  // Legacy getter - defaults to light theme for system
  ThemeData get themeData {
    ThemeData base;
    switch (state) {
      case AppTheme.system:
        base = AppThemes.light; // Fallback when no context available
        break;
      case AppTheme.light:
        base = AppThemes.light;
        break;
      case AppTheme.dark:
        base = AppThemes.dark;
        break;
      case AppTheme.midnight:
        base = AppThemes.midnight;
        break;
      case AppTheme.midnightAurora:
        base = AppThemes.midnightAurora;
        break;
      case AppTheme.glacierBlue:
        base = AppThemes.glacierBlue;
        break;
      case AppTheme.royalRed:
        base = AppThemes.royalRed;
        break;
      case AppTheme.rubyBloom:
        base = AppThemes.rubyBloom;
        break;
      case AppTheme.victorianGold:
        base = AppThemes.victorianGold;
        break;
      case AppTheme.sunsetAmber:
        base = AppThemes.sunsetAmber;
        break;
      case AppTheme.champagneGlow:
        base = AppThemes.champagneGlow;
        break;
      case AppTheme.platinumSilver:
        base = AppThemes.platinumSilver;
        break;
      case AppTheme.onyxGraphite:
        base = AppThemes.onyxGraphite;
        break;
      case AppTheme.jadeForest:
        base = AppThemes.jadeForest;
        break;
      case AppTheme.emeraldLuxe:
        base = AppThemes.emeraldLuxe;
        break;
      case AppTheme.pearlMoon:
        base = AppThemes.pearlMoon;
        break;
    }
    if (_customPrimary != null) {
      final cs = base.colorScheme;
      base = base.copyWith(colorScheme: cs.copyWith(primary: _customPrimary));
    }
    return base;
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

  Future<void> _loadCustomPrimary() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_prefPrimaryKey);
    if (value != null) {
      _customPrimary = Color(value);
      customPrimaryNotifier.value = _customPrimary;
      // re-emit to refresh listeners
      emit(state);
    }
  }

  Future<void> setCustomPrimary(Color? color) async {
    _customPrimary = color;
    customPrimaryNotifier.value = color; // تحديث ValueNotifier فوراً - هذا يحدث التطبيق مباشرة
    final prefs = await SharedPreferences.getInstance();
    if (color == null) {
      await prefs.remove(_prefPrimaryKey);
    } else {
      await prefs.setInt(_prefPrimaryKey, color.toARGB32());
    }
    // لا حاجة لـ emit لأن ValueNotifier يتولى التحديث الفوري
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
