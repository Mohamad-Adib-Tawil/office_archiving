import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:office_archiving/cubit/locale_cubit/locale_cubit.dart';
import 'package:office_archiving/cubit/theme_cubit/theme_cubit.dart';
import 'package:office_archiving/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 30, 16, 16),
        child: SingleChildScrollView(
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
                  Icon(Icons.settings, color: scheme.primary),
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
                    icon: const Icon(Icons.close),
                  )
                ],
              ),
              const SizedBox(height: 12),
              const SettingsContent(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsContent extends StatelessWidget {
  const SettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = context.select((LocaleCubit c) => c.state);
    final themeState = context.select((ThemeCubit c) => c.state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).app_language_label,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'ar', label: Text(AppLocalizations.of(context).app_language_ar)),
            ButtonSegment(value: 'en', label: Text(AppLocalizations.of(context).app_language_en)),
          ],
          selected: {locale.languageCode},
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
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
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _ThemeGrid(themeState: themeState),
        const SizedBox(height: 6),
        Text(AppLocalizations.of(context).accent_color_label,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        _AccentColorRow(),
        const SizedBox(height: 6),
        _DeveloperCard(),
      ],
    );
  }
}

class _DeveloperCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = context.select((LocaleCubit c) => c.state);
    return InkWell(
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
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: .12),
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
                            color: theme.colorScheme.primary.withValues(alpha: .8),
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

class _AccentColorRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeCubit = context.read<ThemeCubit>();
    
    return ValueListenableBuilder<Color?>(
      valueListenable: themeCubit.customPrimaryNotifier,
      builder: (context, current, child) {

    return Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _showColorPicker(context, themeCubit),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: current ?? Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (current ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.palette,
                        color: _getContrastColor(current ?? Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).accent_color_label,
                          style: TextStyle(
                            color: _getContrastColor(current ?? Theme.of(context).colorScheme.primary),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: _getContrastColor(current ?? Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (current != null)
              IconButton(
                onPressed: () => themeCubit.setCustomPrimary(null),
                icon: const Icon(Icons.refresh),
                tooltip: AppLocalizations.of(context).reset_action,
              ),
          ],
        );
      },
    );
  }

  Color _getContrastColor(Color color) {
    // حساب اللون المتباين (أبيض أو أسود) بناءً على سطوع اللون
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  void _showColorPicker(BuildContext context, ThemeCubit themeCubit) {
    showDialog(
      context: context,
      builder: (context) => _ColorPickerDialog(
        currentColor: themeCubit.customPrimary ?? Theme.of(context).colorScheme.primary,
        onColorSelected: (color) {
          themeCubit.setCustomPrimary(color);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final Color currentColor;
  final Function(Color) onColorSelected;

  const _ColorPickerDialog({
    required this.currentColor,
    required this.onColorSelected,
  });

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color selectedColor;

  @override
  void initState() {
    super.initState();
    selectedColor = widget.currentColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context).accent_color_label),
      content: SizedBox(
        width: 300,
        height: 520,
        child: Column(
          children: [
            // معاينة اللون المحدد
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: selectedColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Text(
                  '#${selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                  style: TextStyle(
                    color: _getContrastColor(selectedColor),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // لوحة الألوان الدائرية الاحترافية
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // لوحة الألوان الدائرية
                    ColorPicker(
                      pickerColor: selectedColor,
                      onColorChanged: (color) {
                        setState(() {
                          selectedColor = color;
                        });
                        HapticFeedback.selectionClick();
                      },
                      colorPickerWidth: 250,
                      pickerAreaHeightPercent: 0.8,
                      enableAlpha: false,
                      displayThumbColor: true,
                      paletteType: PaletteType.hueWheel,
                      labelTypes: const [],
                      pickerAreaBorderRadius: BorderRadius.circular(12),
                      hexInputBar: true,
                      portraitOnly: true,
                    ),
                    const SizedBox(height: 12),
                    // شريط إضافي للألوان المحفوظة مسبقاً
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ألوان سريعة',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              Colors.blue,
                              Colors.red,
                              Colors.green,
                              Colors.orange,
                              Colors.purple,
                              Colors.teal,
                              Colors.pink,
                              Colors.indigo,
                            ].map((color) => GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedColor = color;
                                });
                                HapticFeedback.selectionClick();
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: selectedColor == color 
                                        ? Colors.white 
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: selectedColor == color
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).cancel),
        ),
        ElevatedButton(
          onPressed: () => widget.onColorSelected(selectedColor),
          child: Text(AppLocalizations.of(context).addAction),
        ),
      ],
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}
