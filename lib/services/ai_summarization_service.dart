
import 'dart:convert';
import 'package:http/http.dart' as http;

class AISummarizationService {
  static final AISummarizationService _instance = AISummarizationService._internal();
  factory AISummarizationService() => _instance;
  AISummarizationService._internal();

  // يمكن استخدام Hugging Face API للتلخيص المجاني
  static const String _huggingFaceUrl = 'https://api-inference.huggingface.co/models/facebook/bart-large-cnn';
  static String? _apiKey; // مفتاح API اختياري

  // تعيين أو إزالة مفتاح API
  void setApiKey(String? key) {
    _apiKey = (key != null && key.trim().isNotEmpty) ? key.trim() : null;
  }

  // تلخيص باستخدام AI حقيقي أو خوارزميات محلية
  Future<String> summarizeText(String text, {int maxSentences = 3}) async {
    if (text.trim().isEmpty) return '';
    
    try {
      // محاولة استخدام Hugging Face API أولاً
      if (text.length > 100 && text.split(' ').length > 50) {
        try {
          final aiSummary = await _summarizeWithAI(text);
          if (aiSummary.isNotEmpty) return aiSummary;
        } catch (e) {
          // في حالة فشل AI، نستخدم الخوارزمية المحلية
          // فشل في التلخيص بالذكاء الاصطناعي، استخدام الخوارزمية المحلية
        }
      }
      
      // تلخيص محلي كبديل
      return await _summarizeLocally(text, maxSentences);
    } catch (e) {
      throw Exception('فشل في تلخيص النص: $e');
    }
  }

  // تلخيص باستخدام Hugging Face API
  Future<String> _summarizeWithAI(String text) async {
    try {
      final response = await http.post(
        Uri.parse(_huggingFaceUrl),
        headers: {
          'Content-Type': 'application/json',
          if (_apiKey != null) 'Authorization': 'Bearer ' + _apiKey!,
        },
        body: jsonEncode({
          'inputs': text,
          'parameters': {
            'max_length': 150,
            'min_length': 30,
            'do_sample': false,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data[0]['summary_text'] ?? '';
        }
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  // تلخيص محلي كبديل
  Future<String> _summarizeLocally(String text, int maxSentences) async {
    // تقسيم النص إلى جمل
    final sentences = _splitIntoSentences(text);
    
    if (sentences.length <= maxSentences) {
      return text; // النص قصير بما فيه الكفاية
    }
    
    // تسجيل الجمل حسب الأهمية
    final scoredSentences = _scoreSentences(sentences);
    
    // اختيار أفضل الجمل
    scoredSentences.sort((a, b) => b['score'].compareTo(a['score']));
    final topSentences = scoredSentences.take(maxSentences).toList();
    
    // ترتيب الجمل المختارة حسب ترتيبها الأصلي
    topSentences.sort((a, b) => a['index'].compareTo(b['index']));
    
    return topSentences.map((s) => s['sentence']).join(' ');
  }

  List<String> _splitIntoSentences(String text) {
    // تقسيم النص إلى جمل باستخدام علامات الترقيم
    final sentences = text
        .split(RegExp(r'[.!?؟।।]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 10)
        .toList();
    
    return sentences;
  }

  List<Map<String, dynamic>> _scoreSentences(List<String> sentences) {
    // حساب تكرار الكلمات
    final wordFreq = <String, int>{};
    final allWords = <String>[];
    
    for (final sentence in sentences) {
      final words = _extractWords(sentence);
      allWords.addAll(words);
      for (final word in words) {
        wordFreq[word] = (wordFreq[word] ?? 0) + 1;
      }
    }
    
    // تسجيل كل جملة
    final scoredSentences = <Map<String, dynamic>>[];
    
    for (int i = 0; i < sentences.length; i++) {
      final sentence = sentences[i];
      final words = _extractWords(sentence);
      
      double score = 0;
      
      // نقاط بناءً على تكرار الكلمات
      for (final word in words) {
        score += wordFreq[word] ?? 0;
      }
      
      // تطبيع النقاط حسب طول الجملة
      if (words.isNotEmpty) {
        score = score / words.length;
      }
      
      // نقاط إضافية للجمل في البداية والنهاية
      if (i == 0) score *= 1.2; // الجملة الأولى
      if (i == sentences.length - 1) score *= 1.1; // الجملة الأخيرة
      
      // نقاط إضافية للجمل التي تحتوي على كلمات مهمة
      if (_containsImportantWords(sentence)) {
        score *= 1.3;
      }
      
      scoredSentences.add({
        'sentence': sentence,
        'score': score,
        'index': i,
      });
    }
    
    return scoredSentences;
  }

  List<String> _extractWords(String sentence) {
    return sentence
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\u0600-\u06FF\s]'), '')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2)
        .where((word) => !_isStopWord(word))
        .toList();
  }

  bool _isStopWord(String word) {
    // كلمات الإيقاف الشائعة بالعربية والإنجليزية
    const stopWords = {
      // عربي
      'في', 'من', 'إلى', 'على', 'عن', 'مع', 'هذا', 'هذه', 'ذلك', 'تلك',
      'التي', 'الذي', 'كان', 'كانت', 'يكون', 'تكون', 'هو', 'هي',
      'أن', 'إن', 'كما', 'لكن', 'ولكن', 'أو', 'أم', 'بل', 'لا', 'ما',
      'قد', 'لقد', 'كل', 'بعض', 'جميع', 'كلا', 'كلتا', 'أي', 'أية',
      // إنجليزي
      'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
      'of', 'with', 'by', 'is', 'are', 'was', 'were', 'be', 'been', 'have',
      'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should',
      'this', 'that', 'these', 'those', 'i', 'you', 'he', 'she', 'it', 'we',
      'they', 'me', 'him', 'us', 'them', 'my', 'your', 'his',
      'its', 'our', 'their',
    };
    
    return stopWords.contains(word.toLowerCase());
  }

  bool _containsImportantWords(String sentence) {
    // كلمات مهمة تدل على أهمية الجملة
    const importantWords = {
      // عربي
      'مهم', 'أساسي', 'رئيسي', 'خلاصة', 'نتيجة', 'استنتاج', 'خاتمة',
      'ملخص', 'أولاً', 'ثانياً', 'أخيراً', 'بالتالي', 'لذلك', 'إذن',
      'يجب', 'ينبغي', 'ضروري', 'مطلوب', 'هدف', 'غرض', 'سبب',
      // إنجليزي
      'important', 'essential', 'key', 'main', 'primary', 'summary', 'conclusion',
      'result', 'therefore', 'thus', 'however', 'moreover', 'furthermore',
      'first', 'second', 'finally', 'lastly', 'must', 'should', 'required',
      'necessary', 'objective', 'goal', 'purpose', 'reason', 'because',
    };
    
    final words = sentence.toLowerCase().split(RegExp(r'\s+'));
    return words.any((word) => importantWords.contains(word));
  }

  Future<Map<String, dynamic>> generateSummaryWithStats(String text) async {
    final originalLength = text.length;
    final originalSentences = _splitIntoSentences(text).length;
    final originalWords = _extractWords(text).length;
    
    final summary = await summarizeText(text);
    
    final summaryLength = summary.length;
    final summarySentences = _splitIntoSentences(summary).length;
    final summaryWords = _extractWords(summary).length;
    
    final compressionRatio = originalLength > 0 ? (summaryLength / originalLength) : 0;
    
    return {
      'summary': summary,
      'originalStats': {
        'characters': originalLength,
        'sentences': originalSentences,
        'words': originalWords,
      },
      'summaryStats': {
        'characters': summaryLength,
        'sentences': summarySentences,
        'words': summaryWords,
      },
      'compressionRatio': compressionRatio,
      'reductionPercentage': ((1 - compressionRatio) * 100).round(),
    };
  }

  Future<List<String>> extractKeyPoints(String text, {int maxPoints = 5}) async {
    final sentences = _splitIntoSentences(text);
    final scoredSentences = _scoreSentences(sentences);
    
    // ترتيب حسب النقاط
    scoredSentences.sort((a, b) => b['score'].compareTo(a['score']));
    
    // استخراج النقاط الرئيسية
    return scoredSentences
        .take(maxPoints)
        .map((s) => '• ${s['sentence']}')
        .toList();
  }

  Future<String> generateTitle(String text) async {
    final sentences = _splitIntoSentences(text);
    if (sentences.isEmpty) return 'مستند بدون عنوان';
    
    // استخدام الجملة الأولى أو أهم جملة كعنوان
    final scoredSentences = _scoreSentences(sentences);
    scoredSentences.sort((a, b) => b['score'].compareTo(a['score']));
    
    String title = scoredSentences.first['sentence'];
    
    // تقصير العنوان إذا كان طويلاً
    if (title.length > 50) {
      final words = title.split(' ');
      title = words.take(8).join(' ');
      if (words.length > 8) title += '...';
    }
    
    return title;
  }
}

// نموذج لحفظ نتائج التلخيص
class SummaryResult {
  final String originalText;
  final String summary;
  final List<String> keyPoints;
  final String suggestedTitle;
  final Map<String, dynamic> stats;
  final DateTime createdAt;

  SummaryResult({
    required this.originalText,
    required this.summary,
    required this.keyPoints,
    required this.suggestedTitle,
    required this.stats,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'originalText': originalText,
      'summary': summary,
      'keyPoints': keyPoints,
      'suggestedTitle': suggestedTitle,
      'stats': stats,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SummaryResult.fromJson(Map<String, dynamic> json) {
    return SummaryResult(
      originalText: json['originalText'],
      summary: json['summary'],
      keyPoints: List<String>.from(json['keyPoints']),
      suggestedTitle: json['suggestedTitle'],
      stats: json['stats'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
