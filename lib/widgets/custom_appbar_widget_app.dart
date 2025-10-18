import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:office_archiving/l10n/app_localizations.dart';
import 'package:office_archiving/constants.dart';
import 'package:office_archiving/theme/app_icons.dart';
import 'package:office_archiving/widgets/settings_sheet.dart';

class CustomAppBarWidgetApp extends StatelessWidget
    implements PreferredSizeWidget {
  const CustomAppBarWidgetApp({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      centerTitle: true,
      title: Text(
        AppLocalizations.of(context).appTitle,
        style:
            theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(AppRadius.lg)),
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
        IconButton(
          tooltip: 'الإعدادات',
          icon: const Icon(AppIcons.more),
          onPressed: () {
            HapticFeedback.lightImpact();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => const SettingsSheet(),
            );
          },
        ),
      ],
    );
  }
}
