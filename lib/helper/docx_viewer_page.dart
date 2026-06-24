import 'package:flutter/material.dart';
import 'package:office_archiving/helper/office_web_viewer.dart';

/// عارض مستندات Word (.docx) عالي الجودة عبر WebView محلي (docx-preview.js).
/// يعمل أوفلاين بالكامل ويحافظ على الجداول والصور والتنسيق.
class DocxViewerPage extends StatelessWidget {
  const DocxViewerPage({super.key, required this.filePath});

  final String filePath;

  @override
  Widget build(BuildContext context) {
    return OfficeWebViewerPage(
      filePath: filePath,
      assetHtml: 'assets/viewers/docx.html',
      jsFunction: 'renderDocx',
    );
  }
}
