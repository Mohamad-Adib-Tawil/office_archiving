import 'dart:convert';
import 'dart:io';

import 'package:docx_file_viewer/docx_file_viewer.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:office_archiving/pages/rich_text_editor_page.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

/// عارض .docx — إذا وُجد ملف Delta يعرض التنسيق الكامل (Quill)،
/// وإلا يعود إلى docx_file_viewer لقراءة الملف الأصلي.
class DocxViewerPage extends StatefulWidget {
  const DocxViewerPage({super.key, required this.filePath});
  final String filePath;

  @override
  State<DocxViewerPage> createState() => _DocxViewerPageState();
}

class _DocxViewerPageState extends State<DocxViewerPage> {
  late final Future<_Content> _future;
  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Content> _load() async {
    final deltaFile = File('${widget.filePath}.delta.json');
    if (await deltaFile.exists()) {
      try {
        final json = jsonDecode(await deltaFile.readAsString()) as List;
        final doc = Document.fromJson(json);
        return _Content.rich(doc);
      } catch (_) {}
    }
    final widgets = await DocxExtractor().renderLayout(File(widget.filePath));
    return _Content.native(widgets);
  }

  void _openEditor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RichTextEditorPage(existingPath: widget.filePath),
      ),
    ).then((changed) {
      if (changed == true) {
        setState(() {
          _future = _load(); // أعد التحميل بعد التعديل
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            p.basenameWithoutExtension(widget.filePath),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: _ar ? 'تعديل' : 'Edit',
              onPressed: _openEditor,
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: _ar ? 'مشاركة' : 'Share',
              onPressed: () => Share.shareXFiles([XFile(widget.filePath)]),
            ),
          ],
        ),
        body: FutureBuilder<_Content>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError || snap.data == null) {
              return _errorView(context);
            }
            final content = snap.data!;
            return content.isRich
                ? _RichView(document: content.document!, filePath: widget.filePath)
                : _NativeView(widgets: content.nativeWidgets!);
          },
        ),
      ),
    );
  }

  Widget _errorView(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                _ar ? 'تعذّر فتح المستند' : 'Could not open document',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
}

// ─── Rich viewer (Quill read-only) ─────────────────────────────────────────

class _RichView extends StatefulWidget {
  const _RichView({required this.document, required this.filePath});
  final Document document;
  final String filePath;

  @override
  State<_RichView> createState() => _RichViewState();
}

class _RichViewState extends State<_RichView> {
  late final QuillController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = QuillController(
      document: widget.document,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: QuillEditor.basic(
        controller: _ctrl,
        config: QuillEditorConfig(
          scrollable: true,
          autoFocus: false,
          enableInteractiveSelection: true, // يسمح بالنسخ فقط
          showCursor: false,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          customStyles: _styles(),
        ),
      ),
    );
  }

  DefaultStyles _styles() {
    const h = HorizontalSpacing(0, 0);
    const v0 = VerticalSpacing(0, 0);
    return DefaultStyles(
      paragraph: DefaultTextBlockStyle(
        const TextStyle(color: Colors.black, fontSize: 15, height: 1.65),
        h, v0, v0, null,
      ),
      h1: DefaultTextBlockStyle(
        const TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.w800, height: 1.3),
        h, const VerticalSpacing(14, 4), v0, null,
      ),
      h2: DefaultTextBlockStyle(
        const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w700, height: 1.35),
        h, const VerticalSpacing(12, 4), v0, null,
      ),
      h3: DefaultTextBlockStyle(
        const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
        h, const VerticalSpacing(10, 4), v0, null,
      ),
    );
  }
}

// ─── Native viewer (docx_file_viewer fallback) ──────────────────────────────

class _NativeView extends StatelessWidget {
  const _NativeView({required this.widgets});
  final List<Widget> widgets;

  @override
  Widget build(BuildContext context) {
    if (widgets.isEmpty) {
      return Center(
        child: Text(
          Localizations.localeOf(context).languageCode == 'ar'
              ? 'المستند فارغ'
              : 'Document is empty',
        ),
      );
    }
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        itemCount: widgets.length,
        itemBuilder: (_, i) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: i == 0
                ? const BorderRadius.vertical(top: Radius.circular(8))
                : BorderRadius.zero,
            boxShadow: i == 0
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: widgets[i],
          ),
        ),
      ),
    );
  }
}

// ─── Data class ─────────────────────────────────────────────────────────────

class _Content {
  final Document? document;
  final List<Widget>? nativeWidgets;

  const _Content.rich(this.document) : nativeWidgets = null;
  const _Content.native(this.nativeWidgets) : document = null;

  bool get isRich => document != null;
}
