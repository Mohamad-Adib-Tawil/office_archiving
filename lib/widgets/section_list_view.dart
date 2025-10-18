import 'dart:io';
import 'package:flutter/material.dart';
  import 'package:office_archiving/constants.dart';
  import 'package:office_archiving/cubit/section_cubit/section_cubit.dart';
  import 'package:office_archiving/functions/handle_delete_section.dart';
  import 'package:office_archiving/functions/handle_rename_Section.dart';
  import 'package:office_archiving/models/section.dart';
  import 'package:office_archiving/pages/section_screen.dart';
  import 'package:office_archiving/l10n/app_localizations.dart';
  import 'package:office_archiving/theme/app_icons.dart';
  import 'package:image_picker/image_picker.dart';
  import 'package:office_archiving/service/sqlite_service.dart';

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
        child: sections.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      kLogoOffice,
                      width: 200,
                      height: 200,
                      // color: Colors.grey.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context).emptySectionsMessage,
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ],
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
                  final animDuration = Duration(milliseconds: 420 + (index % 12) * 35);
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
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SectionScreen(
                              section: Section(
                                id: sections[index].id,
                                name: sections[index].name,
                              ),
                            ),
                          ),
                        );
                      },
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
                                  theme.colorScheme.primary.withOpacity(0.1),
                                  theme.colorScheme.primary.withOpacity(0.05),
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: FutureBuilder<String?>(
                                    future: DatabaseService.instance.getSectionCoverOrLatest(sections[index].id),
                                    builder: (context, snap) {
                                      final path = snap.data;
                                      if (path != null && path.isNotEmpty && File(path).existsSync()) {
                                        return ClipRRect(
                                          borderRadius: BorderRadius.zero,
                                          child: Image.file(
                                            File(path),
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, _, __) => _buildSectionFallback(),
                                          ),
                                        );
                                      }
                                      return _buildSectionFallback();
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(
                                    sections[index].name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
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
                  );
                },
              ),
      ),
    );
  }

  Widget _buildSectionFallback() {
    return Container(
      color: Colors.white.withOpacity(0.2),
      child: Image.asset(
        kLogoOffice,
        fit: BoxFit.cover,
      ),
    );
  }

  void _showOptionsDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.of(context).optionsTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(AppIcons.edit, color: Theme.of(context).colorScheme.primary),
              title: Text(AppLocalizations.of(context).editName),
              onTap: () {
                Navigator.pop(context);
                handleRenameSection(
                  context,
                  sectionCubit,
                  sections[index],
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(AppIcons.image, color: Theme.of(context).colorScheme.primary),
              title: const Text('Set Cover Image'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  // Persist cover path
                  await sectionCubit.updateSectionCover(sections[index].id, picked.path);
                }
              },
            ),
            ListTile(
              leading: Icon(AppIcons.close, color: Colors.red.shade700),
              title: const Text('Clear Cover'),
              onTap: () async {
                Navigator.pop(context);
                await sectionCubit.updateSectionCover(sections[index].id, null);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(AppIcons.delete, color: Colors.red.shade700),
              title: Text(AppLocalizations.of(context).deleteSection),
              onTap: () {
                Navigator.pop(context);
                handleDeleteSection(context, sections[index]);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        ],
      ),
    );
  }
}
