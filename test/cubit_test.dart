import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_archiving/cubit/theme_cubit/theme_cubit.dart';
import 'package:office_archiving/cubit/locale_cubit/locale_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeCubit', () {
    late ThemeCubit themeCubit;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      themeCubit = ThemeCubit();
    });

    tearDown(() {
      themeCubit.close();
    });

    test('initial state is AppTheme.midnight', () {
      expect(themeCubit.state, AppTheme.midnight);
    });

    test('setTheme changes state', () async {
      await themeCubit.setTheme(AppTheme.glacierBlue);
      expect(themeCubit.state, AppTheme.glacierBlue);
    });

    test('cycle changes theme', () {
      final initialTheme = themeCubit.state;
      themeCubit.cycle();
      expect(themeCubit.state, isNot(initialTheme));
    });

    test('theme persistence works', () async {
      await themeCubit.setTheme(AppTheme.sunsetAmber);
      
      // Create new cubit to test loading
      final newCubit = ThemeCubit();
      await Future.delayed(const Duration(milliseconds: 100)); // Wait for async load
      expect(newCubit.state, AppTheme.sunsetAmber);
      newCubit.close();
    });
  });

  group('LocaleCubit', () {
    late LocaleCubit localeCubit;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      localeCubit = LocaleCubit();
    });

    tearDown(() {
      localeCubit.close();
    });

    test('initial state is Locale(en)', () {
      expect(localeCubit.state, const Locale('en'));
    });

    test('setLocale changes state', () async {
      await localeCubit.setLocale(const Locale('ar'));
      expect(localeCubit.state, const Locale('ar'));
    });

    test('toggle switches between ar and en', () async {
      await localeCubit.setLocale(const Locale('ar'));
      await localeCubit.toggle();
      expect(localeCubit.state, const Locale('en'));
      
      await localeCubit.toggle();
      expect(localeCubit.state, const Locale('ar'));
    });

    test('locale persistence works', () async {
      await localeCubit.setLocale(const Locale('ar'));
      
      // Create new cubit to test loading
      final newCubit = LocaleCubit();
      await Future.delayed(const Duration(milliseconds: 100)); // Wait for async load
      expect(newCubit.state, const Locale('ar'));
      newCubit.close();
    });
  });
}
