import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/services/office_document_service.dart';
import 'package:office_archiving/services/sqlite_service.dart';
import 'package:path/path.dart' as p;

/// محرّر نصوص احترافي كامل (flutter_quill):
/// خطوط، ألوان، عناوين، تعداد، محاذاة، بحث، تراجع/إعادة.
///
/// وضع الإنشاء  → [sectionId] + [itemCubit] + [fileType] ('txt' أو 'docx')
/// وضع التعديل → [existingPath]
class RichTextEditorPage extends StatefulWidget {
  const RichTextEditorPage({
    super.key,
    this.sectionId,
    this.itemCubit,
    this.existingPath,
    this.fileType = 'txt',
  });

  final int? sectionId;
  final ItemSectionCubit? itemCubit;
  final String? existingPath;
  final String fileType; // 'txt' أو 'docx'

  bool get isEditing => existingPath != null;

  @override
  State<RichTextEditorPage> createState() => _RichTextEditorPageState();
}

class _RichTextEditorPageState extends State<RichTextEditorPage> {
  late final QuillController _controller;
  final _titleController = TextEditingController();
  bool _saving = false;
  bool _loading = false;

  // مفتاح لحفظ Delta بجانب الملف الأصلي
  String get _deltaPath =>
      widget.existingPath == null
          ? ''
          : '${widget.existingPath}.delta.json';

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic();
    if (widget.isEditing) {
      _titleController.text =
          p.basenameWithoutExtension(widget.existingPath!);
      _loadExisting();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      // أولوية: ملف Delta المحفوظ (يحتفظ بالتنسيق الكامل)
      final deltaFile = File(_deltaPath);
      if (await deltaFile.exists()) {
        final json = jsonDecode(await deltaFile.readAsString()) as List;
        _controller.document = Document.fromJson(json);
      } else if (widget.existingPath!.endsWith('.docx')) {
        // fallback: نص فقط من DOCX
        final paras = await OfficeDocumentService.instance
            .readDocxParagraphs(widget.existingPath!);
        if (paras.isNotEmpty) {
          final delta = Delta();
          for (final para in paras) {
            delta.insert('$para\n');
          }
          _controller.document = Document.fromDelta(delta);
        }
      } else {
        // TXT
        final text = await File(widget.existingPath!).readAsString();
        if (text.isNotEmpty) {
          final delta = Delta()..insert('$text\n');
          _controller.document = Document.fromDelta(delta);
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty && !widget.isEditing) {
      _snack(_ar ? 'أدخل اسم الملف' : 'Enter a file name');
      return;
    }
    setState(() => _saving = true);
    try {
      final effectiveTitle =
          title.isEmpty ? p.basenameWithoutExtension(widget.existingPath!) : title;
      final plainText = _controller.document.toPlainText().trim();
      final deltaJson = jsonEncode(_controller.document.toDelta().toJson());

      File file;
      if (widget.fileType == 'docx' || (widget.existingPath?.endsWith('.docx') ?? false)) {
        // حفظ كـ DOCX
        final paragraphs = plainText
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .toList();
        file = await OfficeDocumentService.instance.createWordFile(
          title: effectiveTitle,
          paragraphs: paragraphs,
          existingPath: widget.existingPath,
        );
      } else {
        // حفظ كـ TXT
        file = await OfficeDocumentService.instance.createOrUpdateTextFile(
          title: effectiveTitle,
          body: plainText,
          existingPath: widget.existingPath,
        );
      }

      // حفظ Delta بجانب الملف للاحتفاظ بالتنسيق عند إعادة التحرير
      final deltaFile = File('${file.path}.delta.json');
      await deltaFile.writeAsString(deltaJson, flush: true);

      if (!widget.isEditing) {
        final ext = widget.fileType == 'docx' ? 'docx' : 'txt';
        await DatabaseService.instance.insertItem(
          p.basenameWithoutExtension(file.path),
          file.path,
          ext,
          widget.sectionId!,
        );
        await widget.itemCubit?.refreshItems(widget.sectionId!);
      }
      if (!mounted) return;
      _snack(_ar
          ? (widget.isEditing ? 'تم الحفظ' : 'تم إنشاء الملف')
          : (widget.isEditing ? 'Saved' : 'File created'));
      Navigator.pop(context, true);
    } catch (e) {
      _snack('${_ar ? 'خطأ' : 'Error'}: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ===== شريط أدوات عداد الكلمات =====
  String get _wordCount {
    final text = _controller.document.toPlainText().trim();
    if (text.isEmpty) return '0';
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDocx = widget.fileType == 'docx' ||
        (widget.existingPath?.endsWith('.docx') ?? false);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: widget.isEditing
              ? Text(
                  _titleController.text,
                  overflow: TextOverflow.ellipsis,
                )
              : TextField(
                  controller: _titleController,
                  style: theme.textTheme.titleMedium,
                  decoration: InputDecoration(
                    hintText: _ar ? 'اسم الملف...' : 'File name...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
          actions: [
            // عداد الكلمات
            ListenableBuilder(
              listenable: _controller,
              builder: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Center(
                  child: Text(
                    '$_wordCount ${_ar ? 'كلمة' : 'words'}',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
            // حفظ
            IconButton(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              tooltip: _ar ? 'حفظ' : 'Save',
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // تنبيه DOCX
                  if (isDocx && widget.isEditing)
                    _InfoBanner(
                      message: _ar
                          ? 'ملاحظة: التنسيق يُحفظ داخل التطبيق. عند فتح الملف في Word قد يختلف الشكل.'
                          : 'Note: Formatting is preserved in-app. External Word may render differently.',
                    ),

                  // شريط الأدوات
                  SizedBox(
                    height: 48,
                    child: _buildToolbar(theme),
                  ),

                  const Divider(height: 1),

                  // منطقة التحرير
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: QuillEditor.basic(
                        controller: _controller,
                        config: QuillEditorConfig(
                          placeholder: _ar
                              ? 'ابدأ الكتابة هنا...'
                              : 'Start writing here...',
                          padding: const EdgeInsets.all(16),
                          autoFocus: !widget.isEditing,
                          expands: false,
                          scrollable: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: QuillSimpleToolbar(
          controller: _controller,
          config: QuillSimpleToolbarConfig(
            toolbarSize: 36,
            showDividers: true,
            // تنسيق أساسي
            showBoldButton: true,
            showItalicButton: true,
            showUnderLineButton: true,
            showStrikeThrough: true,
            showInlineCode: true,
            showClearFormat: true,
            // خط ولون
            showFontFamily: true,
            showFontSize: true,
            showColorButton: true,
            showBackgroundColorButton: true,
            // عناوين وفقرات
            showHeaderStyle: true,
            // قوائم وتعداد
            showListBullets: true,
            showListNumbers: true,
            showListCheck: true,
            showIndent: true,
            // محاذاة
            showAlignmentButtons: true,
            showDirection: true,
            // أدوات
            showSearchButton: true,
            showLink: true,
            showQuote: true,
            showCodeBlock: true,
            // تراجع/إعادة
            showUndo: true,
            showRedo: true,
            buttonOptions: QuillSimpleToolbarButtonOptions(
              fontSize: QuillToolbarFontSizeButtonOptions(
                items: const {
                  'XS': '10',
                  'S': '12',
                  'M': '14',
                  'L': '16',
                  'XL': '18',
                  'H4': '22',
                  'H3': '28',
                  'H2': '36',
                  'H1': '48',
                },
              ),
            ),
          ),
        ),
      );
  }
}

// ===== بانر معلومات =====
class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.amber.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 11, color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }
}
