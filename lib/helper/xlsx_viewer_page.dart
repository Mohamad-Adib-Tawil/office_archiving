import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:office_archiving/helper/office_web_viewer.dart';
import 'package:office_archiving/pages/excel_editor_page.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

/// عارض جداول Excel (.xlsx) مع بحث وزر تعديل.
class XlsxViewerPage extends StatefulWidget {
  const XlsxViewerPage({super.key, required this.filePath});

  final String filePath;

  @override
  State<XlsxViewerPage> createState() => _XlsxViewerPageState();
}

class _XlsxViewerPageState extends State<XlsxViewerPage> {
  InAppWebViewController? _webCtrl;

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
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
              icon: const Icon(Icons.search),
              tooltip: _ar ? 'بحث' : 'Search',
              onPressed: () =>
                  _webCtrl?.evaluateJavascript(source: 'openSearch()'),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: _ar ? 'تعديل' : 'Edit',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ExcelEditorPage(existingPath: widget.filePath),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: _ar ? 'مشاركة' : 'Share',
              onPressed: () =>
                  Share.shareXFiles([XFile(widget.filePath)]),
            ),
          ],
        ),
        body: OfficeWebViewerPage(
          filePath: widget.filePath,
          assetHtml: 'assets/viewers/xlsx.html',
          jsFunction: 'renderXlsx',
          embedded: true,
          onWebViewCreated: (ctrl) => _webCtrl = ctrl,
        ),
      ),
    );
  }
}
