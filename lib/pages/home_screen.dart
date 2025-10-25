import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:office_archiving/cubit/section_cubit/section_cubit.dart';
import 'package:office_archiving/widgets/section_list_view.dart';
import 'package:office_archiving/widgets/shimmers.dart';
import 'package:office_archiving/functions/show_add_section_dialog.dart';
import 'package:office_archiving/pages/document_management_page.dart';
import 'package:office_archiving/pages/ai_features_page.dart';
import 'package:office_archiving/pages/settings_page.dart';
import 'package:office_archiving/pages/document_scanner_page.dart';
import 'package:office_archiving/pages/professional_tools_page.dart';
import 'package:office_archiving/l10n/app_localizations.dart';
import 'package:office_archiving/pages/storage_center_page.dart';

import '../service/sqlite_service.dart';

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
        final totalFiles = data != null ? (data['totalFiles'] as int? ?? 0) : 0;
        final totalSections = data != null ? (data['totalSections'] as int? ?? 0) : 0;
        final totalSize = data != null ? (data['totalSizeBytes'] as num? ?? 0).toDouble() : 0.0;

        Widget card(String title, String value, Color color, IconData icon) {
          return Expanded(
            child: Container(
              height: 76,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

        String formatBytes(double bytes) {
          if (bytes < 1024) return '${bytes.toInt()} B';
          if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
          if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
            card(AppLocalizations.of(context).total_files, '$totalFiles', Colors.blue, Icons.description),
            const SizedBox(width: 8),
            card(AppLocalizations.of(context).sections, '$totalSections', Colors.green, Icons.folder),
            const SizedBox(width: 8),
            card(AppLocalizations.of(context).storage_size, formatBytes(totalSize), Colors.orange, Icons.storage),
          ],
        );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    log('.............................Building HomeScreen......................................');
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context).appTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        elevation: 2,
      ),
      bottomNavigationBar: _buildBottomBar(context),
      body: Column(
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
                      sections: state.sections, sectionCubit: sectionCubit);
                } else if (state is SectionError) {
                  log('Failed to load sections: ${state.message}');
                  return Center(
                      child: Text('Failed to load sections: ${state.message}'));
                } else {
                  log('else  $state');
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
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
                      color: scheme.shadow.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, -4),
                    ),
                  ],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Scanner
                    IconButton(
                      tooltip: AppLocalizations.of(context).tooltip_scanner,
                      icon: const Icon(Icons.document_scanner_rounded),
                      color: scheme.primary,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DocumentScannerPage(),
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
                        width: 72), // space reserved for center button
                    // Professional Tools
                    IconButton(
                      tooltip: 'أدوات احترافية',
                      icon: const Icon(Icons.construction_rounded),
                      color: scheme.primary,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfessionalToolsPage(),
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
                      context, sectionNameController, sectionCubit);
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        scheme.primary,
                        scheme.primary.withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withOpacity(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
