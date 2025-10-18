import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:office_archiving/cubit/locale_cubit/locale_cubit.dart';
import 'package:office_archiving/l10n/app_localizations.dart';
import 'package:office_archiving/cubit/theme_cubit/theme_cubit.dart';
import 'package:office_archiving/constants.dart';

class CustomAppBarWidgetApp extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBarWidgetApp({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final locale = context.select((LocaleCubit c) => c.state);
    final theme = Theme.of(context);
    return AppBar(
      centerTitle: true,
      title: Text(
        AppLocalizations.of(context).appTitle,
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.lg)),
      ),
      elevation: 2,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.08),
              theme.colorScheme.primary.withOpacity(0.02),
            ],
          ),
        ),
      ),
      actions: [
        Builder(builder: (context) {
          final themeState = context.select((ThemeCubit c) => c.state);
          return PopupMenuButton<AppTheme>(
            tooltip: 'Theme',
            icon: const Icon(Icons.palette_outlined),
            onSelected: (value) => context.read<ThemeCubit>().setTheme(value),
            itemBuilder: (context) => [
              CheckedPopupMenuItem<AppTheme>(value: AppTheme.light, checked: themeState == AppTheme.light, child: const Text('Light')),
              CheckedPopupMenuItem<AppTheme>(value: AppTheme.dark, checked: themeState == AppTheme.dark, child: const Text('Dark')),
              CheckedPopupMenuItem<AppTheme>(value: AppTheme.yellow, checked: themeState == AppTheme.yellow, child: const Text('Yellow')),
            ],
          );
        }),
        PopupMenuButton<String>(
          tooltip: 'Language',
          icon: const Icon(Icons.language),
          onSelected: (value) {
            if (value == 'ar') {
              context.read<LocaleCubit>().setLocale(const Locale('ar'));
            } else if (value == 'en') {
              context.read<LocaleCubit>().setLocale(const Locale('en'));
            }
          },
          itemBuilder: (context) => [
            CheckedPopupMenuItem(value: 'ar', checked: locale.languageCode == 'ar', child: const Text('العربية')),
            CheckedPopupMenuItem(value: 'en', checked: locale.languageCode == 'en', child: const Text('English')),
          ],
        ),
      ],
    );
  }
}
