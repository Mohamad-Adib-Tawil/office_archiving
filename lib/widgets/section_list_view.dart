import 'dart:io';
import 'package:flutter/material.dart';
import 'package:office_archiving/constants.dart';
import 'package:office_archiving/cubit/section_cubit/section_cubit.dart';
import 'package:office_archiving/functions/handle_delete_section.dart';
import 'package:office_archiving/functions/handle_rename_section.dart';
import 'package:office_archiving/models/section.dart';
import 'package:office_archiving/pages/section_screen.dart';
import 'package:office_archiving/service/sqlite_service.dart';
import 'package:office_archiving/theme/app_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animations/animations.dart';
import 'package:office_archiving/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:office_archiving/widgets/empty_state.dart';
import 'package:office_archiving/ui/feedback.dart';

class SectionListView extends StatelessWidget {
  final List<Section> sections;
  final SectionCubit sectionCubit;

  const SectionListView({
    Key? key,
    required this.sections,
    required this.sectionCubit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RefreshIndicator(
          onRefresh: () async {
            sectionCubit.loadSections();
            await Future.delayed(const Duration(milliseconds: 200));
          },
          child: sections.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 80),
                    child: EmptyState(
                      asset: kLogoOffice,
                      title: null,
                      message:
                          AppLocalizations.of(context).empty_sections_message,
                    ),
                  ),
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: sections.length,
                  itemBuilder: (context, index) {
                    final animDuration =
                        Duration(milliseconds: 420 + (index % 12) * 35);
                    return TweenAnimationBuilder<double>(
                      duration: animDuration,
                      tween: Tween(begin: 0, end: 1),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 18 * (1 - value)),
                            child: Transform.scale(
                              scale: 0.98 + (0.02 * value),
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: OpenContainer(
                        openElevation: 0,
                        closedElevation: 4,
                        closedShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        openShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        transitionType: ContainerTransitionType.fadeThrough,
                        openBuilder: (context, _) => SectionScreen(
                          section: Section(
                            id: sections[index].id,
                            name: sections[index].name,
                          ),
                        ),
                        closedBuilder: (context, open) => GestureDetector(
                          onTap: open,
                          onLongPress: () => _showOptionsDialog(context, index),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      theme.colorScheme.primary
                                          .withValues(alpha: 0.1),
                                      theme.colorScheme.primary
                                          .withValues(alpha: 0.05),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: FutureBuilder<String?>(
                                        future: DatabaseService.instance
                                            .getSectionCoverOrLatest(
                                                sections[index].id),
                                        builder: (context, snap) {
                                          final path = snap.data;
                                          if (path != null &&
                                              path.isNotEmpty &&
                                              File(path).existsSync()) {
                                            return ClipRRect(
                                              borderRadius: BorderRadius.zero,
                                              child: Image.file(
                                                File(path),
                                                fit: BoxFit.cover,
                                                errorBuilder: (ctx, _, __) =>
                                                    _buildSectionFallback(ctx),
                                              ),
                                            );
                                          }
                                          return _buildSectionFallback(context);
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Text(
                                        sections[index].name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        maxLines: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildSectionFallback(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.18),
            scheme.primary.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: Image.asset(
                kLogoOffice,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).appTitle,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: scheme.onPrimaryContainer.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsDialog(BuildContext context, int index) {
    final rootContext =
        context; // capture root context to use after sheet dismissal
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                Text(
                  AppLocalizations.of(context).optionsTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Icon(AppIcons.edit, color: scheme.primary),
                  title: Text(AppLocalizations.of(context).editName),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(sheetCtx);
                    handleRenameSection(
                      context,
                      sectionCubit,
                      sections[index],
                    );
                  },
                ),
                ListTile(
                  leading: Icon(AppIcons.image, color: scheme.primary),
                  title: Text(AppLocalizations.of(context).set_cover_image),
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    Navigator.pop(sheetCtx);
                    // Wait for the sheet to fully dismiss before presenting picker (prevents UI freeze on iOS)
                    await Future.delayed(const Duration(milliseconds: 220));

                    String? imagePath;

                    // عرض خيارات للمستخدم لاختيار مصدر الصورة
                    if (!rootContext.mounted) return;
                    final source = await _showImageSourceDialog(rootContext);
                    if (source == null) return;

                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: source,
                      imageQuality: 85, // ضغط الصورة لتوفير المساحة
                    );
                    if (picked != null) {
                      imagePath = picked.path;
                    }

                    if (imagePath != null) {
                      await sectionCubit.updateSectionCover(
                          sections[index].id, imagePath);
                      if (rootContext.mounted) {
                        UIFeedback.success(
                            rootContext,
                            AppLocalizations.of(rootContext)
                                .snackbar_cover_set);
                      }
                    }
                  },
                ),
                ListTile(
                  leading: Icon(AppIcons.close, color: Colors.red.shade700),
                  title: Text(AppLocalizations.of(context).clear_cover),
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    Navigator.pop(sheetCtx);
                    await sectionCubit.updateSectionCover(
                        sections[index].id, null);
                    if (context.mounted) {
                      UIFeedback.info(context,
                          AppLocalizations.of(context).snackbar_cover_cleared);
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(AppIcons.delete, color: Colors.red.shade700),
                  title: Text(AppLocalizations.of(context).deleteSection),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(sheetCtx);
                    handleDeleteSection(context, sections[index]);
                  },
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    child: Text(
                      AppLocalizations.of(context).cancel,
                      style: TextStyle(
                          color: scheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<ImageSource?> _showImageSourceDialog(
      BuildContext context) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('اختر مصدر الصورة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('معرض الصور'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('الكاميرا'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
          ],
        );
      },
    );
  }
}
