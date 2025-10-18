import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleCubit extends Cubit<Locale> {
  static const _prefKey = 'app_locale';

  LocaleCubit({Locale? initial}) : super(initial ?? const Locale('en')) {
    if (initial == null) {
      _loadLocale();
    }
  }

  Future<void> setLocale(Locale locale) async {
    emit(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale.languageCode);
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null) {
      emit(Locale(saved));
    }
  }

  Future<void> toggle() {
    final next = state.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
    return setLocale(next);
  }
}
