import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/services/office_document_service.dart';
import 'package:office_archiving/services/sqlite_service.dart';
import 'package:path/path.dart' as p;

/// محرر نصوص احترافي — تصميم Google Keep.
/// وضع الإنشاء  → [sectionId] + [itemCubit] + [fileType]
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
  final String fileType;

  bool get isEditing => existingPath != null;

  @override
  State<RichTextEditorPage> createState() => _RichTextEditorPageState();
}

class _RichTextEditorPageState extends State<RichTextEditorPage> {
  late final QuillController _ctrl;
  final _titleCtrl = TextEditingController();
  final _editorFocus = FocusNode();
  bool _saving = false;
  bool _loading = false;

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  bool get _isDocx =>
      widget.fileType == 'docx' ||
      (widget.existingPath?.endsWith('.docx') ?? false);

  String get _deltaPath =>
      widget.existingPath == null ? '' : '${widget.existingPath}.delta.json';

  // ───── lifecycle ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _ctrl = QuillController.basic();
    if (widget.isEditing) {
      _titleCtrl.text = p.basenameWithoutExtension(widget.existingPath!);
      _loadExisting();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _titleCtrl.dispose();
    _editorFocus.dispose();
    super.dispose();
  }

  // ───── load ──────────────────────────────────────────────────────────────

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final deltaFile = File(_deltaPath);
      if (await deltaFile.exists()) {
        final json = jsonDecode(await deltaFile.readAsString()) as List;
        _ctrl.document = Document.fromJson(json);
      } else if (_isDocx) {
        final paras = await OfficeDocumentService.instance
            .readDocxParagraphs(widget.existingPath!);
        if (paras.isNotEmpty) {
          final delta = Delta();
          for (final para in paras) {
            delta.insert('$para\n');
          }
          _ctrl.document = Document.fromDelta(delta);
        }
      } else {
        final text = await File(widget.existingPath!).readAsString();
        if (text.isNotEmpty) {
          _ctrl.document = Document.fromDelta(Delta()..insert('$text\n'));
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ───── save ──────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty && !widget.isEditing) {
      _snack(_ar ? 'أدخل اسم الملف' : 'Enter a file name');
      return;
    }
    setState(() => _saving = true);
    try {
      final effectiveTitle = title.isEmpty
          ? p.basenameWithoutExtension(widget.existingPath!)
          : title;
      final plainText = _ctrl.document.toPlainText().trim();
      final deltaJson = jsonEncode(_ctrl.document.toDelta().toJson());

      File file;
      if (_isDocx) {
        final paragraphs =
            plainText.split('\n').where((l) => l.trim().isNotEmpty).toList();
        file = await OfficeDocumentService.instance.createWordFile(
          title: effectiveTitle,
          paragraphs: paragraphs,
          existingPath: widget.existingPath,
        );
      } else {
        file = await OfficeDocumentService.instance.createOrUpdateTextFile(
          title: effectiveTitle,
          body: plainText,
          existingPath: widget.existingPath,
        );
      }

      // حفظ Delta للاحتفاظ بالتنسيق
      await File('${file.path}.delta.json')
          .writeAsString(deltaJson, flush: true);

      if (!widget.isEditing) {
        final ext = _isDocx ? 'docx' : 'txt';
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
          ? (widget.isEditing ? 'تم الحفظ ✓' : 'تم الإنشاء ✓')
          : (widget.isEditing ? 'Saved ✓' : 'Created ✓'));
      Navigator.pop(context, true);
    } catch (e) {
      _snack('${_ar ? 'خطأ' : 'Error'}: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ───── color pickers ─────────────────────────────────────────────────────

  static const _textColors = [
    Color(0xFF000000), // أسود (افتراضي)
    Color(0xFF212121),
    Color(0xFFE53935), // أحمر
    Color(0xFFE91E63), // وردي
    Color(0xFF8E24AA), // بنفسجي
    Color(0xFF1E88E5), // أزرق
    Color(0xFF00897B), // تيل
    Color(0xFF43A047), // أخضر
    Color(0xFFF4511E), // برتقالي
    Color(0xFF8D6E63), // بني
  ];

  static const _highlightColors = [
    null,               // بلا لون
    Color(0xFFFFFF8D), // أصفر
    Color(0xFFCCFF90), // أخضر فاتح
    Color(0xFF80D8FF), // أزرق فاتح
    Color(0xFFFF80AB), // وردي فاتح
    Color(0xFFFFD180), // برتقالي فاتح
    Color(0xFFEA80FC), // بنفسجي فاتح
    Color(0xFFCFD8DC), // رمادي
  ];

  String _toHex(Color c) =>
      '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  void _showColorSheet({required bool isBackground}) {
    final colors = isBackground ? _highlightColors : _textColors.cast<Color?>();
    final label = isBackground
        ? (_ar ? 'لون التظليل' : 'Highlight color')
        : (_ar ? 'لون الخط' : 'Text color');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: colors.map((c) {
                if (c == null) {
                  return GestureDetector(
                    onTap: () {
                      _ctrl.formatSelection(BackgroundAttribute(null));
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26),
                      ),
                      child: const Icon(Icons.block,
                          size: 20, color: Colors.black38),
                    ),
                  );
                }
                return GestureDetector(
                  onTap: () {
                    if (isBackground) {
                      _ctrl.formatSelection(BackgroundAttribute(_toHex(c)));
                    } else {
                      _ctrl.formatSelection(ColorAttribute(_toHex(c)));
                    }
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: c == Colors.white || c.toARGB32() > 0xFFEEEEEE
                          ? Border.all(color: Colors.black26)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: c.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ───── format helpers ─────────────────────────────────────────────────────

  bool _isActive(Attribute attr) {
    final attrs = _ctrl.getSelectionStyle().attributes;
    final v = attrs[attr.key];
    if (v == null) return false;
    if (attr.key == Attribute.header.key) return false; // handled separately
    return true;
  }

  int? _headerLevel() {
    final v = _ctrl.getSelectionStyle().attributes[Attribute.header.key];
    if (v == null) return null;
    return v.value as int?;
  }

  void _toggleAttr(Attribute attr) {
    if (_isActive(attr)) {
      _ctrl.formatSelection(Attribute.clone(attr, null));
    } else {
      _ctrl.formatSelection(attr);
    }
  }

  void _cycleHeader() {
    final level = _headerLevel();
    if (level == null) {
      _ctrl.formatSelection(Attribute.h1);
    } else if (level == 1) {
      _ctrl.formatSelection(Attribute.h2);
    } else if (level == 2) {
      _ctrl.formatSelection(Attribute.h3);
    } else {
      _ctrl.formatSelection(Attribute.clone(Attribute.header, null));
    }
  }

  String _headerLabel() {
    final lvl = _headerLevel();
    if (lvl == null) return 'T';
    return 'H$lvl';
  }

  // ───── build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        appBar: _buildAppBar(),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildTitleField(),
                  if (_isDocx && widget.isEditing) _buildDocxWarning(),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                  Expanded(child: _buildEditor()),
                ],
              ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Color(0xFF424242)),
      titleSpacing: 0,
      title: ListenableBuilder(
        listenable: _ctrl,
        builder: (_, __) {
          final text = _ctrl.document.toPlainText().trim();
          final words = text.isEmpty
              ? 0
              : text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
          return Text(
            '$words ${_ar ? 'كلمة' : 'words'}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF9E9E9E),
              fontWeight: FontWeight.normal,
            ),
          );
        },
      ),
      actions: [
        if (_isDocx)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Chip(
              label: const Text('DOCX',
                  style: TextStyle(fontSize: 11, color: Color(0xFF1565C0))),
              backgroundColor: const Color(0xFFE3F2FD),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _saving
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.check_circle_outline,
                      color: Color(0xFF1976D2), size: 26),
                  tooltip: _ar ? 'حفظ' : 'Save',
                  onPressed: _save,
                ),
        ),
      ],
    );
  }

  // ─── Title field ─────────────────────────────────────────────────────────

  Widget _buildTitleField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: TextField(
        controller: _titleCtrl,
        readOnly: widget.isEditing,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.black,
          letterSpacing: 0.1,
        ),
        decoration: InputDecoration(
          hintText: _ar ? 'العنوان' : 'Title',
          border: InputBorder.none,
          isDense: true,
          hintStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFFBDBDBD),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => _editorFocus.requestFocus(),
      ),
    );
  }

  // ─── DOCX warning ────────────────────────────────────────────────────────

  Widget _buildDocxWarning() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFFDE7),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 14, color: Color(0xFFF9A825)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _ar
                  ? 'التنسيق محفوظ داخل التطبيق — قد يختلف في Word'
                  : 'Formatting preserved in-app — may differ in Word',
              style: const TextStyle(fontSize: 11, color: Color(0xFFF9A825)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Editor ──────────────────────────────────────────────────────────────

  Widget _buildEditor() {
    return Container(
      color: Colors.white,
      child: QuillEditor.basic(
        controller: _ctrl,
        focusNode: _editorFocus,
        config: QuillEditorConfig(
          placeholder: _ar ? 'ابدأ الكتابة...' : 'Start writing...',
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
          scrollable: true,
          autoFocus: !widget.isEditing,
          customStyles: _editorStyles(),
        ),
      ),
    );
  }

  DefaultStyles _editorStyles() {
    const h = HorizontalSpacing(0, 0);
    const v0 = VerticalSpacing(0, 0);
    return DefaultStyles(
      paragraph: DefaultTextBlockStyle(
        const TextStyle(
          color: Colors.black,
          fontSize: 15,
          height: 1.65,
          letterSpacing: 0.1,
        ),
        h, v0, v0, null,
      ),
      h1: DefaultTextBlockStyle(
        const TextStyle(
          color: Colors.black,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),
        h, const VerticalSpacing(14, 4), v0, null,
      ),
      h2: DefaultTextBlockStyle(
        const TextStyle(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
        h, const VerticalSpacing(12, 4), v0, null,
      ),
      h3: DefaultTextBlockStyle(
        const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        h, const VerticalSpacing(10, 4), v0, null,
      ),
      placeHolder: DefaultTextBlockStyle(
        const TextStyle(color: Color(0xFFBDBDBD), fontSize: 15, height: 1.65),
        h, v0, v0, null,
      ),
    );
  }

  // ─── Bottom bar ──────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        height: 52,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ListenableBuilder(
          listenable: _ctrl,
          builder: (_, __) => _toolbar(),
        ),
      ),
    );
  }

  Widget _toolbar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          // تراجع / إعادة
          _tb(Icons.undo_rounded, () => _ctrl.undo()),
          _tb(Icons.redo_rounded, () => _ctrl.redo()),
          _sep(),

          // تنسيق النص
          _fmt(Icons.format_bold_rounded, Attribute.bold),
          _fmt(Icons.format_italic_rounded, Attribute.italic),
          _fmt(Icons.format_underline_rounded, Attribute.underline),
          _fmt(Icons.format_strikethrough_rounded, Attribute.strikeThrough),
          _sep(),

          // عناوين
          _headerTb(),
          _sep(),

          // قوائم
          _blockFmt(Icons.format_list_bulleted_rounded, Attribute.ul),
          _blockFmt(Icons.format_list_numbered_rounded, Attribute.ol),
          _blockFmt(Icons.check_box_outlined, Attribute.checked),
          _sep(),

          // محاذاة
          _blockFmt(Icons.format_align_right_rounded, Attribute.rightAlignment),
          _blockFmt(Icons.format_align_center_rounded, Attribute.centerAlignment),
          _blockFmt(Icons.format_align_left_rounded, Attribute.leftAlignment),
          _sep(),

          // ألوان
          _colorTb(isBackground: false),
          _colorTb(isBackground: true),
          _sep(),

          // اقتباس + مسح
          _blockFmt(Icons.format_quote_rounded, Attribute.blockQuote),
          _tb(Icons.format_clear_rounded, () {
            _ctrl.formatSelection(Attribute.clone(Attribute.bold, null));
            _ctrl.formatSelection(Attribute.clone(Attribute.italic, null));
            _ctrl.formatSelection(Attribute.clone(Attribute.underline, null));
            _ctrl.formatSelection(Attribute.clone(Attribute.strikeThrough, null));
            _ctrl.formatSelection(ColorAttribute(null));
            _ctrl.formatSelection(BackgroundAttribute(null));
          }),
        ],
      ),
    );
  }

  // ─── toolbar helpers ─────────────────────────────────────────────────────

  Widget _sep() => Container(
        width: 1,
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: const Color(0xFFE0E0E0),
      );

  Widget _tb(IconData icon, VoidCallback onTap, {bool active = false}) {
    return Material(
      color: active ? const Color(0xFFE3F2FD) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon,
              size: 20,
              color: active ? const Color(0xFF1976D2) : const Color(0xFF616161)),
        ),
      ),
    );
  }

  Widget _fmt(IconData icon, Attribute attr) {
    final active = _isActive(attr);
    return _tb(icon, () => _toggleAttr(attr), active: active);
  }

  Widget _blockFmt(IconData icon, Attribute attr) {
    final active =
        _ctrl.getSelectionStyle().attributes.containsKey(attr.key);
    return _tb(icon, () {
      if (active) {
        _ctrl.formatSelection(Attribute.clone(attr, null));
      } else {
        _ctrl.formatSelection(attr);
      }
    }, active: active);
  }

  Widget _headerTb() {
    final level = _headerLevel();
    final active = level != null;
    return Material(
      color: active ? const Color(0xFFE3F2FD) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _cycleHeader,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Text(
              _headerLabel(),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: active
                    ? const Color(0xFF1976D2)
                    : const Color(0xFF616161),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _colorTb({required bool isBackground}) {
    // استخراج اللون الحالي من نمط التحديد
    final attrs = _ctrl.getSelectionStyle().attributes;
    Color? current;
    if (!isBackground) {
      final hex = attrs[Attribute.color.key]?.value as String?;
      if (hex != null && hex.startsWith('#')) {
        current = Color(int.parse('FF${hex.substring(1).toUpperCase()}', radix: 16));
      }
    } else {
      final hex = attrs[Attribute.background.key]?.value as String?;
      if (hex != null && hex.startsWith('#')) {
        current = Color(int.parse('FF${hex.substring(1).toUpperCase()}', radix: 16));
      }
    }

    return GestureDetector(
      onTap: () => _showColorSheet(isBackground: isBackground),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: isBackground
            ? Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.brush_rounded,
                      size: 20, color: const Color(0xFF616161)),
                  Positioned(
                    bottom: 6,
                    child: Container(
                      width: 16,
                      height: 4,
                      decoration: BoxDecoration(
                        color: current ?? Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                        border: current == null
                            ? Border.all(color: Colors.black26)
                            : null,
                      ),
                    ),
                  ),
                ],
              )
            : Stack(
                alignment: Alignment.center,
                children: [
                  const Text('A',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Color(0xFF424242))),
                  Positioned(
                    bottom: 5,
                    child: Container(
                      width: 16,
                      height: 4,
                      decoration: BoxDecoration(
                        color: current ?? Colors.black,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
