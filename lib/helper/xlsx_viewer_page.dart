import 'package:flutter/material.dart';
import 'package:office_archiving/helper/office_web_viewer.dart';

/// عارض جداول Excel (.xlsx) عالي الجودة عبر WebView محلي (SheetJS).
/// يعمل أوفلاين بالكامل، يدعم تعدّد الأوراق ودمج الخلايا والتنسيق.
class XlsxViewerPage extends StatelessWidget {
  const XlsxViewerPage({super.key, required this.filePath});

  final String filePath;

  @override
  Widget build(BuildContext context) {
    return OfficeWebViewerPage(
      filePath: filePath,
      assetHtml: 'assets/viewers/xlsx.html',
      jsFunction: 'renderXlsx',
    );
  }
}
