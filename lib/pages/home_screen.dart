import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:office_archiving/cubit/section_cubit/section_cubit.dart';
import 'package:office_archiving/widgets/section_list_view.dart';
import 'package:office_archiving/widgets/shimmers.dart';
import 'package:office_archiving/functions/show_add_section_dialog.dart';
import 'package:office_archiving/pages/ai_features_page.dart';
import 'package:office_archiving/pages/settings_page.dart';
import 'package:office_archiving/pages/tools_documents_center_page.dart';
import 'package:office_archiving/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:intl/intl.dart';

import '../service/sqlite_service.dart';
import 'package:office_archiving/services/pdf_service.dart';
import 'package:office_archiving/pages/storage_center_page.dart';
import 'package:office_archiving/widgets/first_open_animator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DatabaseService sqlDB;
  late SectionCubit sectionCubit;
  final TextEditingController sectionNameController = TextEditingController();

  @override
  void initState() {
    sqlDB = DatabaseService.instance;
    sectionCubit = BlocProvider.of<SectionCubit>(context);
    sectionCubit.loadSections();
    super.initState();
  }

  @override
  void dispose() {
    sectionNameController.dispose();
    super.dispose();
  }

  Widget _buildStorageSummary(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<void>(
      stream: DatabaseService.instance.changes,
      builder: (context, _) {
        return FutureBuilder<Map<String, dynamic>>(
          future: DatabaseService.instance.getStorageAnalytics(),
          builder: (context, snapshot) {
            final loading = snapshot.connectionState == ConnectionState.waiting;
            final data = snapshot.data;
            final totalFiles = data != null
                ? (data['totalFiles'] as int? ?? 0)
                : 0;
            final totalSections = data != null
                ? (data['totalSections'] as int? ?? 0)
                : 0;
            final totalSize = data != null
                ? (data['totalSizeBytes'] as num? ?? 0).toDouble()
                : 0.0;

            Widget card(
              String title,
              String value,
              Color color,
              IconData icon,
            ) {
              return Expanded(
                flex: 3,
                child: Container(
                  height: 76,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: color, size: 20),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              value,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.fade,
                              softWrap: false,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }

            // Larger, more prominent card for storage size
            Widget storageCard(
              String title,
              String value,
              Color color,
              IconData icon,
            ) {
              return Expanded(
                flex: 6,
                child: Container(
                  height: 76,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: color.withValues(alpha: 0.28),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: color, size: 22),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              value,
                              style: const TextStyle(
                                fontSize: 20,
                                height: 1.1,
                                fontWeight: FontWeight.w900,
                              ),
                              overflow: TextOverflow.fade,
                              softWrap: false,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }

            String formatBytes(double bytes) {
              if (bytes < 1024) return '${bytes.toInt()} B';
              if (bytes < 1024 * 1024)
                return '${(bytes / 1024).toStringAsFixed(1)} KB';
              if (bytes < 1024 * 1024 * 1024)
                return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
              return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
            }

            if (loading) {
              return Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 76, // نفس ارتفاع البطاقات
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 76,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 76,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              );
            }

            return Row(
              children: [
                card(
                  AppLocalizations.of(context).total_files,
                  '$totalFiles',
                  Colors.blue,
                  Icons.description,
                ),
                const SizedBox(width: 8),
                card(
                  AppLocalizations.of(context).sections,
                  '$totalSections',
                  Colors.green,
                  Icons.folder,
                ),
                const SizedBox(width: 8),
                storageCard(
                  AppLocalizations.of(context).storage_size,
                  formatBytes(totalSize),
                  Colors.orange,
                  Icons.storage,
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    log(
      '.............................Building HomeScreen......................................',
    );
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context).appTitle,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        elevation: 2,
      ),
      bottomNavigationBar: _buildBottomBar(context),
      body: FirstOpenAnimator(
        pageKey: 'home_screen',
        child: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildStorageSummary(context),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<SectionCubit, SectionState>(
              builder: (context, state) {
                if (state is SectionLoading) {
                  log('HomeScreen SectionLoading Received state');
                  return buildSectionsShimmerGrid(context);
                } else if (state is SectionLoaded) {
                  log('Sections loaded successfully: ${state.sections}');
                  return SectionListView(
                    sections: state.sections,
                    sectionCubit: sectionCubit,
                  );
                } else if (state is SectionError) {
                  log('Failed to load sections: ${state.message}');
                  return Center(
                    child: Text('Failed to load sections: ${state.message}'),
                  );
                } else {
                  log('else  $state');
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 84,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background bar
            Positioned.fill(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, -4),
                    ),
                  ],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Storage Center (replaces Document Management)
                    IconButton(
                      tooltip: AppLocalizations.of(context).storage_center_title,
                      icon: const Icon(Icons.storage_rounded),
                      color: scheme.primary,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StorageCenterPage(),
                          ),
                        );
                      },
                    ),
                    // AI
                    IconButton(
                      tooltip: AppLocalizations.of(context).tooltip_ai,
                      icon: const Icon(Icons.psychology_rounded),
                      color: scheme.primary,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AIFeaturesPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(
                      width: 72,
                    ), // space reserved for center button
                    // Professional Tools (opens combined Tools & Documents center)
                    IconButton(
                      tooltip: AppLocalizations.of(context).tooltip_professional_tools,
                      icon: const Icon(Icons.construction_rounded),
                      color: scheme.primary,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ToolsDocumentsCenterPage(),
                          ),
                        );
                      },
                    ),
                    // Settings
                    IconButton(
                      tooltip: AppLocalizations.of(context).settings_tooltip,
                      icon: const Icon(Icons.settings_rounded),
                      color: scheme.primary,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Center Add button
            Positioned(
              top: 0,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  showAddSectionDialog(
                    context,
                    sectionNameController,
                    sectionCubit,
                  );
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        scheme.primary,
                        scheme.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ],
        ),
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
                              // محاولة الوصول لخصائص ديناميكية
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
