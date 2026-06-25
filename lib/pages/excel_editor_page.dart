import 'package:flutter/material.dart';
import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/services/office_document_service.dart';
import 'package:office_archiving/services/sqlite_service.dart';
import 'package:path/path.dart' as p;

/// محرّر ملف Excel (.xlsx):
/// - وضع الإنشاء: مرّر [sectionId] + [itemCubit]
/// - وضع التعديل: مرّر [existingPath] — يُحمَّل الجدول ويُحفظ مكانه
class ExcelEditorPage extends StatefulWidget {
  const ExcelEditorPage({
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
  State<ExcelEditorPage> createState() => _ExcelEditorPageState();
}

class _ExcelEditorPageState extends State<ExcelEditorPage> {
  final _titleController = TextEditingController();
  final List<List<TextEditingController>> _grid = [];
  int _columns = 3;
  bool _saving = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _titleController.text =
          p.basenameWithoutExtension(widget.existingPath!);
      _loadExisting();
    } else {
      for (var r = 0; r < 4; r++) {
        _grid.add(List.generate(_columns, (_) => TextEditingController()));
      }
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final rows = await OfficeDocumentService.instance
          .readExcelRows(widget.existingPath!);
      if (rows.isEmpty) {
        _grid.add(List.generate(_columns, (_) => TextEditingController()));
      } else {
        _columns = rows.fold<int>(
            0, (m, r) => r.length > m ? r.length : m);
        _columns = _columns < 1 ? 3 : _columns;
        for (final row in rows) {
          final rowCtrls = <TextEditingController>[];
          for (var c = 0; c < _columns; c++) {
            rowCtrls.add(TextEditingController(
                text: c < row.length ? row[c] : ''));
          }
          _grid.add(rowCtrls);
        }
      }
    } catch (_) {
      _grid.add(List.generate(_columns, (_) => TextEditingController()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final row in _grid) {
      for (final c in row) {
        c.dispose();
      }
    }
    super.dispose();
  }

  String _t({required String ar, required String en}) =>
      Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

  void _addRow() {
    setState(() {
      _grid.add(List.generate(_columns, (_) => TextEditingController()));
    });
  }

  void _addColumn() {
    setState(() {
      _columns++;
      for (final row in _grid) {
        row.add(TextEditingController());
      }
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _snack(_t(ar: 'أدخل اسم الملف', en: 'Enter a file name'));
      return;
    }
    setState(() => _saving = true);
    try {
      final rows = _grid
          .map((row) => row.map((c) => c.text).toList())
          .where((row) => row.any((cell) => cell.trim().isNotEmpty))
          .toList();
      final file = await OfficeDocumentService.instance.createExcelFile(
        title: title,
        rows: rows,
        existingPath: widget.existingPath,
      );
      if (!widget.isEditing) {
        await DatabaseService.instance.insertItem(
          p.basenameWithoutExtension(file.path),
          file.path,
          'xlsx',
          widget.sectionId!,
        );
        await widget.itemCubit?.refreshItems(widget.sectionId!);
      }
      if (!mounted) return;
      _snack(_t(
        ar: widget.isEditing ? 'تم حفظ التعديلات' : 'تم إنشاء ملف Excel',
        en: widget.isEditing ? 'Saved' : 'Excel file created',
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
                ? _t(ar: 'تعديل ملف Excel', en: 'Edit Excel file')
                : _t(ar: 'ملف Excel جديد', en: 'New Excel file'),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _titleController,
                      readOnly: widget.isEditing,
                      decoration: InputDecoration(
                        labelText: _t(ar: 'اسم الملف', en: 'File name'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _addRow,
                            icon: const Icon(Icons.add),
                            label: Text(_t(ar: 'صف', en: 'Row')),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _addColumn,
                            icon: const Icon(Icons.add),
                            label: Text(_t(ar: 'عمود', en: 'Column')),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Column(
                            children: [
                              for (final row in _grid)
                                Row(
                                  children: [
                                    for (final cell in row)
                                      Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: SizedBox(
                                          width: 120,
                                          child: TextField(
                                            controller: cell,
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              border: OutlineInputBorder(),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 10,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
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
