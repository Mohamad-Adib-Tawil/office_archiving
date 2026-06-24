import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:office_archiving/helper/pdf_viewer.dart';
import 'package:office_archiving/l10n/app_localizations.dart';
import 'package:office_archiving/services/ocr_service.dart';
import 'package:office_archiving/services/pdf_page_editing_service.dart';
import 'package:office_archiving/widgets/first_open_animator.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

class PdfEditorPage extends StatefulWidget {
  const PdfEditorPage({super.key, required this.pdfPath});

  final String pdfPath;

  @override
  State<PdfEditorPage> createState() => _PdfEditorPageState();
}

class _PdfEditorPageState extends State<PdfEditorPage> {
  final PdfPageEditingService _editingService = PdfPageEditingService.instance;
  final OCRService _ocrService = OCRService();

  PdfEditingSession? _session;
  bool _isLoading = true;
  bool _isBusy = false;
  bool _hasUnsavedChanges = false;
  int _selectedIndex = 0;
  String? _errorMessage;
  String? _lastSavedPdfPath;

  List<PdfEditablePage> get _pages =>
      _session?.pages ?? const <PdfEditablePage>[];

  PdfEditablePage? get _selectedPage {
    if (_pages.isEmpty) {
      return null;
    }
    final safeIndex = _selectedIndex.clamp(0, _pages.length - 1);
    return _pages[safeIndex];
  }

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void dispose() {
    _editingService.cleanupSession(_session?.workingDirectory);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          p.basename(widget.pdfPath),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: _isBusy ? null : _openOriginalPdf,
            icon: const Icon(Icons.visibility_outlined),
            tooltip: _text(
              ar: 'معاينة الملف الأصلي',
              en: 'Preview original PDF',
            ),
          ),
          IconButton(
            onPressed: _isBusy ? null : _sharePdf,
            icon: const Icon(Icons.share),
            tooltip: localizations.share_action,
          ),
          IconButton(
            onPressed: _isBusy ? null : _savePdf,
            icon: _isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
            tooltip: localizations.editor_save,
          ),
          PopupMenuButton<_PdfEditorAction>(
            onSelected: _handleEditorAction,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _PdfEditorAction.managePages,
                child: Text(_text(ar: 'إدارة الصفحات', en: 'Manage pages')),
              ),
              PopupMenuItem(
                value: _PdfEditorAction.extractCurrentPagePdf,
                child: Text(
                  _text(
                    ar: 'استخراج الصفحة الحالية كـ PDF',
                    en: 'Extract current page as PDF',
                  ),
                ),
              ),
              PopupMenuItem(
                value: _PdfEditorAction.exportCurrentPageImage,
                child: Text(
                  _text(
                    ar: 'تصدير الصفحة الحالية كصورة',
                    en: 'Export current page as image',
                  ),
                ),
              ),
              PopupMenuItem(
                value: _PdfEditorAction.discardChanges,
                child: Text(
                  _text(
                    ar: 'إعادة التحميل وإلغاء التعديلات',
                    en: 'Reload and discard changes',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: FirstOpenAnimator(pageKey: 'pdf_editor_page', child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadSession,
                icon: const Icon(Icons.refresh),
                label: Text(_text(ar: 'إعادة المحاولة', en: 'Try again')),
              ),
            ],
          ),
        ),
      );
    }

    final page = _selectedPage;
    if (page == null) {
      return Center(
        child: Text(
          _text(
            ar: 'لا توجد صفحات متاحة في هذا الملف.',
            en: 'No pages are available in this PDF.',
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(),
          const SizedBox(height: 12),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(page.imagePath),
                          key: ValueKey('${page.id}_${page.revision}'),
                          fit: BoxFit.contain,
                          errorBuilder: (_, error, __) => Center(
                            child: Text(
                              _text(
                                ar: 'تعذر تحميل الصفحة الحالية.',
                                en: 'Failed to load the selected page.',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    top: 16,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          _text(
                            ar: 'الصفحة ${_selectedIndex + 1} من ${_pages.length}',
                            en: 'Page ${_selectedIndex + 1} of ${_pages.length}',
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  if (_hasUnsavedChanges)
                    Positioned(
                      left: 16,
                      top: 16,
                      child: Chip(
                        avatar: const Icon(Icons.edit_note, size: 18),
                        label: Text(
                          _text(
                            ar: 'تعديلات غير محفوظة',
                            en: 'Unsaved changes',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildActionBar(),
          const SizedBox(height: 12),
          _buildThumbnails(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.auto_awesome_motion),
        title: Text(
          _text(ar: 'تحرير صفحات PDF بشكل فعلي', en: 'Real PDF page editing'),
        ),
        subtitle: Text(
          _text(
            ar: 'يمكنك إعادة ترتيب الصفحات، تدويرها، حذفها، واستخراج صفحة مستقلة ثم حفظ نسخة PDF جديدة دون المساس بالأصل.',
            en: 'Reorder, rotate, delete, and extract pages, then save a new PDF copy without touching the original.',
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    final localizations = AppLocalizations.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilledButton.tonalIcon(
            onPressed: _isBusy
                ? null
                : () => _rotateSelectedPage(clockwise: false),
            icon: const Icon(Icons.rotate_left),
            label: Text(localizations.editor_rotate_left),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: _isBusy
                ? null
                : () => _rotateSelectedPage(clockwise: true),
            icon: const Icon(Icons.rotate_right),
            label: Text(localizations.editor_rotate_right),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: _isBusy ? null : _extractTextFromCurrentPage,
            icon: const Icon(Icons.text_snippet_outlined),
            label: Text(_text(ar: 'استخراج النص', en: 'Extract text')),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: _isBusy ? null : _openPageManager,
            icon: const Icon(Icons.reorder),
            label: Text(_text(ar: 'ترتيب الصفحات', en: 'Reorder pages')),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _isBusy ? null : _deleteSelectedPage,
            icon: const Icon(Icons.delete_outline),
            label: Text(_text(ar: 'حذف الصفحة', en: 'Delete page')),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnails() {
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _pages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final page = _pages[index];
          final isSelected = index == _selectedIndex;

          return InkWell(
            onTap: () => setState(() => _selectedIndex = index),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 86,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(page.imagePath),
                        key: ValueKey('thumb_${page.id}_${page.revision}'),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _text(ar: 'صفحة ${index + 1}', en: 'Page ${index + 1}'),
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadSession() async {
    final previousDirectory = _session?.workingDirectory;

    setState(() {
      _isLoading = true;
      _isBusy = false;
      _errorMessage = null;
      _selectedIndex = 0;
      _hasUnsavedChanges = false;
      _lastSavedPdfPath = null;
      _session = null;
    });

    try {
      final session = await _editingService.openSession(widget.pdfPath);
      if (!mounted) {
        await _editingService.cleanupSession(session.workingDirectory);
        return;
      }

      setState(() {
        _session = session;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _text(
          ar: 'فشل فتح ملف PDF للتحرير: $error',
          en: 'Failed to open PDF for editing: $error',
        );
      });
    } finally {
      if (previousDirectory != null) {
        _editingService.cleanupSession(previousDirectory);
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _rotateSelectedPage({required bool clockwise}) async {
    final page = _selectedPage;
    if (page == null) {
      return;
    }

    final success = await _runBusyAction<bool>(
      action: () async {
        await _editingService.rotatePage(page, clockwise: clockwise);
        return true;
      },
      errorPrefix: _text(
        ar: 'فشل تدوير الصفحة: ',
        en: 'Failed to rotate page: ',
      ),
    );

    if (success != true || !mounted) {
      return;
    }

    setState(() {
      _pages[_selectedIndex] = page.copyWith(revision: page.revision + 1);
      _hasUnsavedChanges = true;
    });

    _showSnackBar(
      _text(ar: 'تم تدوير الصفحة بنجاح.', en: 'Page rotated successfully.'),
    );
  }

  Future<void> _extractTextFromCurrentPage() async {
    final page = _selectedPage;
    if (page == null) {
      return;
    }

    final extractedText = await _runBusyAction<String>(
      action: () => _ocrService.extractTextFromImage(page.imagePath),
      errorPrefix: _text(
        ar: 'فشل استخراج النص: ',
        en: 'Failed to extract text: ',
      ),
    );

    if (extractedText == null || !mounted) {
      return;
    }

    _showExtractedTextSheet(extractedText.trim());
  }

  Future<void> _savePdf({
    bool shareAfterSave = false,
    bool showResultDialog = true,
  }) async {
    if (_pages.isEmpty) {
      return;
    }

    final savedFile = await _runBusyAction<File>(
      action: () => _editingService.saveEditedPdf(
        pages: _pages,
        baseName: p.basenameWithoutExtension(widget.pdfPath),
      ),
      errorPrefix: _text(ar: 'فشل حفظ ملف PDF: ', en: 'Failed to save PDF: '),
    );

    if (savedFile == null || !mounted) {
      return;
    }

    setState(() {
      _lastSavedPdfPath = savedFile.path;
      _hasUnsavedChanges = false;
    });

    if (shareAfterSave) {
      await Share.shareXFiles([
        XFile(savedFile.path),
      ], text: p.basename(savedFile.path));
      return;
    }

    if (!showResultDialog) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          _text(ar: 'تم حفظ النسخة المعدلة', en: 'Edited copy saved'),
        ),
        content: Text(savedFile.path),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_text(ar: 'إغلاق', en: 'Close')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyPdfViewer(filePath: savedFile.path),
                ),
              );
            },
            child: Text(_text(ar: 'فتح', en: 'Open')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Share.shareXFiles([
                XFile(savedFile.path),
              ], text: p.basename(savedFile.path));
            },
            child: Text(_text(ar: 'مشاركة', en: 'Share')),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePdf() async {
    final pathToShare = await _resolvePathForShare();
    if (pathToShare == null) {
      return;
    }

    try {
      await Share.shareXFiles([
        XFile(pathToShare),
      ], text: p.basename(pathToShare));
    } catch (error) {
      _showSnackBar(
        '${_text(ar: 'فشل مشاركة الملف: ', en: 'Failed to share file: ')}$error',
        isError: true,
      );
    }
  }

  Future<String?> _resolvePathForShare() async {
    if (_hasUnsavedChanges) {
      await _savePdf(showResultDialog: false);
      return _lastSavedPdfPath;
    }

    return _lastSavedPdfPath ?? widget.pdfPath;
  }

  Future<void> _openPageManager() async {
    if (_pages.isEmpty) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.9,
            child: StatefulBuilder(
              builder: (_, setSheetState) {
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.reorder),
                      title: Text(
                        _text(
                          ar: 'إدارة وترتيب الصفحات',
                          en: 'Manage and reorder pages',
                        ),
                      ),
                      subtitle: Text(
                        _text(
                          ar: 'اسحب الصفحة إلى موقعها الجديد أو احذفها من هنا.',
                          en: 'Drag a page to a new position or delete it from here.',
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _pages.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final page = _pages.removeAt(oldIndex);
                            _pages.insert(newIndex, page);
                            _selectedIndex = newIndex;
                            _hasUnsavedChanges = true;
                          });
                          setSheetState(() {});
                        },
                        itemBuilder: (context, index) {
                          final page = _pages[index];
                          final isSelected = index == _selectedIndex;
                          return Card(
                            key: ValueKey(page.id),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              onTap: () {
                                setState(() => _selectedIndex = index);
                                Navigator.pop(sheetContext);
                              },
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(page.imagePath),
                                  key: ValueKey(
                                    'manager_${page.id}_${page.revision}',
                                  ),
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(
                                _text(
                                  ar: 'الصفحة ${index + 1}',
                                  en: 'Page ${index + 1}',
                                ),
                              ),
                              subtitle: Text(
                                isSelected
                                    ? _text(
                                        ar: 'هذه الصفحة معروضة الآن.',
                                        en: 'This page is currently selected.',
                                      )
                                    : _text(
                                        ar: 'اضغط لمعاينتها.',
                                        en: 'Tap to preview it.',
                                      ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: _pages.length > 1
                                        ? () {
                                            setState(() {
                                              _pages.removeAt(index);
                                              if (_selectedIndex >=
                                                  _pages.length) {
                                                _selectedIndex =
                                                    _pages.length - 1;
                                              } else if (index <
                                                  _selectedIndex) {
                                                _selectedIndex -= 1;
                                              }
                                              _hasUnsavedChanges = true;
                                            });
                                            setSheetState(() {});
                                          }
                                        : null,
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: _text(ar: 'حذف', en: 'Delete'),
                                  ),
                                  const Icon(Icons.drag_handle),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteSelectedPage() async {
    if (_pages.length <= 1) {
      _showSnackBar(
        _text(
          ar: 'يجب الإبقاء على صفحة واحدة على الأقل.',
          en: 'At least one page must remain.',
        ),
        isError: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_text(ar: 'حذف الصفحة الحالية', en: 'Delete current page')),
        content: Text(
          _text(
            ar: 'سيتم حذف الصفحة من النسخة المعدلة فقط، ولن يتغير الملف الأصلي.',
            en: 'The page will be removed from the edited copy only. The original PDF will not change.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_text(ar: 'إلغاء', en: 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_text(ar: 'حذف', en: 'Delete')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final removedPage = _pages[_selectedIndex];
    final removedIndex = _selectedIndex;

    setState(() {
      _pages.removeAt(removedIndex);
      if (_selectedIndex >= _pages.length) {
        _selectedIndex = _pages.length - 1;
      }
      _hasUnsavedChanges = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _text(
            ar: 'تم حذف الصفحة من النسخة المعدلة.',
            en: 'Page removed from the edited copy.',
          ),
        ),
        action: SnackBarAction(
          label: _text(ar: 'تراجع', en: 'Undo'),
          onPressed: () {
            if (!mounted) {
              return;
            }
            setState(() {
              _pages.insert(removedIndex, removedPage);
              _selectedIndex = removedIndex;
              _hasUnsavedChanges = true;
            });
          },
        ),
      ),
    );
  }

  Future<void> _exportCurrentPageAsImage() async {
    final page = _selectedPage;
    if (page == null) {
      return;
    }

    final exportedFile = await _runBusyAction<File>(
      action: () => _editingService.exportPageAsImage(
        page: page,
        baseName: p.basenameWithoutExtension(widget.pdfPath),
        pageNumber: _selectedIndex + 1,
      ),
      errorPrefix: _text(
        ar: 'فشل تصدير الصفحة كصورة: ',
        en: 'Failed to export page as image: ',
      ),
    );

    if (exportedFile == null) {
      return;
    }

    _showSnackBar(
      _text(
        ar: 'تم تصدير الصفحة كصورة: ${p.basename(exportedFile.path)}',
        en: 'Page exported as image: ${p.basename(exportedFile.path)}',
      ),
    );
  }

  Future<void> _extractCurrentPageAsPdf() async {
    final page = _selectedPage;
    if (page == null) {
      return;
    }

    final exportedFile = await _runBusyAction<File>(
      action: () => _editingService.exportPageAsPdf(
        page: page,
        baseName: p.basenameWithoutExtension(widget.pdfPath),
        pageNumber: _selectedIndex + 1,
      ),
      errorPrefix: _text(
        ar: 'فشل استخراج الصفحة كملف PDF: ',
        en: 'Failed to extract page as PDF: ',
      ),
    );

    if (exportedFile == null) {
      return;
    }

    _showSnackBar(
      _text(
        ar: 'تم استخراج الصفحة كملف PDF مستقل.',
        en: 'Page extracted as a standalone PDF.',
      ),
    );
  }

  Future<void> _discardChanges() async {
    if (!_hasUnsavedChanges) {
      await _loadSession();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          _text(ar: 'إلغاء التعديلات الحالية', en: 'Discard current changes'),
        ),
        content: Text(
          _text(
            ar: 'سيتم إعادة تحميل الصفحات من الملف الأصلي وفقدان أي تعديل غير محفوظ.',
            en: 'Pages will be reloaded from the original PDF and any unsaved change will be lost.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_text(ar: 'إلغاء', en: 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_text(ar: 'متابعة', en: 'Continue')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _loadSession();
    }
  }

  Future<void> _openOriginalPdf() async {
    if (!mounted) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MyPdfViewer(filePath: widget.pdfPath)),
    );
  }

  Future<T?> _runBusyAction<T>({
    required Future<T> Function() action,
    required String errorPrefix,
  }) async {
    if (_isBusy) {
      return null;
    }

    setState(() => _isBusy = true);

    try {
      return await action();
    } catch (error) {
      _showSnackBar('$errorPrefix$error', isError: true);
      return null;
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  void _showExtractedTextSheet(String text) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.82,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.text_snippet_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _text(
                          ar: 'النص المستخرج من الصفحة الحالية',
                          en: 'Extracted text from current page',
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        text.isEmpty
                            ? _text(
                                ar: 'لم يتم العثور على نص واضح في هذه الصفحة.',
                                en: 'No readable text was found on this page.',
                              )
                            : text,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: text));
                          if (!mounted || !sheetContext.mounted) {
                            return;
                          }
                          Navigator.pop(sheetContext);
                          _showSnackBar(
                            _text(ar: 'تم نسخ النص.', en: 'Text copied.'),
                          );
                        },
                        icon: const Icon(Icons.copy_outlined),
                        label: Text(_text(ar: 'نسخ', en: 'Copy')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.check),
                        label: Text(_text(ar: 'إغلاق', en: 'Close')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleEditorAction(_PdfEditorAction action) {
    switch (action) {
      case _PdfEditorAction.managePages:
        _openPageManager();
        break;
      case _PdfEditorAction.extractCurrentPagePdf:
        _extractCurrentPageAsPdf();
        break;
      case _PdfEditorAction.exportCurrentPageImage:
        _exportCurrentPageAsImage();
        break;
      case _PdfEditorAction.discardChanges:
        _discardChanges();
        break;
    }
  }

  String _text({required String ar, required String en}) {
    return Localizations.localeOf(context).languageCode == 'ar' ? ar : en;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }
}

enum _PdfEditorAction {
  managePages,
  extractCurrentPagePdf,
  exportCurrentPageImage,
  discardChanges,
}
