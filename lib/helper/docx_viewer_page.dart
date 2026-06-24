import 'dart:io';

import 'package:docx_file_viewer/docx_file_viewer.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

/// عارض مستندات Word (.docx) native بالكامل — بدون WebView.
/// يستخدم docx_file_viewer لتحويل المستند إلى Flutter widgets تتكيّف مع الشاشة.
class DocxViewerPage extends StatefulWidget {
  const DocxViewerPage({super.key, required this.filePath});

  final String filePath;

  @override
  State<DocxViewerPage> createState() => _DocxViewerPageState();
}

class _DocxViewerPageState extends State<DocxViewerPage> {
  late final Future<List<Widget>> _future;

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _future = DocxExtractor().renderLayout(File(widget.filePath));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFE8EAED),
        appBar: AppBar(
          title: Text(
            p.basename(widget.filePath),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: _ar ? 'مشاركة' : 'Share',
              onPressed: () => Share.shareXFiles([XFile(widget.filePath)]),
            ),
          ],
        ),
        body: FutureBuilder<List<Widget>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text(
                        _ar ? 'تعذّر فتح المستند' : 'Could not open document',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              );
            }

            final widgets = snapshot.data!;
            if (widgets.isEmpty) {
              return Center(
                child: Text(_ar ? 'المستند فارغ' : 'Document is empty'),
              );
            }

            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                itemCount: widgets.length,
                itemBuilder: (_, i) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: i == 0
                      ? BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        )
                      : const BoxDecoration(color: Colors.white),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    child: widgets[i],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
