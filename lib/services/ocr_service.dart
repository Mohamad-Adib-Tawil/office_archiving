// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'; // Temporarily disabled

class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();
  // late final TextRecognizer _textRecognizer; // Temporarily disabled
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Temporarily disabled ML Kit initialization
    // _textRecognizer = TextRecognizer(
    //   script: TextRecognitionScript.latin,
    // );
    _isInitialized = true;
  }

  Future<String> extractTextFromImage(String imagePath) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Temporarily return mock text for testing
      return "OCR temporarily disabled - ML Kit libraries not available.\nImage path: $imagePath\nThis is a placeholder text for testing image picker functionality.";
    } catch (e) {
      throw Exception('فشل في استخراج النص: $e');
    }
  }

  Future<Map<String, dynamic>> extractTextWithDetails(String imagePath) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final text = await extractTextFromImage(imagePath);
      
      return {
        'fullText': text,
        'blocks': [
          {
            'text': text,
            'confidence': 0.9,
            'lines': text.split('\n').map((line) => {'text': line}).toList(),
          }
        ],
        'totalBlocks': 1,
        'hasText': text.isNotEmpty,
      };
    } catch (e) {
      throw Exception('فشل في تحليل الصورة: $e');
    }
  }

  Future<bool> isTextDetected(String imagePath) async {
    try {
      final result = await extractTextFromImage(imagePath);
      return result.trim().isNotEmpty;
    } catch (e) {
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
      return [];
    }
  }

  void dispose() {
    if (_isInitialized) {
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
