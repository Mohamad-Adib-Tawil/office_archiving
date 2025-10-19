import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:office_archiving/l10n/app_localizations.dart';
import 'package:office_archiving/constants.dart';
import 'package:office_archiving/theme/app_icons.dart';
import 'package:office_archiving/widgets/settings_sheet.dart';
import 'package:office_archiving/pages/analytics_page.dart';
import 'package:office_archiving/pages/file_cleanup_page.dart';
import 'package:office_archiving/pages/ai_features_page.dart';

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
              theme.colorScheme.primary.withValues(alpha: 0.08),
              theme.colorScheme.primary.withValues(alpha: 0.02),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: AppLocalizations.of(context).analytics_title,
          icon: const Icon(Icons.analytics_outlined),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AnalyticsPage(),
              ),
            );
          },
        ),
        IconButton(
          tooltip: AppLocalizations.of(context).file_cleanup_title,
          icon: const Icon(Icons.cleaning_services_outlined),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FileCleanupPage(),
              ),
            );
          },
        ),
        IconButton(
          tooltip: 'ميزات الذكاء الاصطناعي',
          icon: const Icon(Icons.psychology_outlined),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AIFeaturesPage(),
              ),
            );
          },
        ),
        IconButton(
          tooltip: AppLocalizations.of(context).settings_tooltip,
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
