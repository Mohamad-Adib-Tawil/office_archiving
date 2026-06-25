import 'package:flutter/material.dart';
import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/services/office_document_service.dart';
import 'package:office_archiving/services/sqlite_service.dart';
import 'package:path/path.dart' as p;

/// محرّر ملف Word (.docx):
/// - وضع الإنشاء: مرّر [sectionId] + [itemCubit]
/// - وضع التعديل: مرّر [existingPath] — يُحمَّل نص المستند ويُحفظ مكانه
class WordEditorPage extends StatefulWidget {
  const WordEditorPage({
    super.key,
    this.sectionId,
    this.itemCubit,
    this.existingPath,
  });

  final int? sectionId;
  final ItemSectionCubit? itemCubit;
  final String? existingPath;

  bool get isEditing => existingPath != null;

  @override
  State<WordEditorPage> createState() => _WordEditorPageState();
}

class _WordEditorPageState extends State<WordEditorPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _saving = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _titleController.text =
          p.basenameWithoutExtension(widget.existingPath!);
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final paragraphs = await OfficeDocumentService.instance
          .readDocxParagraphs(widget.existingPath!);
      _bodyController.text = paragraphs.join('\n');
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
        existingPath: widget.existingPath,
      );
      if (!widget.isEditing) {
        await DatabaseService.instance.insertItem(
          p.basenameWithoutExtension(file.path),
          file.path,
          'docx',
          widget.sectionId!,
        );
        await widget.itemCubit?.refreshItems(widget.sectionId!);
      }
      if (!mounted) return;
      _snack(_t(
        ar: widget.isEditing ? 'تم حفظ التعديلات' : 'تم إنشاء ملف Word',
        en: widget.isEditing ? 'Saved' : 'Word file created',
      ));
      Navigator.pop(context, true);
    } catch (e) {
      _snack('${_t(ar: 'خطأ', en: 'Error')}: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isEditing
                ? _t(ar: 'تعديل ملف Word', en: 'Edit Word file')
                : _t(ar: 'ملف Word جديد', en: 'New Word file'),
          ),
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
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (widget.isEditing)
                    Container(
                      width: double.infinity,
                      color: Colors.amber.shade50,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _t(
                                ar: 'يُحفظ النص فقط — التنسيق المعقد (صور/جداول) لا يُحتفظ به',
                                en: 'Text only — complex formatting (images/tables) is not preserved',
                              ),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: _titleController,
                      readOnly: widget.isEditing,
                      decoration: InputDecoration(
                        labelText:
                            _t(ar: 'اسم الملف / العنوان', en: 'File / title'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.title),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                  ),
                ],
              ),
      ),
    );
  }
}
