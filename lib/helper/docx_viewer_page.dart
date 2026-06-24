import 'package:flutter/material.dart';
import 'package:office_archiving/services/office_document_service.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

/// عارض مستندات Word (.docx) داخل التطبيق: يقرأ الفقرات ويعرضها بشكل مرتّب.
class DocxViewerPage extends StatefulWidget {
  const DocxViewerPage({super.key, required this.filePath});

  final String filePath;

  @override
  State<DocxViewerPage> createState() => _DocxViewerPageState();
}

class _DocxViewerPageState extends State<DocxViewerPage> {
  late Future<List<String>> _future;

  @override
  void initState() {
    super.initState();
    _future = OfficeDocumentService.instance.readDocxParagraphs(widget.filePath);
  }

  bool get _ar =>
      Localizations.localeOf(context).languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            p.basename(widget.filePath),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: _ar ? 'مشاركة' : 'Share',
              onPressed: () =>
                  Share.shareXFiles([XFile(widget.filePath)]),
            ),
          ],
        ),
        body: FutureBuilder<List<String>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  '${_ar ? 'تعذّر فتح الملف' : 'Could not open file'}: '
                  '${snapshot.error}',
                ),
              );
            }
            final paragraphs = (snapshot.data ?? const [])
                .where((p) => p.trim().isNotEmpty)
                .toList();
            if (paragraphs.isEmpty) {
              return Center(
                child: Text(_ar ? 'المستند فارغ' : 'Document is empty'),
              );
            }
            return Container(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.4),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Card(
                    margin: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: SelectionArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final para in paragraphs)
                              Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  para,
                                  style: theme.textTheme.bodyLarge
                                      ?.copyWith(height: 1.6),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
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
