// خدمة PDF: إنشاء ودمج وإضافة علامة مائية على PDF فعلي
// تعتمد على حزمتَي pdf و printing. الدمج/العلامة المائية يتمان عبر تحويل الصفحات إلى صور ثم إعادة تركيبها.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:office_archiving/services/document_storage_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  PdfService._();
  static final PdfService _instance = PdfService._();
  factory PdfService() => _instance;

  final DocumentStorageService _storageService =
      DocumentStorageService.instance;

  Future<File> _savePdfBytes(Uint8List bytes, String fileName) async {
    return _storageService.writeBytes(
      bytes: bytes,
      directory: ManagedDirectory.exports,
      fileName: fileName,
    );
  }

  Future<File> createPdfFromImages(
    List<String> imagePaths, {
    String? fileName,
  }) async {
    if (imagePaths.isEmpty) {
      throw ArgumentError('At least one image is required to create a PDF.');
    }

    final doc = pw.Document();
    var pageCount = 0;

    for (final path in imagePaths) {
      final file = File(path);
      if (!await file.exists()) {
        continue;
      }

      final bytes = await File(path).readAsBytes();
      final image = pw.MemoryImage(bytes);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (_) => pw.Center(
            child: pw.FittedBox(fit: pw.BoxFit.contain, child: pw.Image(image)),
          ),
        ),
      );
      pageCount++;
    }

    if (pageCount == 0) {
      throw const FileSystemException(
        'No readable images were found to build the PDF.',
      );
    }

    final name =
        fileName ?? 'document_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final bytes = await doc.save();
    return _savePdfBytes(bytes, name);
  }

  Future<File> mergePdfs(List<File> pdfFiles, {String? fileName}) async {
    final outDoc = pw.Document();
    var pageCount = 0;

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
            pageFormat: PdfPageFormat(
              page.width / 72.0 * PdfPageFormat.inch,
              page.height / 72.0 * PdfPageFormat.inch,
            ),
            build: (_) =>
                pw.Center(child: pw.Image(img, fit: pw.BoxFit.contain)),
          ),
        );
        pageCount++;
      }
    }

    if (pageCount == 0) {
      throw const FileSystemException(
        'No readable PDF pages were found to merge.',
      );
    }

    final name =
        fileName ?? 'merged_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final bytes = await outDoc.save();
    return _savePdfBytes(bytes, name);
  }

  Future<File> addWatermark(
    File source, {
    String watermark = 'Office Archiving',
  }) async {
    if (!(await source.exists())) {
      throw FileSystemException('Source PDF does not exist', source.path);
    }

    final data = await source.readAsBytes();
    final outDoc = pw.Document();
    var pageCount = 0;

    final pages = Printing.raster(data, dpi: 144.0);
    await for (final page in pages) {
      final Uint8List pngBytes = await page.toPng();
      final img = pw.MemoryImage(pngBytes);
      outDoc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(
            page.width / 72.0 * PdfPageFormat.inch,
            page.height / 72.0 * PdfPageFormat.inch,
          ),
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
                        style: const pw.TextStyle(
                          fontSize: 48,
                          color: PdfColors.red,
                        ),
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
      pageCount++;
    }

    if (pageCount == 0) {
      throw const FileSystemException(
        'No readable PDF pages were found to watermark.',
      );
    }

    final name = 'watermarked_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final bytes = await outDoc.save();
    return _savePdfBytes(bytes, name);
  }

  Future<File> createProtectedCopy({
    required File source,
    String? watermark,
    Uint8List? signatureBytes,
    String? fileName,
    PdfColor watermarkColor = PdfColors.grey700,
    double watermarkOpacity = 0.14,
  }) async {
    if (!(await source.exists())) {
      throw FileSystemException('Source PDF does not exist', source.path);
    }

    final data = await source.readAsBytes();
    final renderedPages = <_RasterizedPdfPage>[];
    final pageStream = Printing.raster(data, dpi: 170.0);

    await for (final page in pageStream) {
      renderedPages.add(
        _RasterizedPdfPage(
          pngBytes: await page.toPng(),
          width: page.width.toDouble(),
          height: page.height.toDouble(),
        ),
      );
    }

    if (renderedPages.isEmpty) {
      throw const FileSystemException(
        'No readable PDF pages were found to protect.',
      );
    }

    final outDoc = pw.Document();
    final normalizedWatermark = watermark?.trim();
    final signatureImage = (signatureBytes != null && signatureBytes.isNotEmpty)
        ? pw.MemoryImage(signatureBytes)
        : null;

    for (var index = 0; index < renderedPages.length; index++) {
      final renderedPage = renderedPages[index];
      final pageImage = pw.MemoryImage(renderedPage.pngBytes);
      outDoc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(
            renderedPage.width / 72.0 * PdfPageFormat.inch,
            renderedPage.height / 72.0 * PdfPageFormat.inch,
          ),
          build: (_) => pw.Stack(
            children: [
              pw.Positioned.fill(
                child: pw.Image(pageImage, fit: pw.BoxFit.contain),
              ),
              if (normalizedWatermark != null && normalizedWatermark.isNotEmpty)
                pw.Positioned.fill(
                  child: pw.Center(
                    child: pw.Transform.rotate(
                      angle: -0.45,
                      child: pw.Opacity(
                        opacity: watermarkOpacity,
                        child: pw.Text(
                          normalizedWatermark,
                          style: pw.TextStyle(
                            fontSize: 44,
                            color: watermarkColor,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              if (signatureImage != null && index == renderedPages.length - 1)
                pw.Positioned(
                  right: 20,
                  bottom: 20,
                  child: pw.Container(
                    width: 120,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(8),
                      ),
                    ),
                    child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final name =
        fileName ?? 'protected_${DateTime.now().millisecondsSinceEpoch}.pdf';
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
      final dir =
          outputDir ??
          await _storageService.getManagedDirectory(ManagedDirectory.scans);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      if (!(await pdfFile.exists())) return [];
      final data = await pdfFile.readAsBytes();
      final stream = Printing.raster(data, dpi: dpi.toDouble());
      final files = <File>[];
      int index = 1;
      final base =
          namePrefix ?? 'scan_${DateTime.now().millisecondsSinceEpoch}';
      await for (final page in stream) {
        final pngBytes = await page.toPng();
        final outPath = '${dir.path}/${base}_p$index.png';
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

class _RasterizedPdfPage {
  const _RasterizedPdfPage({
    required this.pngBytes,
    required this.width,
    required this.height,
  });

  final Uint8List pngBytes;
  final double width;
  final double height;
}
