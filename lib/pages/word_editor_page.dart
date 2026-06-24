import 'package:flutter/material.dart';
import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/services/office_document_service.dart';
import 'package:office_archiving/services/sqlite_service.dart';
import 'package:path/path.dart' as p;

/// إنشاء ملف Word (.docx) بسيط: عنوان + نص (كل سطر فقرة).
class WordEditorPage extends StatefulWidget {
  const WordEditorPage({
    super.key,
    required this.sectionId,
    required this.itemCubit,
  });

  final int sectionId;
  final ItemSectionCubit itemCubit;

  @override
  State<WordEditorPage> createState() => _WordEditorPageState();
}

class _WordEditorPageState extends State<WordEditorPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  String _t({required String ar, required String en}) =>
      Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _snack(_t(ar: 'أدخل اسم الملف', en: 'Enter a file name'));
      return;
    }
    setState(() => _saving = true);
    try {
      final paragraphs = _bodyController.text
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
      final file = await OfficeDocumentService.instance.createWordFile(
        title: title,
        paragraphs: paragraphs,
      );
      await DatabaseService.instance.insertItem(
        p.basenameWithoutExtension(file.path),
        file.path,
        'docx',
        widget.sectionId,
      );
      await widget.itemCubit.refreshItems(widget.sectionId);
      if (!mounted) return;
      _snack(_t(ar: 'تم إنشاء ملف Word', en: 'Word file created'));
      Navigator.pop(context, true);
    } catch (e) {
      _snack('${_t(ar: 'خطأ', en: 'Error')}: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_t(ar: 'ملف Word جديد', en: 'New Word file')),
          actions: [
            IconButton(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: _t(ar: 'اسم الملف / العنوان', en: 'File / title'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _bodyController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: _t(
                      ar: 'محتوى المستند (كل سطر فقرة)...',
                      en: 'Document content (one paragraph per line)...',
                    ),
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
