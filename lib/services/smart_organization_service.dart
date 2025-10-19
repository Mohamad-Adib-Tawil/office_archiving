import 'dart:io';
import 'package:office_archiving/services/ocr_service.dart';

class SmartOrganizationService {
  static final SmartOrganizationService _instance = SmartOrganizationService._internal();
  factory SmartOrganizationService() => _instance;
  SmartOrganizationService._internal();

  final OCRService _ocrService = OCRService();

  // اقتراح تصنيف للملف بناءً على محتواه
  Future<OrganizationSuggestion> suggestOrganization(String filePath, String fileName) async {
    try {
      String content = '';
      
      // استخراج المحتوى حسب نوع الملف
      if (_isImageFile(filePath)) {
        content = await _ocrService.extractTextFromImage(filePath);
      } else if (_isTextFile(filePath)) {
        content = await File(filePath).readAsString();
      }
      
      // تحليل المحتوى واقتراح التصنيف
      final category = _categorizeContent(content, fileName);
      final tags = await _generateTags(content, fileName);
      final suggestedName = _generateSuggestedName(content, fileName);
      final priority = _calculatePriority(content, fileName);
      
      return OrganizationSuggestion(
        originalFileName: fileName,
        suggestedName: suggestedName,
        suggestedCategory: category,
        suggestedTags: tags,
        priority: priority,
        confidence: _calculateConfidence(content, category),
        reasoning: _generateReasoning(content, category, tags),
      );
    } catch (e) {
      return _fallbackSuggestion(fileName);
    }
  }

  String _getFileType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return extension;
  }

  bool _isImageFile(String filePath) {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'tiff'];
    final extension = _getFileType(filePath);
    return imageExtensions.contains(extension);
  }

  bool _isTextFile(String filePath) {
    const textExtensions = ['txt', 'md', 'rtf'];
    final extension = _getFileType(filePath);
    return textExtensions.contains(extension);
  }

  String _categorizeContent(String content, String fileName) {
    final contentLower = content.toLowerCase();
    final fileNameLower = fileName.toLowerCase();
    
    final categories = {
      'المستندات الرسمية': [
        'شهادة', 'certificate', 'رخصة', 'license', 'جواز', 'passport',
        'هوية', 'id', 'بطاقة', 'card', 'وثيقة', 'document'
      ],
      'الفواتير والإيصالات': [
        'فاتورة', 'invoice', 'إيصال', 'receipt', 'دفع', 'payment',
        'مبلغ', 'amount', 'ريال', 'sar', 'دولار', 'dollar'
      ],
      'العقود والاتفاقيات': [
        'عقد', 'contract', 'اتفاقية', 'agreement', 'شروط', 'terms',
        'بنود', 'clauses', 'توقيع', 'signature'
      ],
      'التقارير': [
        'تقرير', 'report', 'تحليل', 'analysis', 'نتائج', 'results',
        'إحصائيات', 'statistics', 'بيانات', 'data'
      ],
      'الصور الشخصية': [
        'صورة', 'photo', 'شخصية', 'personal', 'عائلة', 'family',
        'ذكريات', 'memories'
      ],
      'المراسلات': [
        'رسالة', 'letter', 'إيميل', 'email', 'مراسلة', 'correspondence',
        'رد', 'reply', 'مرسل', 'sender'
      ],
      'الدراسة والتعليم': [
        'دراسة', 'study', 'تعليم', 'education', 'جامعة', 'university',
        'مدرسة', 'school', 'درجة', 'grade', 'امتحان', 'exam'
      ],
      'العمل': [
        'عمل', 'work', 'وظيفة', 'job', 'شركة', 'company',
        'مشروع', 'project', 'اجتماع', 'meeting'
      ],
      'الصحة': [
        'طبي', 'medical', 'صحة', 'health', 'مستشفى', 'hospital',
        'طبيب', 'doctor', 'دواء', 'medicine', 'تحليل', 'test'
      ],
      'المالية': [
        'بنك', 'bank', 'حساب', 'account', 'استثمار', 'investment',
        'قرض', 'loan', 'تأمين', 'insurance'
      ]
    };
    
    String bestCategory = 'عام';
    int maxMatches = 0;
    
    for (final category in categories.entries) {
      int matches = 0;
      for (final keyword in category.value) {
        if (contentLower.contains(keyword) || fileNameLower.contains(keyword)) {
          matches++;
        }
      }
      if (matches > maxMatches) {
        maxMatches = matches;
        bestCategory = category.key;
      }
    }
    
    return bestCategory;
  }

  Future<List<String>> _generateTags(String content, String fileName) async {
    final tags = <String>[];
    
    // استخراج التاريخ
    final dateRegex = RegExp(r'\d{4}[-/]\d{1,2}[-/]\d{1,2}|\d{1,2}[-/]\d{1,2}[-/]\d{4}');
    if (dateRegex.hasMatch(content) || dateRegex.hasMatch(fileName)) {
      tags.add('مؤرخ');
    }
    
    // استخراج الأرقام المهمة
    final numberRegex = RegExp(r'\d+');
    if (numberRegex.hasMatch(content)) {
      tags.add('يحتوي على أرقام');
    }
    
    // تحديد اللغة
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(content)) {
      tags.add('عربي');
    }
    if (RegExp(r'[a-zA-Z]').hasMatch(content)) {
      tags.add('إنجليزي');
    }
    
    // تحديد نوع الملف
    final extension = _getFileType(fileName);
    tags.add(extension.toUpperCase());
    
    // كلمات مفتاحية من المحتوى
    if (content.isNotEmpty) {
      final keywords = await _ocrService.extractKeywords(fileName);
      tags.addAll(keywords.take(3));
    }
    
    return tags;
  }

  String _generateSuggestedName(String content, String fileName) {
    // محاولة استخراج عنوان من المحتوى
    if (content.isNotEmpty) {
      final lines = content.split('\n');
      for (final line in lines) {
        if (line.trim().length > 10 && line.trim().length < 50) {
          return _cleanFileName(line.trim());
        }
      }
    }
    
    // إذا لم نجد عنوان مناسب، استخدم اسم الملف الأصلي مع تحسينات
    return _cleanFileName(fileName.split('.').first);
  }

  String _cleanFileName(String name) {
    // تنظيف اسم الملف
    return name
        .replaceAll(RegExp(r'[^\w\u0600-\u06FF\s-_.]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  int _calculatePriority(String content, String fileName) {
    int priority = 1; // أولوية منخفضة افتراضياً
    
    // كلمات تدل على أولوية عالية
    const highPriorityWords = [
      'عاجل', 'urgent', 'مهم', 'important', 'ضروري', 'critical',
      'جواز', 'passport', 'هوية', 'id', 'رخصة', 'license'
    ];
    
    const mediumPriorityWords = [
      'فاتورة', 'invoice', 'عقد', 'contract', 'تقرير', 'report'
    ];
    
    final contentLower = content.toLowerCase();
    final fileNameLower = fileName.toLowerCase();
    
    for (final word in highPriorityWords) {
      if (contentLower.contains(word) || fileNameLower.contains(word)) {
        priority = 3; // أولوية عالية
        break;
      }
    }
    
    if (priority == 1) {
      for (final word in mediumPriorityWords) {
        if (contentLower.contains(word) || fileNameLower.contains(word)) {
          priority = 2; // أولوية متوسطة
          break;
        }
      }
    }
    
    return priority;
  }

  double _calculateConfidence(String content, String category) {
    if (content.isEmpty) return 0.3;
    if (category == 'عام') return 0.5;
    return 0.8; // ثقة عالية إذا تم تصنيف المحتوى
  }

  String _generateReasoning(String content, String category, List<String> tags) {
    final reasons = <String>[];
    
    if (category != 'عام') {
      reasons.add('تم تصنيفه كـ "$category" بناءً على المحتوى');
    }
    
    if (tags.isNotEmpty) {
      reasons.add('العلامات المقترحة: ${tags.take(3).join(', ')}');
    }
    
    if (content.isNotEmpty) {
      reasons.add('تم تحليل المحتوى النصي');
    }
    
    return reasons.join('. ');
  }

  OrganizationSuggestion _fallbackSuggestion(String fileName) {
    final extension = _getFileType(fileName);
    String category = 'عام';
    
    // تصنيف بسيط بناءً على امتداد الملف
    if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
      category = 'الصور';
    } else if (['pdf'].contains(extension)) {
      category = 'المستندات';
    } else if (['doc', 'docx', 'txt'].contains(extension)) {
      category = 'النصوص';
    }
    
    return OrganizationSuggestion(
      originalFileName: fileName,
      suggestedName: fileName,
      suggestedCategory: category,
      suggestedTags: [extension.toUpperCase()],
      priority: 1,
      confidence: 0.3,
      reasoning: 'تصنيف بسيط بناءً على نوع الملف',
    );
  }

  // اقتراح إعادة تنظيم شامل للأرشيف
  Future<List<OrganizationRecommendation>> suggestArchiveReorganization(
    List<Map<String, dynamic>> allFiles
  ) async {
    final recommendations = <OrganizationRecommendation>[];
    
    // تجميع الملفات حسب النوع
    final filesByType = <String, List<Map<String, dynamic>>>{};
    for (final file in allFiles) {
      final extension = _getFileType(file['filePath']);
      filesByType[extension] = (filesByType[extension] ?? [])..add(file);
    }
    
    // اقتراحات لكل نوع ملف
    for (final entry in filesByType.entries) {
      if (entry.value.length >= 3) {
        recommendations.add(OrganizationRecommendation(
          type: 'group_by_type',
          title: 'تجميع ملفات ${entry.key.toUpperCase()}',
          description: 'يمكن تجميع ${entry.value.length} ملف من نوع ${entry.key} في قسم منفصل',
          affectedFiles: entry.value.map((f) => f['name'].toString()).toList(),
          priority: entry.value.length > 10 ? 3 : 2,
        ));
      }
    }
    
    // اقتراح حذف الملفات المكررة
    final duplicates = await _findDuplicateFiles(allFiles);
    if (duplicates.isNotEmpty) {
      recommendations.add(OrganizationRecommendation(
        type: 'remove_duplicates',
        title: 'حذف الملفات المكررة',
        description: 'تم العثور على ${duplicates.length} ملف مكرر يمكن حذفه لتوفير المساحة',
        affectedFiles: duplicates,
        priority: 3,
      ));
    }
    
    return recommendations;
  }

  Future<List<String>> _findDuplicateFiles(List<Map<String, dynamic>> files) async {
    final duplicates = <String>[];
    final seenNames = <String, String>{};
    
    for (final file in files) {
      final name = file['name'].toString();
      if (seenNames.containsKey(name)) {
        duplicates.add(name);
      } else {
        seenNames[name] = file['filePath'];
      }
    }
    
    return duplicates;
  }
}

// نماذج البيانات
class OrganizationSuggestion {
  final String originalFileName;
  final String suggestedName;
  final String suggestedCategory;
  final List<String> suggestedTags;
  final int priority; // 1=منخفض, 2=متوسط, 3=عالي
  final double confidence; // 0.0-1.0
  final String reasoning;

  OrganizationSuggestion({
    required this.originalFileName,
    required this.suggestedName,
    required this.suggestedCategory,
    required this.suggestedTags,
    required this.priority,
    required this.confidence,
    required this.reasoning,
  });

  Map<String, dynamic> toJson() {
    return {
      'originalFileName': originalFileName,
      'suggestedName': suggestedName,
      'suggestedCategory': suggestedCategory,
      'suggestedTags': suggestedTags,
      'priority': priority,
      'confidence': confidence,
      'reasoning': reasoning,
    };
  }
}

class OrganizationRecommendation {
  final String type;
  final String title;
  final String description;
  final List<String> affectedFiles;
  final int priority;

  OrganizationRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.affectedFiles,
    required this.priority,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'affectedFiles': affectedFiles,
      'priority': priority,
    };
  }
}
