import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:office_archiving/pages/qr_barcode_scanner.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:intl/intl.dart';
import 'package:office_archiving/pages/business_card_scanner.dart';
import 'package:office_archiving/pages/pdf_security_page.dart';
import 'package:office_archiving/pages/pdf_editor_page.dart';
import 'package:office_archiving/pages/document_management_page.dart';
import 'package:office_archiving/service/sqlite_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:office_archiving/services/pdf_service.dart';
import 'package:office_archiving/l10n/app_localizations.dart';

class ProfessionalToolsPage extends StatelessWidget {
  final bool embedded;
  const ProfessionalToolsPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: embedded
          ? null
          : AppBar(
              title: Text(AppLocalizations.of(context).tab_professional_tools),
              centerTitle: true,
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(context),
            const SizedBox(height: 24),

            const Text(
              'أدوات المسح والالتقاط',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildToolGrid(context, [
              ToolItem(
                title: 'ماسح المستندات',
                subtitle: 'مسح متقدم مع فلاتر وتحسين',
                icon: Icons.document_scanner,
                color: Colors.blue,
                onTap: () => _showSectionSelectionForScanner(context),
              ),
              ToolItem(
                title: 'ماسح بطاقات العمل',
                subtitle: 'استخراج معلومات الاتصال تلقائياً',
                icon: Icons.credit_card,
                color: Colors.green,
                page: const BusinessCardScannerPage(),
              ),
              ToolItem(
                title: 'ماسح الرموز والباركود',
                subtitle: 'مسح وإنشاء رموز QR والباركود',
                icon: Icons.qr_code_scanner,
                color: Colors.orange,
                page: const QRBarcodeScannerPage(),
              ),
            ]),

            const SizedBox(height: 24),

            const Text(
              'أدوات PDF المتقدمة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildToolGrid(context, [
              ToolItem(
                title: 'حماية PDF',
                subtitle: 'كلمات مرور وتوقيع إلكتروني',
                icon: Icons.security,
                color: Colors.red,
                onTap: () => _openPdfPickerForSecurity(context),
              ),
              ToolItem(
                title: 'محرر PDF',
                subtitle: 'إضافة تعليقات وتمييز النصوص',
                icon: Icons.edit_document,
                color: Colors.purple,
                onTap: () => _openPdfPickerForEditor(context),
              ),
              ToolItem(
                title: 'دمج PDF',
                subtitle: 'دمج عدة ملفات PDF في ملف واحد',
                icon: Icons.merge,
                color: Colors.teal,
                page: const DocumentManagementPage(),
              ),
            ]),

            const SizedBox(height: 24),

            const Text(
              'أدوات إضافية',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildToolGrid(context, [
              ToolItem(
                title: 'مولد التقارير',
                subtitle: 'إنشاء تقارير احترافية',
                icon: Icons.assessment,
                color: Colors.indigo,
                onTap: () => _showComingSoon(context),
              ),
              ToolItem(
                title: 'النسخ الاحتياطي السحابي',
                subtitle: 'مزامنة مع الخدمات السحابية',
                icon: Icons.cloud_sync,
                color: Colors.lightBlue,
                onTap: () => _showComingSoon(context),
              ),
              ToolItem(
                title: 'مشاركة متقدمة',
                subtitle: 'مشاركة مع تحكم في الصلاحيات',
                icon: Icons.share_outlined,
                color: Colors.amber,
                onTap: () => _showComingSoon(context),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> _openPdfPickerForEditor(BuildContext context) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final scansDir = Directory('${docsDir.path}/scans');
    final files = <File>[];
    if (await docsDir.exists()) {
      for (final e in docsDir.listSync()) {
        if (e is File && e.path.toLowerCase().endsWith('.pdf')) files.add(e);
      }
    }
    if (await scansDir.exists()) {
      for (final e in scansDir.listSync()) {
        if (e is File && e.path.toLowerCase().endsWith('.pdf')) files.add(e);
      }
    }

    if (files.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).no_pdfs_found)),
        );
      }
      return;
    }

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView.builder(
        itemCount: files.length,
        itemBuilder: (_, i) {
          final f = files[i];
          final name = f.path.split('/').last;
          return ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: Text(name),
            subtitle: Text('${(f.lengthSync() / 1024).toStringAsFixed(1)} KB'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PdfEditorPage(pdfPath: f.path),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openPdfPickerForSecurity(BuildContext context) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final scansDir = Directory('${docsDir.path}/scans');
    final files = <File>[];
    if (await docsDir.exists()) {
      for (final e in docsDir.listSync()) {
        if (e is File && e.path.toLowerCase().endsWith('.pdf')) files.add(e);
      }
    }
    if (await scansDir.exists()) {
      for (final e in scansDir.listSync()) {
        if (e is File && e.path.toLowerCase().endsWith('.pdf')) files.add(e);
      }
    }

    if (files.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).no_pdfs_found)),
        );
      }
      return;
    }

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView.builder(
        itemCount: files.length,
        itemBuilder: (_, i) {
          final f = files[i];
          final name = f.path.split('/').last;
          return ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: Text(name),
            subtitle: Text('${(f.lengthSync() / 1024).toStringAsFixed(1)} KB'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PdfSecurityPage(inputPdfPath: f.path),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 8,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [scheme.primary, scheme.primary.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'أدوات احترافية لإدارة المستندات',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'مجموعة شاملة من الأدوات المتقدمة لمسح وتحرير وحماية وإدارة المستندات بطريقة احترافية',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolGrid(BuildContext context, List<ToolItem> tools) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return _buildToolCard(context, tool);
      },
    );
  }

  Widget _buildToolCard(BuildContext context, ToolItem tool) {
    return Card(
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.lightImpact();
          if (tool.page != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => tool.page!),
            );
          } else if (tool.onTap != null) {
            tool.onTap!();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tool.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(tool.icon, color: tool.color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                tool.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tool.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.schedule, color: Colors.orange),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).coming_soon),
          ],
        ),
        content: Text(AppLocalizations.of(context).coming_soon_message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context).ok_action),
          ),
        ],
      ),
    );
  }

  /// عرض قائمة الأقسام لاختيار القسم قبل المسح
  Future<void> _showSectionSelectionForScanner(BuildContext context) async {
    final db = DatabaseService.instance;
    final sections = await db.getAllSections();

    if (!context.mounted) return;

    if (sections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد أقسام متاحة. يرجى إنشاء قسم أولاً.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Icon(Icons.folder_outlined, color: Colors.blue, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'اختر القسم للمسح',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: sections.length,
                  itemBuilder: (context, index) {
                    final section = sections[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.folder,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          section['name'] ?? 'قسم',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          Navigator.pop(ctx);

                          final sectionId = section['id'] as int;
                          final sectionName =
                              section['name'] as String? ?? 'قسم';

                          try {
                            final result = await FlutterDocScanner()
                                .getScanDocuments();
                            debugPrint(
                              'Scanner result type: ${result.runtimeType}',
                            );
                            debugPrint('Scanner raw result: $result');

                            // تطبيع النتيجة إلى List<String>
                            final paths = <String>[];
                            if (result is String) {
                              paths.add(result);
                            } else if (result is List) {
                              for (final item in result) {
                                String? p;
                                if (item is String) {
                                  p = item;
                                } else if (item is Map) {
                                  final tmp =
                                      item['path'] ??
                                      item['filePath'] ??
                                      item['imagePath'];
                                  if (tmp is String) p = tmp;
                                } else {
                                  try {
                                    p = (item as dynamic).path as String?;
                                  } catch (_) {}
                                }
                                if (p != null && p.isNotEmpty) paths.add(p);
                              }
                            } else if (result is Map) {
                              final maybeList =
                                  result['paths'] ??
                                  result['images'] ??
                                  result['files'] ??
                                  result['savedPaths'];
                              if (maybeList is List) {
                                for (final item in maybeList) {
                                  String? p;
                                  if (item is String) {
                                    p = item;
                                  } else if (item is Map) {
                                    final tmp =
                                        item['path'] ??
                                        item['filePath'] ??
                                        item['imagePath'];
                                    if (tmp is String) p = tmp;
                                  } else {
                                    try {
                                      p = (item as dynamic).path as String?;
                                    } catch (_) {}
                                  }
                                  if (p != null && p.isNotEmpty) paths.add(p);
                                }
                              } else {
                                final single =
                                    result['path'] ??
                                    result['filePath'] ??
                                    result['imagePath'] ??
                                    result['pdfUri'];
                                if (single is String && single.isNotEmpty)
                                  paths.add(single);
                              }
                            } else {
                              // خصائص ديناميكية محتملة
                              try {
                                final dynSaved =
                                    (result as dynamic).savedPaths as List?;
                                if (dynSaved != null) {
                                  for (final item in dynSaved) {
                                    String? p;
                                    if (item is String)
                                      p = item;
                                    else {
                                      try {
                                        p = (item as dynamic).path as String?;
                                      } catch (_) {}
                                    }
                                    if (p != null && p.isNotEmpty) paths.add(p);
                                  }
                                }
                                final dynList =
                                    (result as dynamic).paths as List?;
                                if (dynList != null) {
                                  for (final item in dynList) {
                                    String? p;
                                    if (item is String)
                                      p = item;
                                    else {
                                      try {
                                        p = (item as dynamic).path as String?;
                                      } catch (_) {}
                                    }
                                    if (p != null && p.isNotEmpty) paths.add(p);
                                  }
                                } else {
                                  final p =
                                      (result as dynamic).path as String? ??
                                      (result as dynamic).filePath as String? ??
                                      (result as dynamic).imagePath
                                          as String? ??
                                      (result as dynamic).pdfUri as String?;
                                  if (p != null && p.isNotEmpty) paths.add(p);
                                }
                              } catch (_) {}
                            }

                            if (paths.isEmpty) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('لم يتم التقاط أي مستند'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                              return;
                            }

                            final now = DateTime.now();
                            final dateStr = DateFormat(
                              'yyyy-MM-dd',
                            ).format(now);

                            // تحضير مجلد scans للنسخ الدائم
                            final docsDir =
                                await getApplicationDocumentsDirectory();
                            final scansDir = Directory('${docsDir.path}/scans');
                            if (!await scansDir.exists()) {
                              await scansDir.create(recursive: true);
                            }

                            int savedCount = 0;
                            for (int i = 0; i < paths.length; i++) {
                              String path = paths[i];
                              if (path.startsWith('file://')) {
                                try {
                                  path = Uri.parse(path).toFilePath();
                                } catch (_) {
                                  path = path.replaceFirst('file://', '');
                                }
                              }
                              if (!File(path).existsSync()) {
                                debugPrint('Skipped non-existing file: $path');
                                continue;
                              }

                              final ext = (path.split('.').length > 1)
                                  ? path.split('.').last.toLowerCase()
                                  : 'jpg';
                              if (ext == 'pdf') {
                                final images = await PdfService()
                                    .rasterizePdfToImages(
                                      File(path),
                                      outputDir: scansDir,
                                      namePrefix:
                                          'scan_${now.millisecondsSinceEpoch}_$i',
                                    );
                                for (int p = 0; p < images.length; p++) {
                                  final img = images[p];
                                  final imgExt = (img.path.split('.').last)
                                      .toLowerCase();
                                  final docName =
                                      'مستند $sectionName $dateStr ${i + 1}-${p + 1}';
                                  await DatabaseService.instance.insertItem(
                                    docName,
                                    img.path,
                                    imgExt,
                                    sectionId,
                                    createdAt: now.toIso8601String(),
                                  );
                                  savedCount++;
                                }
                                continue;
                              }

                              final newName =
                                  'scan_${now.millisecondsSinceEpoch}_$i.$ext';
                              final destPath = '${scansDir.path}/$newName';
                              await File(path).copy(destPath);

                              final docName =
                                  'مستند $sectionName $dateStr ${i + 1}';
                              await DatabaseService.instance.insertItem(
                                docName,
                                destPath,
                                ext,
                                sectionId,
                                createdAt: now.toIso8601String(),
                              );
                              savedCount++;
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'تم حفظ $savedCount ${savedCount == 1 ? "صورة" : "صور"} بنجاح',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('فشل المسح: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ToolItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget? page;
  final VoidCallback? onTap;

  ToolItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.page,
    this.onTap,
  });
}
