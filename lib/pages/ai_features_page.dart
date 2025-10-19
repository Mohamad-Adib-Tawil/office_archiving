import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:office_archiving/services/ocr_service.dart';
import 'package:office_archiving/services/translation_service.dart';
import 'package:office_archiving/services/ai_summarization_service.dart';
import 'package:image_picker/image_picker.dart';

class AIFeaturesPage extends StatefulWidget {
  const AIFeaturesPage({super.key});

  @override
  State<AIFeaturesPage> createState() => _AIFeaturesPageState();
}

class _AIFeaturesPageState extends State<AIFeaturesPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TranslationService _translationService;
  late AISummarizationService _summarizationService;
  late OCRService _ocrService;
  
  String _extractedText = '';
  String _translatedText = '';
  String _summary = '';
  bool _isProcessing = false;

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
    _animationController.forward();
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
          title: const Text('اختر مصدر الصورة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('معرض الصور'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('الكاميرا'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
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
        
        final extractedText = await _ocrService.extractTextFromImage(imagePath);
        
        if (!mounted) return;
        setState(() {
          _extractedText = extractedText;
          _isProcessing = false;
        });
        
        HapticFeedback.mediumImpact();
        
        if (extractedText.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم استخراج النص بنجاح!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم اختيار صورة')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في استخراج النص: $e')),
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
          const SnackBar(
            content: Text('تم ترجمة النص بنجاح!'),
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
          SnackBar(content: Text('خطأ في الترجمة: $e')),
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
          const SnackBar(
            content: Text('تم تلخيص النص بنجاح!'),
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
          SnackBar(content: Text('خطأ في التلخيص: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ميزات الذكاء الاصطناعي'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFeatureCard(
                'استخراج النص من الصور',
                'قم بتحويل الصور إلى نص قابل للتحرير',
                Icons.text_fields,
                Colors.blue,
                _pickImageAndExtractText,
              ),
              const SizedBox(height: 16),
              if (_extractedText.isNotEmpty) ...[
                _buildResultCard('النص المستخرج', _extractedText, Colors.blue),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        'ترجمة النص',
                        Icons.translate,
                        Colors.green,
                        _translateText,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        'تلخيص النص',
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
                _buildResultCard('النص المترجم', _translatedText, Colors.green),
                const SizedBox(height: 16),
              ],
              if (_summary.isNotEmpty) ...[
                _buildResultCard('ملخص النص', _summary, Colors.orange),
                const SizedBox(height: 16),
              ],
              _buildFeaturesList(),
            ],
          ),
        ),
      ),
    );
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
              label: Text(_isProcessing ? 'جاري المعالجة...' : 'ابدأ'),
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
                    const SnackBar(content: Text('تم نسخ النص')),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('نسخ'),
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
            'ميزات الذكاء الاصطناعي المتاحة',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            '📷 استخراج النص من الصور',
            'تحويل الصور والمستندات الممسوحة إلى نص قابل للتحرير',
            true,
          ),
          _buildFeatureItem(
            '🌐 ترجمة المستندات',
            'ترجمة النصوص تلقائياً بين العربية والإنجليزية',
            true,
          ),
          _buildFeatureItem(
            '📝 تلخيص المستندات',
            'إنشاء ملخصات ذكية للنصوص الطويلة',
            true,
          ),
          _buildFeatureItem(
            '🤖 التنظيم الذكي',
            'اقتراحات تلقائية لتصنيف وتنظيم الملفات',
            false,
          ),
          _buildFeatureItem(
            '🔍 البحث الذكي',
            'البحث في محتوى الملفات والصور',
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
              child: const Text(
                'قريباً',
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
