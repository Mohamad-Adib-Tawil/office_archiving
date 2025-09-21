import 'package:flutter/material.dart';
import 'package:office_archiving/constants.dart';

class AppThemes {
  static final ThemeData light = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
    useMaterial3: true,
    fontFamily: kFontGTSectraFine,
    brightness: Brightness.light,
  );

  static final ThemeData dark = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor, brightness: Brightness.dark),
    useMaterial3: true,
    fontFamily: kFontGTSectraFine,
    brightness: Brightness.dark,
  );

  static final ThemeData yellow = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
    useMaterial3: true,
    fontFamily: kFontGTSectraFine,
    brightness: Brightness.light,
    appBarTheme: const AppBarTheme(backgroundColor: Colors.amber),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Colors.amber),
  );
}
