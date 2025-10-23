import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:office_archiving/cubit/locale_cubit/locale_cubit.dart';
import 'package:office_archiving/cubit/theme_cubit/theme_cubit.dart';
import 'package:office_archiving/theme/app_icons.dart';
import 'package:office_archiving/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

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
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final uri = Uri.parse('https://mohamad-adib-tawil.github.io/CV/');
                bool opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
                if (!opened) {
                  opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                }
                if (!opened) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تعذّر فتح الرابط')),
                  );
                }
              },
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: theme.colorScheme.primary.withOpacity(.12),
                            backgroundImage: const NetworkImage(
                              'https://avatars.githubusercontent.com/u/223110350?s=400&u=75cb795be7688812bda8863968c8139a0fe6a96a&v=4',
                            ),
                            onBackgroundImageError: (_, __) {},
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  locale.languageCode == 'ar'
                                      ? 'تم تصميم التطبيق بواسطة المبرمج'
                                      : 'Designed by the developer',
                                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'محمد أديب طويل',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  'Mohamad Adib Tawil',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'اضغط لفتح السيرة الذاتية',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary.withOpacity(.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
      _ThemeItemData(
          AppTheme.system, AppLocalizations.of(context).theme_system, scheme.primary, Icons.brightness_auto),
      _ThemeItemData(
          AppTheme.light, AppLocalizations.of(context).theme_light, scheme.primary, Icons.wb_sunny_outlined),
      _ThemeItemData(
          AppTheme.dark, AppLocalizations.of(context).theme_dark, scheme.primary, Icons.nightlight_round),
      _ThemeItemData(AppTheme.midnight, 'Midnight', const Color(0xFF0B2239), Icons.circle),
      _ThemeItemData(AppTheme.midnightAurora, 'Midnight Aurora', const Color(0xFF1B5E78), Icons.circle),
      _ThemeItemData(AppTheme.glacierBlue, 'Glacier Blue', const Color(0xFF2F6DE1), Icons.circle),
      _ThemeItemData(AppTheme.royalRed, 'Royal Red', const Color(0xFF8B0F24), Icons.circle),
      _ThemeItemData(AppTheme.rubyBloom, 'Ruby Bloom', const Color(0xFFC2185B), Icons.circle),
      _ThemeItemData(AppTheme.victorianGold, 'Victorian Gold', const Color(0xFFC6A15B), Icons.circle),
      _ThemeItemData(AppTheme.sunsetAmber, 'Sunset Amber', const Color(0xFFFF8C42), Icons.circle),
      _ThemeItemData(AppTheme.champagneGlow, 'Champagne Glow', const Color(0xFFF2D16B), Icons.circle),
      _ThemeItemData(AppTheme.platinumSilver, 'Platinum Silver', const Color(0xFFB0BEC5), Icons.circle),
      _ThemeItemData(AppTheme.onyxGraphite, 'Onyx Graphite', const Color(0xFF1C1F26), Icons.circle),
      _ThemeItemData(AppTheme.jadeForest, 'Jade Forest', const Color(0xFF0F3D2E), Icons.circle),
      _ThemeItemData(AppTheme.emeraldLuxe, 'Emerald Luxe', const Color(0xFF2BB673), Icons.circle),
      _ThemeItemData(AppTheme.pearlMoon, 'Pearl Moon', const Color(0xFFECE5D9), Icons.circle),
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
