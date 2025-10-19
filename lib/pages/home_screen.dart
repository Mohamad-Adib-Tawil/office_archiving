import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:office_archiving/cubit/section_cubit/section_cubit.dart';
import 'package:office_archiving/widgets/custom_appbar_widget_app.dart';
import 'package:office_archiving/widgets/section_list_view.dart';
import 'package:office_archiving/widgets/shimmers.dart';
import 'package:office_archiving/functions/show_add_section_dialog.dart';
import 'package:office_archiving/pages/document_management_page.dart';
import 'package:office_archiving/pages/ai_features_page.dart';
import 'package:office_archiving/pages/file_cleanup_page.dart';
import 'package:office_archiving/widgets/settings_sheet.dart';

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
  Widget build(BuildContext context) {
    log('.............................Building HomeScreen......................................');
    return Scaffold(
      appBar: const CustomAppBarWidgetApp(showActions: false),
      bottomNavigationBar: _buildBottomBar(context),
      body: BlocBuilder<SectionCubit, SectionState>(
        builder: (context, state) {
          if (state is SectionLoading) {
            log('HomeScreen SectionLoading Received state');
            return buildSectionsShimmerGrid(context);
          } else if (state is SectionLoaded) {
            log('Sections loaded successfully: ${state.sections}');
            return SectionListView(
              sections: state.sections, 
              sectionCubit: sectionCubit
            );
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Scanner
                    IconButton(
                      tooltip: 'الماسح الضوئي',
                      icon: const Icon(Icons.document_scanner_rounded),
                      color: scheme.primary,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DocumentManagementPage(),
                          ),
                        );
                      },
                    ),
                    // AI
                    IconButton(
                      tooltip: 'الذكاء الاصطناعي',
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
                    const SizedBox(width: 72), // space reserved for center button
                    // Cleaner
                    IconButton(
                      tooltip: 'منظف الملفات',
                      icon: const Icon(Icons.cleaning_services_rounded),
                      color: scheme.primary,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FileCleanupPage(),
                          ),
                        );
                      },
                    ),
                    // Settings
                    IconButton(
                      tooltip: 'الإعدادات',
                      icon: const Icon(Icons.settings_rounded),
                      color: scheme.primary,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (_) => const SettingsSheet(),
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
                  showAddSectionDialog(context, sectionNameController, sectionCubit);
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
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
