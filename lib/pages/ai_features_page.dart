import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:office_archiving/services/ocr_service.dart';
import 'package:office_archiving/services/translation_service.dart';
import 'package:office_archiving/services/ai_summarization_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:office_archiving/l10n/app_localizations.dart';
import 'package:office_archiving/services/smart_organization_service.dart';
import 'package:office_archiving/services/first_open_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

class AIFeaturesPage extends StatefulWidget {
  final String? initialText; // نص أولي يتم تمريره من المحرر الداخلي
  const AIFeaturesPage({super.key, this.initialText});

  @override
  State<AIFeaturesPage> createState() => _AIFeaturesPageState();
}

class _AIFeaturesPageState extends State<AIFeaturesPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TranslationService _translationService;
  late AISummarizationService _summarizationService;
  late OCRService _ocrService;
  final SmartOrganizationService _smartOrg = SmartOrganizationService();
  
  String _extractedText = '';
  String _translatedText = '';
  String _summary = '';
  bool _isProcessing = false;
  String _ocrLang = 'auto'; // 'auto' | 'ar' | 'en'
  bool _batchRunning = false;
  int _batchProcessed = 0;
  int _batchTotal = 0;
  OrganizationSuggestion? _orgSuggestion;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _translationService = TranslationService();
    _summarizationService = AISummarizationService();
    _ocrService = OCRService();
    // Animate only on first open
    Future.microtask(() async {
      final first = await FirstOpenService.isFirstOpen('ai_features_page');
      if (!mounted) return;
      if (first) {
        _animationController.forward();
      } else {
        _animationController.value = 1.0; // show content without animating
      }
    });
    // تهيئة النص المستخرج إن تم تمريره من شاشة أخرى (مثل المحرر الداخلي)
    if (widget.initialText != null && widget.initialText!.trim().isNotEmpty) {
      _extractedText = widget.initialText!.trim();
    }
    _loadSavedApiKey();
  }

  Future<void> _pickPdfAndExtractText() async {
    try {
      setState(() {
        _isProcessing = true;
        _extractedText = '';
      });

      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (res == null || res.files.isEmpty || res.files.first.path == null) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        return;
      }
      final path = res.files.first.path!;

      final text = await _ocrService.recognizePdfToText(path, lang: _ocrLang);

      if (!mounted) return;
      setState(() {
        _extractedText = text;
        _isProcessing = false;
      });
      if (text.trim().isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).snack_extraction_done), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).generic_error}: $e')),
      );
    }
  }

  Future<void> _runBatchOcr() async {
    if (_batchRunning) return;
    setState(() {
      _batchRunning = true;
      _batchProcessed = 0;
      _batchTotal = 0;
    });
    try {
      final count = await _ocrService.batchProcessMissingOcr(
        lang: _ocrLang,
        onProgress: (p, t) {
          if (!mounted) return;
          setState(() {
            _batchProcessed = p;
            _batchTotal = t;
          });
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تمت معالجة $count عنصر OCR')), // static Arabic text
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).generic_error}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _batchRunning = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    // _translationService.dispose(); // No dispose method
    // _summarizationService.dispose(); // No dispose method
    super.dispose();
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).choose_image_source),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(AppLocalizations.of(context).from_gallery),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(AppLocalizations.of(context).from_camera),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context).cancel),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImageAndExtractText() async {
    try {
      String? imagePath;

      // عرض خيارات للمستخدم
      final source = await _showImageSourceDialog();
      if (source == null) return;

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      
      if (image != null) {
        imagePath = image.path;
      }

      if (imagePath != null) {
        setState(() {
          _isProcessing = true;
          _extractedText = '';
        });
        
        HapticFeedback.lightImpact();
        
        final extractedText = await _ocrService.recognizeTextAdvanced(
          imagePath,
          lang: _ocrLang,
        );
        
        if (!mounted) return;
        setState(() {
          _extractedText = extractedText;
          _isProcessing = false;
        });
        
        HapticFeedback.mediumImpact();
        
        if (extractedText.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).snack_extraction_done),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).no_image_selected)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).generic_error}: $e')),
        );
      }
    }
  }

  Future<void> _translateText() async {
    if (_extractedText.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final translated = await _translationService.translateToArabic(_extractedText);
      setState(() {
        _translatedText = translated;
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).snack_translation_done),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).generic_error}: $e')),
        );
      }
    }
  }

  Future<void> _summarizeText() async {
    if (_extractedText.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final summary = await _summarizationService.summarizeText(_extractedText);
      setState(() {
        _summary = summary;
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).snack_summary_done),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).generic_error}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).ai_features_title),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'مفتاح Hugging Face (اختياري)',
            icon: Icon(
              Icons.vpn_key_outlined,
              color: _summarizationService.hasApiKey 
                ? Colors.green 
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            onPressed: _showApiKeyDialog,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رسالة ترحيبية
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context).ai_features_title,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).ai_info_desc,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // لغة OCR: تلقائي / العربية / الإنجليزية
              Text(
                AppLocalizations.of(context).ocr_language,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(AppLocalizations.of(context).ocr_auto),
                    selected: _ocrLang == 'auto',
                    onSelected: (v) {
                      if (!v) return;
                      setState(() => _ocrLang = 'auto');
                      HapticFeedback.selectionClick();
                    },
                  ),
                  ChoiceChip(
                    label: Text(AppLocalizations.of(context).ocr_arabic),
                    selected: _ocrLang == 'ar',
                    onSelected: (v) {
                      if (!v) return;
                      setState(() => _ocrLang = 'ar');
                      HapticFeedback.selectionClick();
                    },
                  ),
                  ChoiceChip(
                    label: Text(AppLocalizations.of(context).ocr_english),
                    selected: _ocrLang == 'en',
                    onSelected: (v) {
                      if (!v) return;
                      setState(() => _ocrLang = 'en');
                      HapticFeedback.selectionClick();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                AppLocalizations.of(context).ai_extract_title,
                AppLocalizations.of(context).ai_extract_desc,
                Icons.text_fields,
                Colors.blue,
                _pickImageAndExtractText,
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                AppLocalizations.of(context).pdf_ocr_title,
                AppLocalizations.of(context).pdf_ocr_desc,
                Icons.picture_as_pdf,
                Colors.red,
                _pickPdfAndExtractText,
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                AppLocalizations.of(context).batch_ocr_title,
                _batchRunning
                    ? '${AppLocalizations.of(context).ocr_processing} $_batchProcessed/$_batchTotal'
                    : AppLocalizations.of(context).batch_ocr_desc,
                Icons.task,
                Colors.purple,
                _runBatchOcr,
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                AppLocalizations.of(context).ai_feature_smart_organize_title,
                AppLocalizations.of(context).ai_feature_smart_organize_desc,
                Icons.auto_awesome,
                Colors.teal,
                _runSmartOrganization,
              ),
              const SizedBox(height: 16),
              if (_extractedText.isNotEmpty) ...[
                _buildResultCard(AppLocalizations.of(context).ai_extracted_text_title, _extractedText, Colors.blue),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        AppLocalizations.of(context).ai_translate_action,
                        Icons.translate,
                        Colors.green,
                        _translateText,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        AppLocalizations.of(context).ai_summary_action,
                        Icons.summarize,
                        Colors.orange,
                        _summarizeText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              if (_translatedText.isNotEmpty) ...[
                _buildResultCard(AppLocalizations.of(context).ai_translated_text_title, _translatedText, Colors.green),
                const SizedBox(height: 16),
              ],
              if (_summary.isNotEmpty) ...[
                _buildResultCard(AppLocalizations.of(context).ai_summary_text_title, _summary, Colors.orange),
                const SizedBox(height: 16),
              ],
              if (_orgSuggestion != null) ...[
                _buildOrgResultCard(_orgSuggestion!),
                const SizedBox(height: 16),
              ],
              _buildFeaturesList(),
            ],
          ),
        ),
      ),
    );
  }

  // بطاقة نتيجة التنظيم الذكي
  Widget _buildOrgResultCard(OrganizationSuggestion s) {
    final chips = s.suggestedTags.map((t) => Chip(label: Text(t))).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('نتيجة التنظيم الذكي', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
          const SizedBox(height: 8),
          Text('الاسم المقترح: ${s.suggestedName}'),
          Text('التصنيف: ${s.suggestedCategory}'),
          Text('الأولوية: ${s.priority} • الثقة: ${(s.confidence * 100).toStringAsFixed(0)}%'),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: chips),
          const SizedBox(height: 8),
          Text('المبررات: ${s.reasoning}'),
        ],
      ),
    );
  }

  // تشغيل التنظيم الذكي
  Future<void> _runSmartOrganization() async {
    try {
      setState(() => _isProcessing = true);
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'txt'],
      );
      if (res == null || res.files.isEmpty || res.files.first.path == null) {
        if (mounted) setState(() => _isProcessing = false);
        return;
      }
      final path = res.files.first.path!;
      final name = p.basename(path);
      final suggestion = await _smartOrg.suggestOrganization(path, name);
      if (!mounted) return;
      setState(() {
        _orgSuggestion = suggestion;
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء اقتراح التنظيم')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).generic_error}: $e')),
      );
    }
  }

  // إدارة مفتاح API
  Future<void> _loadSavedApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('huggingface_api_key');
    _summarizationService.setApiKey(saved);
  }

  Future<void> _showApiKeyDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final initial = prefs.getString('huggingface_api_key') ?? '';
    final controller = TextEditingController(text: initial);
    final key = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('إعداد مفتاح Hugging Face (اختياري)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ملاحظة: جميع الميزات تعمل بدون مفتاح API، لكن مع مفتاح ستحصل على تلخيص أفضل للنصوص الطويلة.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Bearer Token (اختياري)',
                  hintText: 'hf_...',
                  helperText: 'اتركه فارغاً للاستخدام المحلي فقط',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, null), child: Text(AppLocalizations.of(context).cancel)),
            TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text(AppLocalizations.of(context).ok_action)),
          ],
        );
      },
    );
    if (key == null) return;
    await prefs.setString('huggingface_api_key', key);
    _summarizationService.setApiKey(key);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ مفتاح API')));
  }

  Widget _buildFeatureCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : onTap,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(icon),
              label: Text(_isProcessing
                  ? AppLocalizations.of(context).processing_ellipsis
                  : AppLocalizations.of(context).start_action),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(String title, String content, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              content,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context).snack_copy_done)),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: Text(AppLocalizations.of(context).copy_action),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: _isProcessing ? null : onTap,
      icon: Icon(icon),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).ai_features_list_title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            AppLocalizations.of(context).ai_feature_extract_title,
            AppLocalizations.of(context).ai_feature_extract_desc,
            true,
          ),
          _buildFeatureItem(
            AppLocalizations.of(context).ai_feature_translate_title,
            AppLocalizations.of(context).ai_feature_translate_desc,
            true,
          ),
          _buildFeatureItem(
            AppLocalizations.of(context).ai_feature_summarize_title,
            AppLocalizations.of(context).ai_feature_summarize_desc,
            true,
          ),
          _buildFeatureItem(
            AppLocalizations.of(context).ai_feature_smart_organize_title,
            AppLocalizations.of(context).ai_feature_smart_organize_desc,
            true,
          ),
          _buildFeatureItem(
            AppLocalizations.of(context).ai_feature_smart_search_title,
            AppLocalizations.of(context).ai_feature_smart_search_desc,
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description, bool isAvailable) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: isAvailable ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isAvailable ? null : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          if (!isAvailable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                AppLocalizations.of(context).coming_soon,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
