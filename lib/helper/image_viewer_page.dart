import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';

/// عارض صور احترافي: تكبير بإصبعين، تحريك، نقرة مزدوجة للتكبير، ومشاركة.
class ImageViewerPage extends StatelessWidget {
  const ImageViewerPage({super.key, required this.filePath});

  final String filePath;

  bool _isArabic(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          p.basename(filePath),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: _isArabic(context) ? 'مشاركة' : 'Share',
            onPressed: () => Share.shareXFiles([XFile(filePath)]),
          ),
        ],
      ),
      body: file.existsSync()
          ? PhotoView(
              imageProvider: FileImage(file),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 4,
              backgroundDecoration:
                  const BoxDecoration(color: Colors.black),
              loadingBuilder: (_, __) =>
                  const Center(child: CircularProgressIndicator()),
              heroAttributes: PhotoViewHeroAttributes(tag: filePath),
            )
          : Center(
              child: Text(
                _isArabic(context) ? 'الملف غير موجود' : 'File not found',
                style: const TextStyle(color: Colors.white),
              ),
            ),
    );
  }
}
