import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:office_archiving/cubit/locale_cubit/locale_cubit.dart';
import 'package:office_archiving/l10n/app_localizations.dart';
import 'package:office_archiving/cubit/theme_cubit/theme_cubit.dart';

class CustomAppBarWidgetApp extends StatelessWidget
    implements PreferredSizeWidget {
  const CustomAppBarWidgetApp({
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final locale = context.select((LocaleCubit c) => c.state);
    return AppBar(
      title: Text(AppLocalizations.of(context).appTitle),
      centerTitle: true,
      actions: [
        // Theme switcher
        Builder(builder: (context) {
          final themeState = context.select((ThemeCubit c) => c.state);
          return PopupMenuButton<AppTheme>(
            icon: const Icon(Icons.palette_outlined),
            onSelected: (value) {
              context.read<ThemeCubit>().setTheme(value);
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem<AppTheme>(
                value: AppTheme.light,
                checked: themeState == AppTheme.light,
                child: const Text('Light'),
              ),
              CheckedPopupMenuItem<AppTheme>(
                value: AppTheme.dark,
                checked: themeState == AppTheme.dark,
                child: const Text('Dark'),
              ),
              CheckedPopupMenuItem<AppTheme>(
                value: AppTheme.yellow,
                checked: themeState == AppTheme.yellow,
                child: const Text('Yellow'),
              ),
            ],
          );
        }),
        PopupMenuButton<String>(
          icon: const Icon(Icons.language),
          onSelected: (value) {
            if (value == 'ar') {
              context.read<LocaleCubit>().setLocale(const Locale('ar'));
            } else if (value == 'en') {
              context.read<LocaleCubit>().setLocale(const Locale('en'));
            }
          },
          itemBuilder: (context) => [
            CheckedPopupMenuItem(
              value: 'ar',
              checked: locale.languageCode == 'ar',
              child: const Text('العربية'),
            ),
            CheckedPopupMenuItem(
              value: 'en',
              checked: locale.languageCode == 'en',
              child: const Text('English'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
