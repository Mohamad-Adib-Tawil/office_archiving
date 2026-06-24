import 'dart:developer';
import 'package:office_archiving/services/sqlite_service.dart';
import 'package:office_archiving/services/professional_ocr_service.dart';

class OCRService {
  static const int _safePdfOcrMaxPages = 3;
  static const int _safePdfOcrDpi = 72;
  static const int _safePdfOcrMaxFileSizeBytes = 12 * 1024 * 1024;

  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();
  final ProfessionalOcrService _engine = ProfessionalOcrService.instance;

  Future<void> initialize() async {
    await _engine.initialize();
  }

  /// OCR for multi-page PDF -> concatenated text
  Future<String> recognizePdfToText(
    String pdfPath, {
    String lang = 'auto',
    int maxPages = _safePdfOcrMaxPages,
    int dpi = _safePdfOcrDpi,
    int maxFileSizeBytes = _safePdfOcrMaxFileSizeBytes,
  }) async {
    try {
      final result = await _engine.recognizePdf(
        pdfPath,
        options: ProfessionalOcrOptions(
          languageProfile: _profileFromLang(lang),
          pdfMaxPages: maxPages,
          pdfDpi: dpi,
          pdfMaxFileSizeBytes: maxFileSizeBytes,
        ),
      );
      return result.text;
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
    bool allowPdf = true,
  }) async {
    String text;
    final t = fileType.toLowerCase();
    if (t == 'pdf') {
      if (!allowPdf) {
        log('Auto OCR skipped for PDF item id=$id path=$filePath');
        return;
      }
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
    final rows = await DatabaseService.instance.getItemsMissingOcr(
      limit: limit,
    );
    int processed = 0;
    final total = rows.length;
    for (final row in rows) {
      final id = row['id'] as int;
      final path = row['filePath'] as String?;
      final type = (row['fileType'] as String?) ?? '';
      if (path == null || path.isEmpty) continue;
      await processItemAndSaveOcr(
        id: id,
        filePath: path,
        fileType: type,
        lang: lang,
      );
      processed++;
      if (onProgress != null) onProgress(processed, total);
    }
    return processed;
  }

  Future<String> extractTextFromImage(String imagePath) async {
    // Backward compatible API -> use advanced pipeline with auto language
    return recognizeTextAdvanced(imagePath, lang: 'auto');
  }

  Future<ProfessionalOcrResult> recognizeImageProfessionally(
    String imagePath, {
    String lang = 'auto',
  }) {
    return _engine.recognizeImage(
      imagePath,
      options: ProfessionalOcrOptions(languageProfile: _profileFromLang(lang)),
    );
  }

  Future<ProfessionalOcrResult> recognizePdfProfessionally(
    String pdfPath, {
    String lang = 'auto',
    int maxPages = _safePdfOcrMaxPages,
    int dpi = _safePdfOcrDpi,
    int maxFileSizeBytes = _safePdfOcrMaxFileSizeBytes,
  }) {
    return _engine.recognizePdf(
      pdfPath,
      options: ProfessionalOcrOptions(
        languageProfile: _profileFromLang(lang),
        pdfMaxPages: maxPages,
        pdfDpi: dpi,
        pdfMaxFileSizeBytes: maxFileSizeBytes,
      ),
    );
  }

  /// Advanced OCR: preprocessing + orientation trials + dual backend
  /// lang: 'auto' | 'ar' | 'en'
  Future<String> recognizeTextAdvanced(
    String imagePath, {
    String lang = 'auto',
  }) async {
    try {
      final result = await _engine.recognizeImage(
        imagePath,
        options: ProfessionalOcrOptions(
          languageProfile: _profileFromLang(lang),
        ),
      );
      return result.text;
    } catch (e) {
      log('OCR recognizeTextAdvanced failed: $e');
      throw Exception('فشل في استخراج النص: $e');
    }
  }

  Future<Map<String, dynamic>> extractTextWithDetails(String imagePath) async {
    try {
      return await _engine.extractLatinDetails(imagePath);
    } catch (e) {
      log('OCR extractTextWithDetails failed: $e');
      throw Exception('فشل في تحليل الصورة: $e');
    }
  }

  Future<bool> isTextDetected(String imagePath) async {
    try {
      return await _engine.isLatinTextDetected(imagePath);
    } catch (e) {
      log('OCR isTextDetected failed: $e');
      return false;
    }
  }

  Future<List<String>> extractKeywords(String imagePath) async {
    try {
      final text = await extractTextFromImage(imagePath);

      // استخراج الكلمات المفتاحية البسيط
      final words = text
          .split(RegExp(r'\s+'))
          .where((word) => word.length > 3) // كلمات أطول من 3 أحرف
          .map(
            (word) => word.replaceAll(RegExp(r'[^\w\u0600-\u06FF]'), ''),
          ) // إزالة الرموز
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
    _engine.dispose();
  }

  OcrLanguageProfile _profileFromLang(String lang) {
    switch (lang.toLowerCase()) {
      case 'ar':
        return OcrLanguageProfile.arabic;
      case 'en':
        return OcrLanguageProfile.english;
      case 'mixed':
        return OcrLanguageProfile.mixed;
      case 'auto':
      default:
        return OcrLanguageProfile.auto;
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
