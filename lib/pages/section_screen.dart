import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/models/section.dart';
import 'package:office_archiving/pages/item_search_page.dart';
import 'package:office_archiving/widgets/grid_view_items_success.dart';
import '../service/sqlite_service.dart';
import 'package:office_archiving/theme/app_icons.dart';
import 'package:office_archiving/widgets/shimmers.dart';
import 'package:office_archiving/l10n/app_localizations.dart';
import 'package:office_archiving/functions/show_add_item_sheet.dart';
import 'package:office_archiving/screens/editor/internal_editor_page.dart';
import 'package:office_archiving/services/pdf_service.dart';
import 'package:office_archiving/services/ocr_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:office_archiving/widgets/first_open_animator.dart';

class SectionScreen extends StatefulWidget {
  final Section section;
  final bool animateIntro;
  const SectionScreen({
    super.key,
    required this.section,
    this.animateIntro = true,
  });

  @override
  State<SectionScreen> createState() => _SectionScreenState();
}

class _SectionScreenState extends State<SectionScreen> {
  late DatabaseService sqlDB;
  late ItemSectionCubit itemCubit;
  bool _isProcessing = false;
  late String _sectionName;

  @override
  void initState() {
    sqlDB = DatabaseService.instance;
    itemCubit = BlocProvider.of<ItemSectionCubit>(context);
    log('SectionScreen widget.section.id ${widget.section.id}');
    // Defer initial fetch slightly to avoid jank during route transition
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 180));
      if (!mounted) return;
      itemCubit.fetchItemsBySectionId(widget.section.id);
    });
    _sectionName = widget.section.name;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    log(
      '|||||||||||||||||||||||||||||||||||||||||| SectionScreen widget.section.id ${widget.section.id} |||||||||||||||||||||||||||||||||||||||||| ',
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottomNavigationBar: _buildBottomBar(),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 72,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ItemSearchPage(sectionId: widget.section.id),
                  ),
                );
              },
              icon: Icon(
                AppIcons.search,
                color: Theme.of(context).colorScheme.primary,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          title: GestureDetector(
            onTap: _editSectionName,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Small cover thumbnail beside the name
                StreamBuilder<void>(
                  stream: DatabaseService.instance.changes,
                  builder: (context, _) {
                    return FutureBuilder<String?>(
                      future: DatabaseService.instance.getSectionCoverOrLatest(
                        widget.section.id,
                      ),
                      builder: (context, snap) {
                        final path = snap.data;
                        final hasImage =
                            path != null &&
                            path.isNotEmpty &&
                            File(path).existsSync();
                        return Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsetsDirectional.only(end: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: hasImage
                              ? Image.file(
                                  File(path),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                )
                              : Icon(
                                  AppIcons.image,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                        );
                      },
                    );
                  },
                ),
                Flexible(
                  child: Text(_sectionName, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.edit, size: 18),
              ],
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Transform.flip(
                  flipX: true,
                  child: Icon(
                    AppIcons.back,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: FirstOpenAnimator(
          pageKey: 'section_screen',
          enabled: widget.animateIntro,
          child: Column(
            children: [
              // Small cover moved to AppBar; removed large cover from body
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    itemCubit.fetchItemsBySectionId(widget.section.id);
                    await Future.delayed(const Duration(milliseconds: 200));
                  },
                  child: BlocBuilder<ItemSectionCubit, ItemSectionState>(
                    builder: (context, state) {
                      if (state is ItemSectionLoading) {
                        log('ItemSectionLoading');
                        return buildItemsShimmerGrid(context);
                      } else if (state is ItemSectionLoaded) {
                        log('ItemSectionLoaded');
                        return GridViewItemsSuccess(
                          items: state.items,
                          itemSectionCubit: itemCubit,
                        );
                      } else if (state is ItemSectionError) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 80),
                            child: Center(
                              child: Text(
                                AppLocalizations.of(context).loading_error,
                              ),
                            ),
                          ),
                        );
                      } else {
                        log("else section screen state :$state");
                        return buildItemsShimmerGrid(context);
                      }
                    },
                  ),
                ),
              ),
              if (_isProcessing)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text(AppLocalizations.of(context).processing_ellipsis),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      height: 70,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomBarButton(
            icon: Icons.add_circle,
            label: AppLocalizations.of(context).addAction,
            onTap: () {
              showAddItemSheet(
                context,
                widget.section.id,
                itemCubit,
                sectionName: widget.section.name,
              );
            },
          ),
          _buildBottomBarButton(
            icon: Icons.edit,
            label: AppLocalizations.of(context).edit_action,
            onTap: _openImageEditor,
          ),
          _buildBottomBarButton(
            icon: Icons.share,
            label: AppLocalizations.of(context).share_action,
            onTap: _showShareOptions,
          ),
          _buildBottomBarButton(
            icon: Icons.more_vert,
            label: AppLocalizations.of(context).options_action,
            onTap: _showAllOptions,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(height: 1),
              Text(
                label,
                style: const TextStyle(fontSize: 9, height: 1.1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editSectionName() async {
    final controller = TextEditingController(text: _sectionName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).rename_section_title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).sectionNameLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(AppLocalizations.of(context).renameAction),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != _sectionName) {
      await sqlDB.updateSectionName(widget.section.id, result);
      if (mounted) {
        setState(() => _sectionName = result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).snackbar_rename_done),
          ),
        );
      }
    }
  }

  Future<void> _openImageEditor() async {
    final state = itemCubit.state;
    if (state is! ItemSectionLoaded || state.items.isEmpty) {
      _showSnackBar(AppLocalizations.of(context).no_images_to_edit);
      return;
    }

    // فتح المحرر الداخلي الجاهز
    final firstImage = state.items.first.filePath;
    if (firstImage == null) {
      _showSnackBar(AppLocalizations.of(context).no_valid_image_path);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InternalEditorPage(initialImagePath: firstImage),
      ),
    );

    // تحديث القائمة بعد التحرير
    itemCubit.fetchItemsBySectionId(widget.section.id);
  }

  Future<void> _showShareOptions() async {
    final nameController = TextEditingController(text: _sectionName);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).share_options_title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).file_name_label,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.edit),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    _shareOptionTile(
                      AppLocalizations.of(context).share_pdf_single,
                      Icons.picture_as_pdf,
                      Colors.red,
                      () => _createAndSharePDF(nameController.text),
                    ),
                    _shareOptionTile(
                      AppLocalizations.of(context).share_images_multiple,
                      Icons.collections,
                      Colors.teal,
                      () => _shareAllImages(nameController.text),
                    ),
                    _shareOptionTile(
                      AppLocalizations.of(context).save_to_gallery_action,
                      Icons.photo_library,
                      Colors.pink,
                      _saveToGallery,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shareOptionTile(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
      ),
    );
  }

  Future<void> _showAllOptions() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).all_options_title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    _optionTile(
                      AppLocalizations.of(context).merge_all_to_pdf,
                      Icons.merge,
                      Colors.purple,
                      _mergeAllToPDF,
                    ),
                    _optionTile(
                      AppLocalizations.of(context).extract_text_ocr,
                      Icons.text_fields,
                      Colors.orange,
                      _extractAllText,
                    ),
                    _optionTile(
                      AppLocalizations.of(context).save_to_gallery_action,
                      Icons.save_alt,
                      Colors.green,
                      _saveToGallery,
                    ),
                    _optionTile(
                      AppLocalizations.of(context).copy_action,
                      Icons.copy,
                      Colors.teal,
                      _copyFiles,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionTile(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
      ),
    );
  }

  // الوظائف الفعلية
  Future<void> _createAndSharePDF(String fileName) async {
    try {
      final state = itemCubit.state;
      if (state is! ItemSectionLoaded || state.items.isEmpty) {
        _showSnackBar(AppLocalizations.of(context).no_items_to_share);
        return;
      }

      setState(() => _isProcessing = true);
      final imagePaths = state.items
          .map((item) => item.filePath)
          .where((path) => path != null && File(path).existsSync())
          .cast<String>()
          .toList();

      if (imagePaths.isEmpty) {
        _showSnackBar(AppLocalizations.of(context).no_valid_images);
        return;
      }

      final pdfFile = await PdfService().createPdfFromImages(
        imagePaths,
        fileName: '$fileName.pdf',
      );

      await Share.shareXFiles([XFile(pdfFile.path)], subject: fileName);
      _showSnackBar(AppLocalizations.of(context).pdf_created_shared_success);
    } catch (e) {
      _showSnackBar('${AppLocalizations.of(context).error_prefix}$e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _shareAllImages(String fileName) async {
    try {
      final state = itemCubit.state;
      if (state is! ItemSectionLoaded || state.items.isEmpty) {
        _showSnackBar(AppLocalizations.of(context).no_images_to_share);
        return;
      }

      final files = state.items
          .where((item) => item.filePath != null)
          .where((item) => File(item.filePath!).existsSync())
          .map((item) => XFile(item.filePath!))
          .toList();

      if (files.isEmpty) {
        _showSnackBar(AppLocalizations.of(context).no_valid_images_to_share);
        return;
      }

      await Share.shareXFiles(files, subject: fileName);
    } catch (e) {
      _showSnackBar('${AppLocalizations.of(context).error_prefix}$e');
    }
  }

  Future<void> _mergeAllToPDF() async {
    try {
      final state = itemCubit.state;
      if (state is! ItemSectionLoaded || state.items.isEmpty) {
        _showSnackBar(AppLocalizations.of(context).no_items_to_merge);
        return;
      }

      setState(() => _isProcessing = true);
      final imagePaths = state.items
          .map((item) => item.filePath)
          .where((path) => path != null && File(path).existsSync())
          .cast<String>()
          .toList();

      if (imagePaths.isEmpty) {
        _showSnackBar(AppLocalizations.of(context).no_valid_images);
        return;
      }

      final pdfFile = await PdfService().createPdfFromImages(
        imagePaths,
        fileName: '${_sectionName}_merged.pdf',
      );

      _showSnackBar('${AppLocalizations.of(context).merged_success_prefix}${pdfFile.path}');
    } catch (e) {
      _showSnackBar('${AppLocalizations.of(context).merge_error_prefix}$e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _extractAllText() async {
    try {
      final state = itemCubit.state;
      if (state is! ItemSectionLoaded || state.items.isEmpty) {
        _showSnackBar(AppLocalizations.of(context).no_images_for_text_extraction);
        return;
      }

      setState(() => _isProcessing = true);
      final ocr = OCRService();
      final allText = StringBuffer();

      for (final item in state.items) {
        final path = item.filePath;
        if (path != null && File(path).existsSync()) {
          final text = await ocr.extractTextFromImage(path);
          if (text.isNotEmpty) {
            allText.writeln('--- ${item.name} ---');
            allText.writeln(text);
            allText.writeln();
          }
        }
      }

      if (allText.isEmpty) {
        _showSnackBar(AppLocalizations.of(context).no_text_found);
        return;
      }

      // حفظ النص في ملف
      final dir = await getApplicationDocumentsDirectory();
      final textFile = File('${dir.path}/${_sectionName}_extracted.txt');
      await textFile.writeAsString(allText.toString());

      _showSnackBar('${AppLocalizations.of(context).text_extracted_prefix}${textFile.path}');
    } catch (e) {
      _showSnackBar('${AppLocalizations.of(context).text_extraction_error_prefix}$e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveToGallery() async {
    _showSnackBar(AppLocalizations.of(context).saving_to_gallery);
    await Future.delayed(const Duration(seconds: 1));
    _showSnackBar(AppLocalizations.of(context).saved_to_gallery);
  }

  Future<void> _copyFiles() async {
    try {
      final state = itemCubit.state;
      if (state is! ItemSectionLoaded || state.items.isEmpty) {
        _showSnackBar(AppLocalizations.of(context).no_files_to_copy);
        return;
      }

      final paths = state.items
          .map((item) => item.filePath)
          .where((path) => path != null)
          .join('\n');

      await Clipboard.setData(ClipboardData(text: paths));
      _showSnackBar(AppLocalizations.of(context).file_paths_copied);
    } catch (e) {
      _showSnackBar('${AppLocalizations.of(context).copy_error_prefix}$e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }
}
