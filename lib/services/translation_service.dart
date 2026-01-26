import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  // يمكن استخدام Google Translate API أو Microsoft Translator
  // هنا سأستخدم LibreTranslate كمثال مجاني
  static const String _baseUrl = 'https://libretranslate.de/translate';
  
  Future<String> translateText(String text, {
    String from = 'auto',
    String to = 'ar',
  }) async {
    if (text.trim().isEmpty) return text;

    try {
      // استخدام Google Translator المجاني
      final translator = GoogleTranslator();
      final result = await translator.translate(text, from: from, to: to);
      return result.text;
    } catch (e) {
      // في حالة فشل Google Translator، نحاول LibreTranslate
      try {
        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'q': text,
            'source': from,
            'target': to,
            'format': 'text',
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['translatedText'] ?? text;
        } else {
          throw Exception('فشل في الترجمة: ${response.statusCode}');
        }
      } catch (e2) {
        throw Exception('خطأ في الترجمة: $e');
      }
    }
  }

  Future<String> translateToArabic(String text) async {
    return await translateText(text, from: 'auto', to: 'ar');
  }

  Future<String> translateToEnglish(String text) async {
    return await translateText(text, from: 'auto', to: 'en');
  }

  Future<Map<String, String>> translateDocument(String documentText) async {
    try {
      // تقسيم النص إلى فقرات للترجمة
      final paragraphs = documentText.split('\n\n');
      final translations = <String, String>{};
      
      for (int i = 0; i < paragraphs.length; i++) {
        final paragraph = paragraphs[i].trim();
        if (paragraph.isNotEmpty) {
          final translated = await translateText(paragraph);
          translations['paragraph_$i'] = translated;
          
          // تأخير قصير لتجنب تجاوز حدود API
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      return translations;
    } catch (e) {
      throw Exception('فشل في ترجمة المستند: $e');
    }
  }

  Future<String> detectLanguage(String text) async {
    if (text.trim().isEmpty) return 'unknown';

    try {
      final response = await http.post(
        Uri.parse('https://libretranslate.de/detect'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'q': text.substring(0, text.length > 100 ? 100 : text.length),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data[0]['language'] ?? 'unknown';
        }
      }
      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  List<String> getSupportedLanguages() {
    return [
      'ar', // العربية
      'en', // الإنجليزية
      'es', // الإسبانية
      'fr', // الفرنسية
      'de', // الألمانية
      'it', // الإيطالية
      'pt', // البرتغالية
      'ru', // الروسية
      'zh', // الصينية
      'ja', // اليابانية
      'ko', // الكورية
      'tr', // التركية
      'fa', // الفارسية
      'ur', // الأردية
    ];
  }

  String getLanguageName(String code) {
    const languageNames = {
      'ar': 'العربية',
      'en': 'English',
      'es': 'Español',
      'fr': 'Français',
      'de': 'Deutsch',
      'it': 'Italiano',
      'pt': 'Português',
      'ru': 'Русский',
      'zh': '中文',
      'ja': '日本語',
      'ko': '한국어',
      'tr': 'Türkçe',
      'fa': 'فارسی',
      'ur': 'اردو',
    };
    return languageNames[code] ?? code.toUpperCase();
  }

  // ترجمة محلية بسيطة للكلمات الشائعة (بدون إنترنت)
  String translateOffline(String text, String targetLang) {
    final offlineDict = {
      'en_ar': {
        'document': 'مستند',
        'file': 'ملف',
        'image': 'صورة',
        'pdf': 'بي دي إف',
        'text': 'نص',
        'photo': 'صورة',
        'picture': 'صورة',
        'scan': 'مسح ضوئي',
        'receipt': 'إيصال',
        'invoice': 'فاتورة',
        'contract': 'عقد',
        'report': 'تقرير',
        'letter': 'رسالة',
        'certificate': 'شهادة',
        'passport': 'جواز سفر',
        'id': 'هوية',
        'license': 'رخصة',
      },
      'ar_en': {
        'مستند': 'document',
        'ملف': 'file',
        'صورة': 'image',
        'نص': 'text',
        'إيصال': 'receipt',
        'فاتورة': 'invoice',
        'عقد': 'contract',
        'تقرير': 'report',
        'رسالة': 'letter',
        'شهادة': 'certificate',
        'جواز سفر': 'passport',
        'هوية': 'id',
        'رخصة': 'license',
      }
    };

    final dictKey = targetLang == 'ar' ? 'en_ar' : 'ar_en';
    final dict = offlineDict[dictKey] ?? {};
    
    return dict[text.toLowerCase()] ?? text;
  }
}

// نموذج لحفظ نتائج الترجمة
class TranslationResult {
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final DateTime translatedAt;

  TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.translatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'originalText': originalText,
      'translatedText': translatedText,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
      'translatedAt': translatedAt.toIso8601String(),
    };
  }

  factory TranslationResult.fromJson(Map<String, dynamic> json) {
    return TranslationResult(
      originalText: json['originalText'],
      translatedText: json['translatedText'],
      sourceLanguage: json['sourceLanguage'],
      targetLanguage: json['targetLanguage'],
      translatedAt: DateTime.parse(json['translatedAt']),
    );
  }
}
