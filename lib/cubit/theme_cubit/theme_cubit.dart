import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:office_archiving/theme/themes.dart';

enum AppTheme { light, dark, yellow }

class ThemeCubit extends Cubit<AppTheme> {
  ThemeCubit() : super(AppTheme.light);

  void setTheme(AppTheme theme) => emit(theme);
  void cycle() {
    switch (state) {
      case AppTheme.light:
        emit(AppTheme.dark);
        break;
      case AppTheme.dark:
        emit(AppTheme.yellow);
        break;
      case AppTheme.yellow:
        emit(AppTheme.light);
        break;
    }
  }

  ThemeData get themeData {
    switch (state) {
      case AppTheme.light:
        return AppThemes.light;
      case AppTheme.dark:
        return AppThemes.dark;
      case AppTheme.yellow:
        return AppThemes.yellow;
    }
  }
}
