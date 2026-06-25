import 'package:flutter/material.dart';
import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/functions/add_item_from_memory_storage.dart';
import 'package:office_archiving/functions/add_item_from_camera.dart';
import 'package:office_archiving/functions/add_item_from_gallery.dart';
import 'package:office_archiving/theme/app_icons.dart';
import 'package:office_archiving/l10n/app_localizations.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:office_archiving/services/scanner_import_service.dart';
import 'package:office_archiving/pages/rich_text_editor_page.dart';
import 'package:office_archiving/pages/excel_editor_page.dart';

bool _isArabic(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'ar';

void showAddItemSheet(
  BuildContext context,
  int idSection,
  ItemSectionCubit itemCubit, {
  String? sectionName,
}) async {
  final theme = Theme.of(context);
  final primary = theme.colorScheme.primary;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(AppIcons.add, color: primary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context).add_item_title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ActionTile(
                icon: AppIcons.file,
                color: Colors.blue,
                title: AppLocalizations.of(context).from_files,
                onTap: () {
                  Navigator.pop(ctx);
                  addItemFromMemoryStorage(context, idSection, itemCubit);
                },
              ),
              _ActionTile(
                icon: AppIcons.image,
                color: Colors.orange,
                title: AppLocalizations.of(context).from_gallery,
                onTap: () {
                  Navigator.pop(ctx);
                  addItemFromGallery(context, idSection, itemCubit);
                },
              ),
              _ActionTile(
                icon: AppIcons.video, // fallback if no camera icon
                color: Colors.teal,
                title: AppLocalizations.of(context).from_camera,
                onTap: () {
                  Navigator.pop(ctx);
                  addItemFromCamera(idSection, itemCubit, context);
                },
              ),
              _ActionTile(
                icon: Icons.text_snippet,
                color: Colors.indigo,
                title: _isArabic(context)
                    ? 'مستند نصّي جديد'
                    : 'New text document',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RichTextEditorPage(
                        sectionId: idSection,
                        itemCubit: itemCubit,
                        fileType: 'txt',
                      ),
                    ),
                  );
                },
              ),
              _ActionTile(
                icon: Icons.description,
                color: const Color(0xFF2B579A),
                title: _isArabic(context) ? 'ملف Word جديد' : 'New Word file',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RichTextEditorPage(
                        sectionId: idSection,
                        itemCubit: itemCubit,
                        fileType: 'docx',
                      ),
                    ),
                  );
                },
              ),
              _ActionTile(
                icon: Icons.table_chart,
                color: const Color(0xFF217346),
                title: _isArabic(context) ? 'ملف Excel جديد' : 'New Excel file',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExcelEditorPage(
                        sectionId: idSection,
                        itemCubit: itemCubit,
                      ),
                    ),
                  );
                },
              ),
              _ActionTile(
                icon: Icons.document_scanner,
                color: Colors.deepPurple,
                title: AppLocalizations.of(context).professional_scanner_title,
                onTap: () async {
                  Navigator.pop(ctx);

                  try {
                    final result = await FlutterDocScanner().getScanDocuments();
                    final imported = await ScannerImportService.instance
                        .importScannerResultToSection(
                          rawResult: result,
                          sectionId: idSection,
                          sectionName:
                              sectionName ??
                              AppLocalizations.of(context).section_prefix,
                        );

                    if (imported.savedCount == 0) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context).no_document_captured,
                            ),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                      return;
                    }

                    // تحديث القائمة
                    itemCubit.refreshItems(idSection);

                    // رسالة نجاح
                    if (context.mounted) {
                      final suffix = imported.savedCount == 1
                          ? AppLocalizations.of(
                              context,
                            ).scanner_saved_suffix_singular
                          : AppLocalizations.of(
                              context,
                            ).scanner_saved_suffix_plural;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${AppLocalizations.of(context).scanner_saved_prefix}${imported.savedCount}$suffix',
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${AppLocalizations.of(context).scan_failed_prefix}$e',
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.6), color.withValues(alpha: 0.15)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
