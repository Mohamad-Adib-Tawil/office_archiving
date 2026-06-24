import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path/path.dart' as p;

class MyPdfViewer extends StatefulWidget {
  const MyPdfViewer({super.key, required this.filePath});

  final String filePath;

  @override
  State<MyPdfViewer> createState() => _MyPdfViewerState();
}

class _MyPdfViewerState extends State<MyPdfViewer> {
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isReady = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final file = File(widget.filePath);
    final exists = file.existsSync();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          p.basename(widget.filePath),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: !exists
          ? const Center(child: Text('PDF file was not found.'))
          : Stack(
              children: [
                PDFView(
                  filePath: widget.filePath,
                  fitEachPage: true,
                  fitPolicy: FitPolicy.BOTH,
                  onRender: (pages) {
                    if (!mounted) {
                      return;
                    }
                    setState(() {
                      _totalPages = pages ?? 0;
                      _isReady = true;
                    });
                  },
                  onError: (error) {
                    if (!mounted) {
                      return;
                    }
                    setState(() => _errorMessage = error.toString());
                  },
                  onPageError: (page, error) {
                    if (!mounted) {
                      return;
                    }
                    setState(() => _errorMessage = 'Page $page: $error');
                  },
                  onViewCreated: (controller) async {
                    final pageCount = await controller.getPageCount() ?? 0;
                    if (!mounted) {
                      return;
                    }
                    setState(() => _totalPages = pageCount);
                  },
                  onPageChanged: (page, total) {
                    if (!mounted) {
                      return;
                    }
                    setState(() {
                      _currentPage = page ?? 0;
                      _totalPages = total ?? _totalPages;
                    });
                  },
                ),
                if (_errorMessage != null)
                  Center(child: Text(_errorMessage!))
                else if (!_isReady)
                  const Center(child: CircularProgressIndicator()),
                if (_isReady && _errorMessage == null && _totalPages > 0)
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
                          '${_currentPage + 1} / $_totalPages',
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
