// خدمة PDF: إنشاء ودمج وإضافة علامة مائية على PDF فعلي
// تعتمد على حزمتَي pdf و printing. الدمج/العلامة المائية يتمان عبر تحويل الصفحات إلى صور ثم إعادة تركيبها.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:office_archiving/constants.dart';
import 'package:media_store_plus/media_store_plus.dart';
// duplicate import removed

class PdfService {
  PdfService._();
  static final PdfService _instance = PdfService._();
  factory PdfService() => _instance;

  // تحديد مجلد الإخراج: مجلد مستندات التطبيق (مؤقتاً لتجنب مشاكل الإضافات على أندرويد)
  Future<Directory> _getOutputDir() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final out = Directory(p.join(dir.path, kOfficeArchiving));
      if (!await out.exists()) {
        await out.create(recursive: true);
      }
      return out;
    } catch (e) {
      if (kDebugMode) {
        print('PdfService _getOutputDir error: $e');
      }
      return await getApplicationDocumentsDirectory();
    }
  }

  // حفظ بايتات PDF إلى الموقع النهائي حسب النظام
  Future<File> _savePdfBytes(Uint8List bytes, String fileName) async {
    if (Platform.isAndroid) {
      try {
        // 1) اكتب إلى ملف مؤقت
        final tmpDir = await getTemporaryDirectory();
        final tmpPath = p.join(tmpDir.path, fileName);
        final tmpFile = File(tmpPath);
        await tmpFile.writeAsBytes(bytes, flush: true);

        // 2) MediaStore: Downloads/Office Archiving
        await MediaStore.ensureInitialized();
        MediaStore.appFolder = kOfficeArchiving; // سيستخدم كـ relativePath الافتراضي
        final ms = MediaStore();
        final saved = await ms.saveFile(
          tempFilePath: tmpPath,
          dirType: DirType.download,
          dirName: DirName.download,
          // relativePath: null => يستخدم MediaStore.appFolder
        );

        // حذف المؤقت (قد يُحذف من البلجن أيضاً، لا ضرر بالتأكيد)
        try {
          if (await tmpFile.exists()) await tmpFile.delete();
        } catch (_) {}

        if (saved != null && saved.isSuccessful) {
          // حاول الحصول على مسار فعلي لعرضه للمستخدم
          final uriStr = saved.uri.toString();
          final resolved = await ms.getFilePathFromUri(uriString: uriStr);
          if (resolved != null && resolved.isNotEmpty) {
            return File(resolved);
          }
          // مسار تقريبي في حال لم نستطع حله
          final approx = p.join('/storage/emulated/0', 'Download', kOfficeArchiving, fileName);
          return File(approx);
        }
      } catch (e) {
        if (kDebugMode) {
          print('PdfService _savePdfBytes MediaStore error: $e');
        }
      }
      // فشل MediaStore، احفظ داخل مجلد التطبيق
      final fallbackDir = await _getOutputDir();
      final fallbackFile = File(p.join(fallbackDir.path, fileName));
      await fallbackFile.writeAsBytes(bytes, flush: true);
      return fallbackFile;
    }

    // iOS/desktop: احفظ داخل مجلد التطبيق
    final dir = await _getOutputDir();
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  // إنشاء PDF من قائمة صور
  Future<File> createPdfFromImages(List<String> imagePaths, {String? fileName}) async {
    final doc = pw.Document();

    for (final path in imagePaths) {
      final bytes = await File(path).readAsBytes();
      final image = pw.MemoryImage(bytes);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (_) => pw.Center(
            child: pw.FittedBox(
              fit: pw.BoxFit.contain,
              child: pw.Image(image),
            ),
          ),
        ),
      );
    }

    final name = fileName ?? 'document_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final bytes = await doc.save();
    return _savePdfBytes(bytes, name);
  }

  // دمج ملفات PDF متعددة في ملف واحد
  Future<File> mergePdfs(List<File> pdfFiles, {String? fileName}) async {
    final outDoc = pw.Document();

    for (final f in pdfFiles) {
      if (!(await f.exists())) continue;
      final data = await f.readAsBytes();
      // Rasterize كل صفحات PDF المصدر ثم إضافتها كصور في مستند جديد
      final pages = Printing.raster(data, dpi: 144.0);
      await for (final page in pages) {
        final Uint8List pngBytes = await page.toPng();
        final img = pw.MemoryImage(pngBytes);
        outDoc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(page.width / 72.0 * PdfPageFormat.inch, page.height / 72.0 * PdfPageFormat.inch),
            build: (_) => pw.Center(child: pw.Image(img, fit: pw.BoxFit.contain)),
          ),
        );
      }
    }

    final name = fileName ?? 'merged_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final bytes = await outDoc.save();
    return _savePdfBytes(bytes, name);
  }

  // إضافة علامة مائية نصية على كل صفحة
  Future<File> addWatermark(File source, {String watermark = 'Office Archiving'}) async {
    final data = await source.readAsBytes();
    final outDoc = pw.Document();

    final pages = Printing.raster(data, dpi: 144.0);
    await for (final page in pages) {
      final Uint8List pngBytes = await page.toPng();
      final img = pw.MemoryImage(pngBytes);
      outDoc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(page.width / 72.0 * PdfPageFormat.inch, page.height / 72.0 * PdfPageFormat.inch),
          build: (_) => pw.Stack(
            children: [
              pw.Positioned.fill(child: pw.Image(img, fit: pw.BoxFit.contain)),
              pw.Positioned.fill(
                child: pw.Center(
                  child: pw.Transform.rotate(
                    angle: -0.35,
                    child: pw.Opacity(
                      opacity: 0.12,
                      child: pw.Text(
                        watermark,
                        style: pw.TextStyle(fontSize: 48, color: PdfColors.red),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final name = 'watermarked_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final bytes = await outDoc.save();
    return _savePdfBytes(bytes, name);
  }

  // Rasterize a PDF to PNG images and save them to outputDir (default: Documents/scans)
  Future<List<File>> rasterizePdfToImages(
    File pdfFile, {
    Directory? outputDir,
    String? namePrefix,
    int dpi = 144,
  }) async {
    try {
      final dir = outputDir ??
          Directory(p.join((await getApplicationDocumentsDirectory()).path, 'scans'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      if (!(await pdfFile.exists())) return [];
      final data = await pdfFile.readAsBytes();
      final stream = Printing.raster(data, dpi: dpi.toDouble());
      final files = <File>[];
      int index = 1;
      final base = namePrefix ?? 'scan_${DateTime.now().millisecondsSinceEpoch}';
      await for (final page in stream) {
        final pngBytes = await page.toPng();
        final outPath = p.join(dir.path, '${base}_p$index.png');
        final f = File(outPath);
        await f.writeAsBytes(pngBytes, flush: true);
        files.add(f);
        index++;
      }
      return files;
    } catch (e) {
      if (kDebugMode) {
        print('PdfService rasterizePdfToImages error: $e');
      }
      return [];
    }
  }
}
