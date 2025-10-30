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
                      message: AppLocalizations.of(
                        context,
                      ).empty_sections_message,
                    ),
                  ),
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: sections.length,
                  itemBuilder: (context, index) {
                    final animDuration = Duration(
                      milliseconds: 420 + (index % 12) * 35,
                    );
                    return TweenAnimationBuilder<double>(
                      duration: animDuration,
                      tween: Tween(begin: 0, end: 1),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 24 * (1 - value)),
                            child: Transform.scale(
                              scale: 0.96 + (0.04 * value),
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: _buildModernSectionCard(context, index),
                    );
                  },
                ),
        ),
      ),
    );
  }

  // Determine text direction based on name language
  // Rules: Arabic -> RTL, English -> LTR, Others/Mixed -> RTL
  TextDirection _dirFor(String text) {
    // Arabic ranges: Arabic, Arabic Supplement, Arabic Extended-A/B, Presentation Forms
    final hasArabic = RegExp(
      r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
    ).hasMatch(text);
    final hasEnglish = RegExp(r'[A-Za-z]').hasMatch(text);
    if (hasArabic && !hasEnglish) return TextDirection.rtl;
    if (hasEnglish && !hasArabic) return TextDirection.ltr;
    // Mixed or other languages default to RTL per requirement
    return TextDirection.rtl;
  }

  Widget _buildModernSectionCard(BuildContext context, int index) {
    final section = sections[index];

    // تدرجات لونية متنوعة لكل قسم
    final gradients = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)],
      [const Color(0xFFf093fb), const Color(0xFFf5576c)],
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      [const Color(0xFF43e97b), const Color(0xFF38f9d7)],
      [const Color(0xFFfa709a), const Color(0xFFfee140)],
      [const Color(0xFF30cfd0), const Color(0xFF330867)],
    ];

    final gradientColors = gradients[index % gradients.length];

    return OpenContainer(
      openElevation: 0,
      closedElevation: 0,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      openShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: const Duration(milliseconds: 500),
      openBuilder: (context, _) => SectionScreen(
        section: Section(id: section.id, name: section.name),
      ),
      closedBuilder: (context, open) => GestureDetector(
        onTap: open,
        onLongPress: () => _showOptionsDialog(context, index),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gradientColors[0].withValues(alpha: 0.85),
                gradientColors[1].withValues(alpha: 0.95),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: -5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // خلفية متحركة بتأثير Glassmorphism
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                ),

                // الصورة أو الأيقونة الافتراضية
                Positioned.fill(
                  child: FutureBuilder<String?>(
                    future: DatabaseService.instance.getSectionCoverOrLatest(
                      section.id,
                    ),
                    builder: (context, snap) {
                      final path = snap.data;
                      if (path != null &&
                          path.isNotEmpty &&
                          File(path).existsSync()) {
                        return Stack(
                          children: [
                            Image.file(
                              File(path),
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, _, __) =>
                                  _buildModernFallback(context, gradientColors),
                            ),
                            // تأثير overlay للصورة
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.7),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return _buildModernFallback(context, gradientColors);
                    },
                  ),
                ),

                // محتوى البطاقة
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Directionality(
                    textDirection: _dirFor(section.name),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // اسم القسم
                          Text(
                            section.name,
                            textAlign: TextAlign.start,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // إحصائيات القسم
                          FutureBuilder<int>(
                            future: DatabaseService.instance
                                .getDocumentCountBySection(section.id),
                            builder: (context, snapshot) {
                              final count = snapshot.data ?? 0;
                              return Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.25,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.description_outlined,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$count',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // زر الخيارات
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _showOptionsDialog(context, index),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.more_vert_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernFallback(
    BuildContext context,
    List<Color> gradientColors,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradientColors[0].withValues(alpha: 0.6),
            gradientColors[1].withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.folder_rounded,
                size: 48,
                color: Colors.white,
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
                    handleRenameSection(context, sectionCubit, sections[index]);
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
                        sections[index].id,
                        imagePath,
                      );
                      if (rootContext.mounted) {
                        UIFeedback.success(
                          rootContext,
                          AppLocalizations.of(rootContext).snackbar_cover_set,
                        );
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
                      sections[index].id,
                      null,
                    );
                    if (context.mounted) {
                      UIFeedback.info(
                        context,
                        AppLocalizations.of(context).snackbar_cover_cleared,
                      );
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
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
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
    BuildContext context,
  ) async {
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
