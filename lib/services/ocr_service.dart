import 'dart:developer';

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

  Future<String> extractTextFromImage(String imagePath) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      log('OCR extractTextFromImage failed: $e');
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
