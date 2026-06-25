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
  bool _showSearch = false;
  final _searchController = TextEditingController();
  int _searchMatchIndex = 0;
  List<int> _searchOffsets = [];

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
    _searchController.dispose();
    super.dispose();
  }

  void _runSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchOffsets = [];
        _searchMatchIndex = 0;
      });
      return;
    }
    final text = _bodyController.text.toLowerCase();
    final q = query.toLowerCase();
    final offsets = <int>[];
    int start = 0;
    while (true) {
      final idx = text.indexOf(q, start);
      if (idx == -1) break;
      offsets.add(idx);
      start = idx + 1;
    }
    setState(() {
      _searchOffsets = offsets;
      _searchMatchIndex = 0;
    });
    _jumpToMatch(0);
  }

  void _jumpToMatch(int index) {
    if (_searchOffsets.isEmpty) return;
    final i = index.clamp(0, _searchOffsets.length - 1);
    final offset = _searchOffsets[i];
    final len = _searchController.text.length;
    _bodyController.selection = TextSelection(
      baseOffset: offset,
      extentOffset: offset + len,
    );
    setState(() => _searchMatchIndex = i);
  }

  void _nextMatch() => _jumpToMatch(_searchMatchIndex + 1 < _searchOffsets.length
      ? _searchMatchIndex + 1
      : 0);

  void _prevMatch() => _jumpToMatch(_searchMatchIndex - 1 >= 0
      ? _searchMatchIndex - 1
      : _searchOffsets.length - 1);

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
          title: _showSearch
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: _t(ar: 'بحث...', en: 'Search...'),
                    border: InputBorder.none,
                  ),
                  onSubmitted: _runSearch,
                  onChanged: (v) {
                    if (v.isEmpty) {
                      setState(() {
                        _searchOffsets = [];
                        _searchMatchIndex = 0;
                      });
                    }
                  },
                )
              : Text(
                  widget.isEditing
                      ? _t(ar: 'تعديل مستند نصّي', en: 'Edit text document')
                      : _t(ar: 'مستند نصّي جديد', en: 'New text document'),
                ),
          actions: [
            if (_showSearch && _searchOffsets.isNotEmpty) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '${_searchMatchIndex + 1}/${_searchOffsets.length}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up),
                tooltip: _t(ar: 'السابق', en: 'Previous'),
                onPressed: _prevMatch,
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down),
                tooltip: _t(ar: 'التالي', en: 'Next'),
                onPressed: _nextMatch,
              ),
            ],
            IconButton(
              icon: Icon(_showSearch ? Icons.close : Icons.search),
              tooltip: _showSearch
                  ? _t(ar: 'إغلاق', en: 'Close')
                  : _t(ar: 'بحث', en: 'Search'),
              onPressed: () {
                setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _searchController.clear();
                    _searchOffsets = [];
                  }
                });
              },
            ),
            if (!_showSearch)
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
