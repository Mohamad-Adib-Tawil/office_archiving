import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/functions/add_item_from_memory_storage.dart';
import 'package:office_archiving/functions/add_item_from_camera.dart';
import 'package:office_archiving/functions/add_item_from_gallery.dart';
import 'package:office_archiving/theme/app_icons.dart';
import 'package:office_archiving/l10n/app_localizations.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:office_archiving/service/sqlite_service.dart';
import 'package:office_archiving/services/pdf_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

void showAddItemSheet(BuildContext context, int idSection, ItemSectionCubit itemCubit, {String? sectionName}) async {
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
                  Text(AppLocalizations.of(context).add_item_title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
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
                icon: Icons.document_scanner,
                color: Colors.deepPurple,
                title: AppLocalizations.of(context).professional_scanner_title,
                onTap: () async {
                  Navigator.pop(ctx);
                  
                  try {
                    // فتح الماسح مباشرة
                    final result = await FlutterDocScanner().getScanDocuments();
                    debugPrint('Scanner result type: ${result.runtimeType}');
                    debugPrint('Scanner raw result: $result');
                    
                    // تطبيع النتيجة إلى List<String> آمنة
                    final paths = <String>[];
                    if (result is String) {
                      paths.add(result);
                    } else if (result is List) {
                      for (final item in result) {
                        String? p;
                        if (item is String) {
                          p = item;
                        } else if (item is Map) {
                          final tmp = item['path'] ?? item['filePath'] ?? item['imagePath'];
                          if (tmp is String) p = tmp;
                        } else {
                          try {
                            p = (item as dynamic).path as String?;
                          } catch (_) {}
                        }
                        if (p != null && p.isNotEmpty) paths.add(p);
                      }
                    } else if (result is Map) {
                      final maybeList = result['paths'] ?? result['images'] ?? result['files'] ?? result['savedPaths'];
                      if (maybeList is List) {
                        for (final item in maybeList) {
                          String? p;
                          if (item is String) {
                            p = item;
                          } else if (item is Map) {
                            final tmp = item['path'] ?? item['filePath'] ?? item['imagePath'];
                            if (tmp is String) p = tmp;
                          } else {
                            try {
                              p = (item as dynamic).path as String?;
                            } catch (_) {}
                          }
                          if (p != null && p.isNotEmpty) paths.add(p);
                        }
                      } else {
                        final single = result['path'] ?? result['filePath'] ?? result['imagePath'] ?? result['pdfUri'];
                        if (single is String && single.isNotEmpty) paths.add(single);
                      }
                    } else {
                      // محاولة الوصول لخصائص ديناميكية
                      try {
                        final dynSaved = (result as dynamic).savedPaths as List?;
                        if (dynSaved != null) {
                          for (final item in dynSaved) {
                            String? p;
                            if (item is String) p = item; else {
                              try { p = (item as dynamic).path as String?; } catch (_) {}
                            }
                            if (p != null && p.isNotEmpty) paths.add(p);
                          }
                        }
                        final dynList = (result as dynamic).paths as List?;
                        if (dynList != null) {
                          for (final item in dynList) {
                            String? p;
                            if (item is String) p = item; else {
                              try { p = (item as dynamic).path as String?; } catch (_) {}
                            }
                            if (p != null && p.isNotEmpty) paths.add(p);
                          }
                        } else {
                          final p = (result as dynamic).path as String? ?? (result as dynamic).filePath as String? ?? (result as dynamic).imagePath as String? ?? (result as dynamic).pdfUri as String?;
                          if (p != null && p.isNotEmpty) paths.add(p);
                        }
                      } catch (_) {}
                    }

                    if (paths.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context).no_document_captured),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                      return;
                    }

                    // إنشاء عناصر جديدة لكل صورة
                    final now = DateTime.now();
                    final dateStr = DateFormat('yyyy-MM-dd').format(now);
                    
                    // تحضير مجلد scans للنسخ الدائم
                    final docsDir = await getApplicationDocumentsDirectory();
                    final scansDir = Directory('${docsDir.path}/scans');
                    if (!await scansDir.exists()) {
                      await scansDir.create(recursive: true);
                    }

                    int savedCount = 0;
                    for (int i = 0; i < paths.length; i++) {
                      String path = paths[i];
                      if (path.startsWith('file://')) {
                        try { path = Uri.parse(path).toFilePath(); } catch (_) { path = path.replaceFirst('file://', ''); }
                      }
                      if (!File(path).existsSync()) {
                        debugPrint('Skipped non-existing file: $path');
                        continue;
                      }

                      final ext = (path.split('.').length > 1) ? path.split('.').last.toLowerCase() : 'jpg';
                      // في حال عاد المسح كـ PDF: حوله إلى صور واحفظ الصور فقط
                      if (ext == 'pdf') {
                        final images = await PdfService().rasterizePdfToImages(
                          File(path),
                          outputDir: scansDir,
                          namePrefix: 'scan_${now.millisecondsSinceEpoch}_$i',
                        );
                        for (int p = 0; p < images.length; p++) {
                          final img = images[p];
                          final imgExt = (img.path.split('.').last).toLowerCase();
                          final docName = '${AppLocalizations.of(context).document_prefix} ${sectionName ?? AppLocalizations.of(context).section_prefix} $dateStr ${i + 1}-${p + 1}';
                          await DatabaseService.instance.insertItem(
                            docName,
                            img.path,
                            imgExt,
                            idSection,
                            createdAt: now.toIso8601String(),
                          );
                          savedCount++;
                        }
                        continue;
                      }

                      final newName = 'scan_${now.millisecondsSinceEpoch}_$i.$ext';
                      final destPath = '${scansDir.path}/$newName';
                      await File(path).copy(destPath);

                      final docName = '${AppLocalizations.of(context).document_prefix} ${sectionName ?? AppLocalizations.of(context).section_prefix} $dateStr ${i + 1}';
                      await DatabaseService.instance.insertItem(
                        docName,
                        destPath,
                        ext,
                        idSection,
                        createdAt: now.toIso8601String(),
                      );
                      savedCount++;
                    }
                    
                    // تحديث القائمة
                    itemCubit.refreshItems(idSection);
                    
                    // رسالة نجاح
                    if (context.mounted) {
                      final suffix = savedCount == 1
                          ? AppLocalizations.of(context).scanner_saved_suffix_singular
                          : AppLocalizations.of(context).scanner_saved_suffix_plural;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${AppLocalizations.of(context).scanner_saved_prefix}$savedCount$suffix',
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
                          content: Text('${AppLocalizations.of(context).scan_failed_prefix}$e'),
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
  const _ActionTile({required this.icon, required this.color, required this.title, required this.onTap});
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
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.6), color.withValues(alpha: 0.15)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
        onTap: onTap,
      ),
    );
  }
}
