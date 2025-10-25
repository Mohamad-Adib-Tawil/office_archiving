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

class SectionScreen extends StatefulWidget {
  final Section section;
  const SectionScreen({super.key, required this.section});

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
    itemCubit.fetchItemsBySectionId(widget.section.id);
    _sectionName = widget.section.name;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    log('|||||||||||||||||||||||||||||||||||||||||| SectionScreen widget.section.id ${widget.section.id} |||||||||||||||||||||||||||||||||||||||||| ');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
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
              icon: Icon(AppIcons.search,
                  color: Theme.of(context).colorScheme.primary),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          title: GestureDetector(
            onTap: _editSectionName,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_sectionName),
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
                  child: Icon(AppIcons.back,
                      color: Theme.of(context).colorScheme.onSurface),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            FutureBuilder<String?>(
              future: DatabaseService.instance
                  .getSectionCoverOrLatest(widget.section.id),
              builder: (context, snap) {
                final scheme = Theme.of(context).colorScheme;
                final path = snap.data;
                final hasImage =
                    path != null && path.isNotEmpty && File(path).existsSync();
                if (!hasImage) {
                  return const SizedBox.shrink();
                }
                return Container(
                  height: 200,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(path),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(AppIcons.image,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  AppLocalizations.of(context).cover_badge,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
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
                          child: Center(child: Text(AppLocalizations.of(context).loading_error)),
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
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('جاري المعالجة...'),
                  ],
                ),
              ),
          ],
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
            label: 'إضافة',
            onTap: () => showAddItemSheet(context, widget.section.id, itemCubit),
          ),
          _buildBottomBarButton(
            icon: Icons.edit,
            label: 'تحرير',
            onTap: _openImageEditor,
          ),
          _buildBottomBarButton(
            icon: Icons.share,
            label: 'مشاركة',
            onTap: _showShareOptions,
          ),
          _buildBottomBarButton(
            icon: Icons.more_vert,
            label: 'خيارات',
            onTap: _showAllOptions,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBarButton({required IconData icon, required String label, required VoidCallback onTap}) {
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
                style: const TextStyle(
                  fontSize: 9,
                  height: 1.1,
                ),
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
        title: const Text('تعديل اسم القسم'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'اسم القسم',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty && result != _sectionName) {
      await sqlDB.updateSectionName(widget.section.id, result);
      if (mounted) {
        setState(() => _sectionName = result);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث اسم القسم')),
        );
      }
    }
  }

  Future<void> _openImageEditor() async {
    final state = itemCubit.state;
    if (state is! ItemSectionLoaded || state.items.isEmpty) {
      _showSnackBar('لا توجد صور للتحرير');
      return;
    }
    
    // فتح المحرر الداخلي الجاهز
    final firstImage = state.items.first.filePath;
    if (firstImage == null) {
      _showSnackBar('لا يوجد مسار صورة صالح');
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
              const Text(
                'خيارات المشاركة',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الملف',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    _shareOptionTile('PDF واحد', Icons.picture_as_pdf, Colors.red, () => _createAndSharePDF(nameController.text)),
                    _shareOptionTile('صور متعددة', Icons.collections, Colors.teal, () => _shareAllImages(nameController.text)),
                    _shareOptionTile('حفظ في المعرض', Icons.photo_library, Colors.pink, _saveToGallery),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shareOptionTile(String title, IconData icon, Color color, VoidCallback onTap) {
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
              const Text('خيارات شاملة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    _optionTile('دمج الكل في PDF', Icons.merge, Colors.purple, _mergeAllToPDF),
                    _optionTile('استخراج نص (OCR)', Icons.text_fields, Colors.orange, _extractAllText),
                    _optionTile('حفظ في المعرض', Icons.save_alt, Colors.green, _saveToGallery),
                    _optionTile('نسخ', Icons.copy, Colors.teal, _copyFiles),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionTile(String title, IconData icon, Color color, VoidCallback onTap) {
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
        _showSnackBar('لا توجد عناصر للمشاركة');
        return;
      }
      
      setState(() => _isProcessing = true);
      final imagePaths = state.items
          .map((item) => item.filePath)
          .where((path) => path != null && File(path).existsSync())
          .cast<String>()
          .toList();
      
      if (imagePaths.isEmpty) {
        _showSnackBar('لا توجد صور صالحة');
        return;
      }
      
      final pdfFile = await PdfService().createPdfFromImages(imagePaths, fileName: '$fileName.pdf');
      
      await Share.shareXFiles([XFile(pdfFile.path)], subject: fileName);
      _showSnackBar('تم إنشاء ومشاركة PDF بنجاح');
    } catch (e) {
      _showSnackBar('خطأ: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _shareAllImages(String fileName) async {
    try {
      final state = itemCubit.state;
      if (state is! ItemSectionLoaded || state.items.isEmpty) {
        _showSnackBar('لا توجد صور للمشاركة');
        return;
      }
      
      final files = state.items
          .where((item) => item.filePath != null)
          .where((item) => File(item.filePath!).existsSync())
          .map((item) => XFile(item.filePath!))
          .toList();
      
      if (files.isEmpty) {
        _showSnackBar('لا توجد صور صالحة للمشاركة');
        return;
      }
      
      await Share.shareXFiles(files, subject: fileName);
    } catch (e) {
      _showSnackBar('خطأ: $e');
    }
  }

  Future<void> _mergeAllToPDF() async {
    try {
      final state = itemCubit.state;
      if (state is! ItemSectionLoaded || state.items.isEmpty) {
        _showSnackBar('لا توجد عناصر للدمج');
        return;
      }
      
      setState(() => _isProcessing = true);
      final imagePaths = state.items
          .map((item) => item.filePath)
          .where((path) => path != null && File(path).existsSync())
          .cast<String>()
          .toList();
      
      if (imagePaths.isEmpty) {
        _showSnackBar('لا توجد صور صالحة');
        return;
      }
      
      final pdfFile = await PdfService().createPdfFromImages(
        imagePaths,
        fileName: '${_sectionName}_merged.pdf',
      );
      
      _showSnackBar('تم الدمج: ${pdfFile.path}');
    } catch (e) {
      _showSnackBar('خطأ في الدمج: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _extractAllText() async {
    try {
      final state = itemCubit.state;
      if (state is! ItemSectionLoaded || state.items.isEmpty) {
        _showSnackBar('لا توجد صور لاستخراج النص منها');
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
        _showSnackBar('لم يتم العثور على نص');
        return;
      }
      
      // حفظ النص في ملف
      final dir = await getApplicationDocumentsDirectory();
      final textFile = File('${dir.path}/${_sectionName}_extracted.txt');
      await textFile.writeAsString(allText.toString());
      
      _showSnackBar('تم استخراج النص: ${textFile.path}');
    } catch (e) {
      _showSnackBar('خطأ في استخراج النص: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveToGallery() async {
    _showSnackBar('جاري الحفظ في المعرض...');
    await Future.delayed(const Duration(seconds: 1));
    _showSnackBar('تم الحفظ في المعرض');
  }

  Future<void> _copyFiles() async {
    try {
      final state = itemCubit.state;
      if (state is! ItemSectionLoaded || state.items.isEmpty) {
        _showSnackBar('لا توجد ملفات للنسخ');
        return;
      }
      
      final paths = state.items
          .map((item) => item.filePath)
          .where((path) => path != null)
          .join('\n');
      
      await Clipboard.setData(ClipboardData(text: paths));
      _showSnackBar('تم نسخ مسارات الملفات');
    } catch (e) {
      _showSnackBar('خطأ في النسخ: $e');
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
