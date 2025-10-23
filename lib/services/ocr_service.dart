import 'dart:developer';
import 'dart:io';

import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';
import 'package:office_archiving/service/sqlite_service.dart';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();
  late final TextRecognizer _textRecognizer;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    // Initialize ML Kit Text Recognizer (Latin script works for most English docs)
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _isInitialized = true;
  }

  /// OCR for multi-page PDF -> concatenated text
  Future<String> recognizePdfToText(String pdfPath, {String lang = 'auto'}) async {
    try {
      final data = await File(pdfPath).readAsBytes();
      final pages = Printing.raster(data, dpi: 144);
      final buffer = StringBuffer();
      int index = 1;
      await for (final page in pages) {
        final pngBytes = await page.toPng();
        final tmp = await _writeTempFile(pngBytes, suffix: '_pdf_$index.png');
        final t = await recognizeTextAdvanced(tmp.path, lang: lang);
        if (t.trim().isNotEmpty) {
          buffer.writeln('--- Page $index ---');
          buffer.writeln(t);
          buffer.writeln();
        }
        index++;
      }
      return buffer.toString();
    } catch (e) {
      log('recognizePdfToText failed: $e');
      rethrow;
    }
  }

  /// Detect file type and save OCR text to DB for given item
  Future<void> processItemAndSaveOcr({
    required int id,
    required String filePath,
    required String fileType,
    String lang = 'auto',
  }) async {
    String text;
    final t = fileType.toLowerCase();
    if (t == 'pdf') {
      text = await recognizePdfToText(filePath, lang: lang);
    } else {
      text = await recognizeTextAdvanced(filePath, lang: lang);
    }
    await DatabaseService.instance.updateItemOcr(
      id,
      ocrText: text,
      ocrLang: lang,
      hasText: text.trim().isNotEmpty,
      processedAt: DateTime.now(),
    );
  }

  /// Batch OCR for items missing OCR text
  Future<int> batchProcessMissingOcr({
    String lang = 'auto',
    int? limit,
    void Function(int processed, int total)? onProgress,
  }) async {
    final rows = await DatabaseService.instance.getItemsMissingOcr(limit: limit);
    int processed = 0;
    final total = rows.length;
    for (final row in rows) {
      final id = row['id'] as int;
      final path = row['filePath'] as String?;
      final type = (row['fileType'] as String?) ?? '';
      if (path == null || path.isEmpty) continue;
      await processItemAndSaveOcr(id: id, filePath: path, fileType: type, lang: lang);
      processed++;
      if (onProgress != null) onProgress(processed, total);
    }
    return processed;
  }

  // --------- Internal helpers ---------
  Future<String> _extractWithMlkit(String imagePath) async {
    if (!_isInitialized) {
      await initialize();
    }
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  Future<String> _extractWithTesseract(String imagePath, {required String languages}) async {
    // languages like 'ara' or 'ara+eng'
    // Use bundled tessdata inside assets
    final args = {
      'psm': '3', // default page segmentation
      'oem': '1', // LSTM only
      'tessdata': 'assets/tessdata',
      'preserve_interword_spaces': '1',
    };
    final text = await FlutterTesseractOcr.extractText(
      imagePath,
      language: languages,
      args: args,
    );
    return text;
  }

  String _chooseAuto(String tesseractText, String mlkitText) {
    // Prefer Arabic-rich text; otherwise pick longer
    int arCount(String s) => RegExp(r'[\u0600-\u06FF]').allMatches(s).length;
    final tAr = arCount(tesseractText);
    final mAr = arCount(mlkitText);
    if (tAr >= mAr && tAr > 0) return tesseractText;
    if (mAr > tAr && mAr > 0) return mlkitText;
    return tesseractText.trim().length >= mlkitText.trim().length
        ? tesseractText
        : mlkitText;
  }

  int _scoreText(String text, {bool preferArabic = true}) {
    final len = text.trim().length;
    int score = len;
    if (preferArabic) {
      final ar = RegExp(r'[\u0600-\u06FF]').allMatches(text).length;
      score += ar * 5; // weight Arabic characters higher
    }
    return score;
  }

  Future<String> _preprocessForOcr(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return imagePath; // fallback

      // Auto orient and grayscale + slight contrast
      final oriented = img.bakeOrientation(decoded);
      var gray = img.grayscale(oriented);
      gray = img.adjustColor(gray, contrast: 1.2);

      final outBytes = img.encodePng(gray);
      final tmp = await _writeTempFile(outBytes, suffix: '_pre.png');
      return tmp.path;
    } catch (_) {
      return imagePath;
    }
  }

  Future<String> _rotateImageToTemp(String path, int angle) async {
    try {
      final bytes = await File(path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return path;
      final rotated = img.copyRotate(decoded, angle: angle);
      final out = img.encodePng(rotated);
      final tmp = await _writeTempFile(out, suffix: '_r$angle.png');
      return tmp.path;
    } catch (_) {
      return path;
    }
  }

  Future<File> _writeTempFile(List<int> bytes, {String suffix = '.png'}) async {
    final dir = Directory.systemTemp.createTempSync('ocr_');
    final file = File('${dir.path}/img$suffix');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<String> extractTextFromImage(String imagePath) async {
    // Backward compatible API -> use advanced pipeline with auto language
    return recognizeTextAdvanced(imagePath, lang: 'auto');
  }

  /// Advanced OCR: preprocessing + orientation trials + dual backend
  /// lang: 'auto' | 'ar' | 'en'
  Future<String> recognizeTextAdvanced(String imagePath, {String lang = 'auto'}) async {
    try {
      // 1) Preprocess
      final preprocessedPath = await _preprocessForOcr(imagePath);

      // 2) Try rotations with slight deskew around 0 and 90/180/270 if needed
      final angles = [0, -5, 5, 90, 180, 270];
      String bestText = '';
      int bestScore = -1;

      for (final angle in angles) {
        final rotatedPath = angle == 0
            ? preprocessedPath
            : await _rotateImageToTemp(preprocessedPath, angle);

        String text = '';
        if (lang == 'ar') {
          text = await _extractWithTesseract(rotatedPath, languages: 'ara');
        } else if (lang == 'en') {
          text = await _extractWithMlkit(rotatedPath);
        } else {
          // auto: favor arabic if present, otherwise choose longer
          final tText = await _extractWithTesseract(rotatedPath, languages: 'ara+eng');
          final mText = await _extractWithMlkit(rotatedPath);
          text = _chooseAuto(tText, mText);
        }

        final score = _scoreText(text, preferArabic: lang == 'ar' || lang == 'auto');
        if (score > bestScore) {
          bestScore = score;
          bestText = text;
        }
      }

      return bestText;
    } catch (e) {
      log('OCR recognizeTextAdvanced failed: $e');
      throw Exception('فشل في استخراج النص: $e');
    }
  }

  Future<Map<String, dynamic>> extractTextWithDetails(String imagePath) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final blocks = recognizedText.blocks
          .map((b) => {
                'text': b.text,
                'lines': b.lines.map((l) => {'text': l.text}).toList(),
              })
          .toList();

      return {
        'fullText': recognizedText.text,
        'blocks': blocks,
        'totalBlocks': blocks.length,
        'hasText': recognizedText.text.trim().isNotEmpty,
      };
    } catch (e) {
      log('OCR extractTextWithDetails failed: $e');
      throw Exception('فشل في تحليل الصورة: $e');
    }
  }

  Future<bool> isTextDetected(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text.trim().isNotEmpty;
    } catch (e) {
      log('OCR isTextDetected failed: $e');
      return false;
    }
  }

  Future<List<String>> extractKeywords(String imagePath) async {
    try {
      final text = await extractTextFromImage(imagePath);
      
      // استخراج الكلمات المفتاحية البسيط
      final words = text.split(RegExp(r'\s+'))
          .where((word) => word.length > 3) // كلمات أطول من 3 أحرف
          .map((word) => word.replaceAll(RegExp(r'[^\w\u0600-\u06FF]'), '')) // إزالة الرموز
          .where((word) => word.isNotEmpty)
          .toSet() // إزالة التكرار
          .toList();
      
      // ترتيب حسب الطول (الكلمات الأطول أولاً)
      words.sort((a, b) => b.length.compareTo(a.length));
      
      return words.take(10).toList(); // أفضل 10 كلمات مفتاحية
    } catch (e) {
      log('OCR extractKeywords failed: $e');
      return [];
    }
  }

  void dispose() {
    if (_isInitialized) {
      _textRecognizer.close();
      _isInitialized = false;
    }
  }
}

// نموذج لحفظ نتائج OCR
class OCRResult {
  final String filePath;
  final String extractedText;
  final List<String> keywords;
  final DateTime processedAt;
  final bool hasText;

  OCRResult({
    required this.filePath,
    required this.extractedText,
    required this.keywords,
    required this.processedAt,
    required this.hasText,
  });

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'extractedText': extractedText,
      'keywords': keywords,
      'processedAt': processedAt.toIso8601String(),
      'hasText': hasText,
    };
  }

  factory OCRResult.fromJson(Map<String, dynamic> json) {
    return OCRResult(
      filePath: json['filePath'],
      extractedText: json['extractedText'],
      keywords: List<String>.from(json['keywords']),
      processedAt: DateTime.parse(json['processedAt']),
      hasText: json['hasText'],
    );
  }
}
