import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:office_archiving/pages/qr_barcode_scanner.dart';
import 'dart:io';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:office_archiving/pages/business_card_scanner.dart';
import 'package:office_archiving/pages/pdf_security_page.dart';
import 'package:office_archiving/pages/pdf_editor_page.dart';
import 'package:office_archiving/pages/document_management_page.dart';
import 'package:office_archiving/service/sqlite_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:office_archiving/l10n/app_localizations.dart';
import 'package:office_archiving/services/scanner_import_service.dart';
import 'package:office_archiving/widgets/first_open_animator.dart';

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
      body: FirstOpenAnimator(
        pageKey: 'professional_tools_page',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(context),
              const SizedBox(height: 24),

              Text(
                AppLocalizations.of(context).scan_capture_tools_title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildToolGrid(context, [
                ToolItem(
                  title: AppLocalizations.of(context).tool_scanner_title,
                  subtitle: AppLocalizations.of(context).tool_scanner_sub,
                  icon: Icons.document_scanner,
                  color: Colors.blue,
                  onTap: () => _showSectionSelectionForScanner(context),
                ),
                ToolItem(
                  title: AppLocalizations.of(context).tool_bizcard_title,
                  subtitle: AppLocalizations.of(context).tool_bizcard_sub,
                  icon: Icons.credit_card,
                  color: Colors.green,
                  page: const BusinessCardScannerPage(),
                ),
                ToolItem(
                  title: AppLocalizations.of(context).tool_qr_title,
                  subtitle: AppLocalizations.of(context).tool_qr_sub,
                  icon: Icons.qr_code_scanner,
                  color: Colors.orange,
                  page: const QRBarcodeScannerPage(),
                ),
              ]),

              const SizedBox(height: 24),

              Text(
                AppLocalizations.of(context).advanced_pdf_tools_title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildToolGrid(context, [
                ToolItem(
                  title: 'PDF Security',
                  subtitle: AppLocalizations.of(context).tool_pdf_security_sub,
                  icon: Icons.security,
                  color: Colors.red,
                  onTap: () => _openPdfPickerForSecurity(context),
                ),
                ToolItem(
                  title: AppLocalizations.of(context).tool_pdf_editor_title,
                  subtitle: AppLocalizations.of(context).tool_pdf_editor_sub,
                  icon: Icons.edit_document,
                  color: Colors.purple,
                  onTap: () => _openPdfPickerForEditor(context),
                ),
                ToolItem(
                  title: AppLocalizations.of(context).tool_pdf_merge_title,
                  subtitle: AppLocalizations.of(context).tool_pdf_merge_sub,
                  icon: Icons.merge,
                  color: Colors.teal,
                  page: const DocumentManagementPage(),
                ),
              ]),

              const SizedBox(height: 24),

              Text(
                AppLocalizations.of(context).extra_tools_title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildToolGrid(context, [
                ToolItem(
                  title: AppLocalizations.of(context).tool_report_gen_title,
                  subtitle: AppLocalizations.of(context).tool_report_gen_sub,
                  icon: Icons.assessment,
                  color: Colors.indigo,
                  onTap: () => _showComingSoon(context),
                ),
                ToolItem(
                  title: AppLocalizations.of(context).tool_cloud_backup_title,
                  subtitle: AppLocalizations.of(context).tool_cloud_backup_sub,
                  icon: Icons.cloud_sync,
                  color: Colors.lightBlue,
                  onTap: () => _showComingSoon(context),
                ),
                ToolItem(
                  title: AppLocalizations.of(context).tool_advanced_share_title,
                  subtitle: AppLocalizations.of(
                    context,
                  ).tool_advanced_share_sub,
                  icon: Icons.share_outlined,
                  color: Colors.amber,
                  onTap: () => _showComingSoon(context),
                ),
              ]),
            ],
          ),
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
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).header_title_prof_tools,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).header_sub_prof_tools,
                style: const TextStyle(color: Colors.white, fontSize: 14),
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
        SnackBar(
          content: Text(AppLocalizations.of(context).no_sections_available),
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
              Row(
                children: [
                  const Icon(
                    Icons.folder_outlined,
                    color: Colors.blue,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context).choose_section_to_scan_title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
                          section['name'] ??
                              AppLocalizations.of(context).section_default_name,
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
                            final imported = await ScannerImportService.instance
                                .importScannerResultToSection(
                                  rawResult: result,
                                  sectionId: sectionId,
                                  sectionName: sectionName,
                                );

                            if (imported.savedCount == 0) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(
                                        context,
                                      ).no_document_captured,
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                              return;
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'تم حفظ ${imported.savedCount} ${imported.savedCount == 1 ? "صورة" : "صور"} بنجاح',
                                  ),
                                  backgroundColor: Colors.green,
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
