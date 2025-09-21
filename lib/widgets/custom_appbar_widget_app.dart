import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:office_archiving/cubit/locale_cubit/locale_cubit.dart';
import 'package:office_archiving/l10n/app_localizations.dart';

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
