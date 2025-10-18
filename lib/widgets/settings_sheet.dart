import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:office_archiving/cubit/locale_cubit/locale_cubit.dart';
import 'package:office_archiving/cubit/theme_cubit/theme_cubit.dart';
import 'package:office_archiving/theme/app_icons.dart';
import 'package:office_archiving/l10n/app_localizations.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = context.select((LocaleCubit c) => c.state);
    final themeState = context.select((ThemeCubit c) => c.state);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Row(
              children: [
                Icon(AppIcons.more, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).app_settings_title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(AppIcons.close),
                )
              ],
            ),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context).app_language_label,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                    value: 'ar',
                    label: Text(AppLocalizations.of(context).app_language_ar)),
                ButtonSegment(
                    value: 'en',
                    label: Text(AppLocalizations.of(context).app_language_en)),
              ],
              selected: {locale.languageCode},
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
              onSelectionChanged: (Set<String> values) {
                final value = values.first;
                if (value == 'ar') {
                  context.read<LocaleCubit>().setLocale(const Locale('ar'));
                } else {
                  context.read<LocaleCubit>().setLocale(const Locale('en'));
                }
              },
            ),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).app_theme_label,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _ThemeGrid(themeState: themeState),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ThemeGrid extends StatelessWidget {
  const _ThemeGrid({required this.themeState});
  final AppTheme themeState;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = <_ThemeItemData>[
      _ThemeItemData(AppTheme.system, AppLocalizations.of(context).theme_system, scheme.primary,
          Icons.brightness_auto),
      _ThemeItemData(
          AppTheme.light, AppLocalizations.of(context).theme_light, scheme.primary, Icons.wb_sunny_outlined),
      _ThemeItemData(
          AppTheme.dark, AppLocalizations.of(context).theme_dark, scheme.primary, Icons.nightlight_round),
      _ThemeItemData(AppTheme.blue, AppLocalizations.of(context).theme_blue, Colors.blue, Icons.circle),
      _ThemeItemData(AppTheme.purple, AppLocalizations.of(context).theme_purple, Colors.purple, Icons.circle),
      _ThemeItemData(AppTheme.teal, AppLocalizations.of(context).theme_teal, Colors.teal, Icons.circle),
      _ThemeItemData(AppTheme.orange, AppLocalizations.of(context).theme_orange, Colors.orange, Icons.circle),
      _ThemeItemData(AppTheme.pink, AppLocalizations.of(context).theme_pink, Colors.pink, Icons.circle),
      _ThemeItemData(AppTheme.indigo, AppLocalizations.of(context).theme_indigo, Colors.indigo, Icons.circle),
      _ThemeItemData(
          AppTheme.coral, AppLocalizations.of(context).theme_coral, const Color(0xFFFF6F61), Icons.circle),
      _ThemeItemData(AppTheme.yellow, AppLocalizations.of(context).theme_yellow, Colors.amber, Icons.circle),
      // New gradient themes
      _ThemeItemData(AppTheme.oceanBlue, AppLocalizations.of(context).theme_ocean_blue, const Color(0xFF0099CC), Icons.waves),
      _ThemeItemData(AppTheme.sunsetOrange, AppLocalizations.of(context).theme_sunset_orange, const Color(0xFFF7931E), Icons.wb_sunny),
      _ThemeItemData(AppTheme.forestGreen, AppLocalizations.of(context).theme_forest_green, const Color(0xFF4F7942), Icons.forest),
      _ThemeItemData(AppTheme.royalPurple, AppLocalizations.of(context).theme_royal_purple, const Color(0xFF9A031E), Icons.diamond),
      _ThemeItemData(AppTheme.roseGold, AppLocalizations.of(context).theme_rose_gold, const Color(0xFFD4AF37), Icons.auto_awesome),
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: .72,
      ),
      itemBuilder: (ctx, i) {
        final it = items[i];
        final selected = it.theme == themeState;
        return _ThemeCard(
          label: it.label,
          color: it.color,
          icon: it.icon,
          selected: selected,
          onTap: () {
            HapticFeedback.selectionClick();
            context.read<ThemeCubit>().setTheme(it.theme);
          },
        );
      },
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.label,
    required this.color,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.5 : 1),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeItemData {
  final AppTheme theme;
  final String label;
  final Color color;
  final IconData icon;
  const _ThemeItemData(this.theme, this.label, this.color, this.icon);
}
