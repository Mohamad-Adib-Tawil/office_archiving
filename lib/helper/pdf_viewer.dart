import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

/// عارض PDF احترافي مبني على pdfrx (PDFium):
/// تكبير سلس، تحديد نص، بحث داخل المستند، تنقّل بين الصفحات، ومشاركة.
class MyPdfViewer extends StatefulWidget {
  const MyPdfViewer({super.key, required this.filePath});

  final String filePath;

  @override
  State<MyPdfViewer> createState() => _MyPdfViewerState();
}

class _MyPdfViewerState extends State<MyPdfViewer> {
  final _controller = PdfViewerController();
  final _searchController = TextEditingController();
  PdfTextSearcher? _searcher;

  int _pageNumber = 1;
  int _pageCount = 0;
  bool _ready = false;
  bool _showSearch = false;

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  void _onSearchUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searcher?.removeListener(_onSearchUpdate);
    _searcher?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _runSearch(String text) {
    if (text.trim().isEmpty) {
      _searcher?.resetTextSearch();
    } else {
      _searcher?.startTextSearch(text, caseInsensitive: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.filePath);
    final exists = file.existsSync();

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: _ar ? 'بحث في المستند...' : 'Search in document...',
                  border: InputBorder.none,
                ),
                onSubmitted: _runSearch,
                onChanged: (v) {
                  if (v.isEmpty) _searcher?.resetTextSearch();
                },
              )
            : Text(
                p.basename(widget.filePath),
                overflow: TextOverflow.ellipsis,
              ),
        actions: [
          if (_showSearch && (_searcher?.hasMatches ?? false)) ...[
            Center(
              child: Text(
                '${(_searcher?.currentIndex ?? 0) + 1}/${_searcher?.matches.length ?? 0}',
              ),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up),
              tooltip: _ar ? 'السابق' : 'Previous',
              onPressed: () => _searcher?.goToPrevMatch(),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              tooltip: _ar ? 'التالي' : 'Next',
              onPressed: () => _searcher?.goToNextMatch(),
            ),
          ],
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            tooltip: _showSearch
                ? (_ar ? 'إغلاق البحث' : 'Close search')
                : (_ar ? 'بحث' : 'Search'),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _searcher?.resetTextSearch();
                }
              });
            },
          ),
          if (!_showSearch)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: _ar ? 'مشاركة' : 'Share',
              onPressed: () => Share.shareXFiles([XFile(widget.filePath)]),
            ),
        ],
      ),
      body: !exists
          ? Center(
              child: Text(_ar ? 'ملف PDF غير موجود' : 'PDF file was not found.'),
            )
          : Stack(
              children: [
                PdfViewer.file(
                  widget.filePath,
                  controller: _controller,
                  params: PdfViewerParams(
                    textSelectionParams: const PdfTextSelectionParams(
                      enabled: true,
                    ),
                    pagePaintCallbacks: [
                      if (_searcher != null) _searcher!.pageTextMatchPaintCallback,
                    ],
                    loadingBannerBuilder: (context, downloaded, total) =>
                        const Center(child: CircularProgressIndicator()),
                    errorBannerBuilder: (context, error, stack, ref) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          '${_ar ? 'تعذّر فتح الملف' : 'Could not open file'}'
                          ': $error',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    onViewerReady: (document, controller) {
                      if (!mounted) return;
                      final searcher = PdfTextSearcher(_controller)
                        ..addListener(_onSearchUpdate);
                      setState(() {
                        _searcher = searcher;
                        _pageCount = document.pages.length;
                        _ready = true;
                      });
                    },
                    onPageChanged: (pageNumber) {
                      if (!mounted) return;
                      setState(() => _pageNumber = pageNumber ?? 1);
                    },
                  ),
                ),
                if (_ready && _pageCount > 0)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          '$_pageNumber / $_pageCount',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
