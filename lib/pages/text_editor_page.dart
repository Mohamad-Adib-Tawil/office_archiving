import 'dart:io';

import 'package:flutter/material.dart';
import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/services/office_document_service.dart';
import 'package:office_archiving/services/sqlite_service.dart';
import 'package:path/path.dart' as p;

/// محرّر نصّي كامل داخل التطبيق.
/// - وضع الإنشاء: مرّر [sectionId] + [itemCubit] فيُنشأ ملف `.txt` ويُضاف للقسم.
/// - وضع التعديل: مرّر [existingPath] فيُحرَّر نفس الملف ويُحفظ مكانه.
class TextEditorPage extends StatefulWidget {
  const TextEditorPage({
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
  State<TextEditorPage> createState() => _TextEditorPageState();
}

class _TextEditorPageState extends State<TextEditorPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _saving = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _titleController.text = p.basenameWithoutExtension(widget.existingPath!);
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final file = File(widget.existingPath!);
      if (await file.exists()) {
        _bodyController.text = await file.readAsString();
      }
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
    if (!widget.isEditing && title.isEmpty) {
      _snack(_t(ar: 'أدخل اسم المستند', en: 'Enter a document name'));
      return;
    }
    setState(() => _saving = true);
    try {
      final file = await OfficeDocumentService.instance.createOrUpdateTextFile(
        title: title.isEmpty ? 'document' : title,
        body: _bodyController.text,
        existingPath: widget.existingPath,
      );

      if (!widget.isEditing) {
        await DatabaseService.instance.insertItem(
          p.basenameWithoutExtension(file.path),
          file.path,
          'txt',
          widget.sectionId!,
        );
        if (widget.itemCubit != null) {
          await widget.itemCubit!.refreshItems(widget.sectionId!);
        }
      }
      if (!mounted) return;
      _snack(_t(ar: 'تم الحفظ', en: 'Saved'));
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
          title: Text(
            widget.isEditing
                ? _t(ar: 'تعديل مستند نصّي', en: 'Edit text document')
                : _t(ar: 'مستند نصّي جديد', en: 'New text document'),
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
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (!widget.isEditing)
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: _t(
                            ar: 'اسم المستند',
                            en: 'Document name',
                          ),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.title),
                        ),
                      ),
                    if (!widget.isEditing) const SizedBox(height: 12),
                    Expanded(
                      child: TextField(
                        controller: _bodyController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText: _t(
                            ar: 'اكتب هنا...',
                            en: 'Write here...',
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
