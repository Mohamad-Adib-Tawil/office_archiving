import 'package:flutter/material.dart';
import 'package:office_archiving/services/office_document_service.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

/// عارض جداول Excel (.xlsx) داخل التطبيق: يعرض أوّل ورقة كجدول.
class XlsxViewerPage extends StatefulWidget {
  const XlsxViewerPage({super.key, required this.filePath});

  final String filePath;

  @override
  State<XlsxViewerPage> createState() => _XlsxViewerPageState();
}

class _XlsxViewerPageState extends State<XlsxViewerPage> {
  late Future<List<List<String>>> _future;

  @override
  void initState() {
    super.initState();
    _future = OfficeDocumentService.instance.readExcelRows(widget.filePath);
  }

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

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
              onPressed: () => Share.shareXFiles([XFile(widget.filePath)]),
            ),
          ],
        ),
        body: FutureBuilder<List<List<String>>>(
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
            final rows = snapshot.data ?? const [];
            if (rows.isEmpty) {
              return Center(
                child: Text(_ar ? 'الجدول فارغ' : 'Sheet is empty'),
              );
            }
            final columnCount =
                rows.fold<int>(0, (m, r) => r.length > m ? r.length : m);
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                child: DataTable(
                  border: TableBorder.all(
                    color: theme.dividerColor,
                    width: 0.6,
                  ),
                  headingRowColor: WidgetStatePropertyAll(
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                  ),
                  columns: [
                    for (var c = 0; c < columnCount; c++)
                      DataColumn(
                        label: Text(
                          _columnLabel(c),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                  rows: [
                    for (final row in rows)
                      DataRow(
                        cells: [
                          for (var c = 0; c < columnCount; c++)
                            DataCell(
                              Text(c < row.length ? row[c] : ''),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// A, B, C ... Z, AA, AB ...
  String _columnLabel(int index) {
    var i = index;
    final sb = StringBuffer();
    while (i >= 0) {
      sb.write(String.fromCharCode(65 + (i % 26)));
      i = (i ~/ 26) - 1;
    }
    return sb.toString().split('').reversed.join();
  }
}
