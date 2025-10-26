import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:office_archiving/service/sqlite_service.dart';
import 'package:intl/intl.dart';

/// صفحة الماسح الاحترافي باستخدام flutter_doc_scanner
/// تجربة احترافية مشابهة لـ CamScanner مع:
/// • كشف تلقائي للحواف (Auto Edge Detection)
/// • قص ذكي للمستندات (Smart Crop)
/// • فلاتر متقدمة (Black & White, Gray, Enhance, Original)
/// • دعم مسح متعدد الصفحات (Multi-Page Scanning)
/// • حفظ دائم في قاعدة البيانات داخل الأقسام فقط
/// • منع أي عملية مسح بدون قسم صالح
class FlutterDocScannerPage extends StatefulWidget {
  final int sectionId;
  final String sectionName;
  final bool multiPage;
  
  const FlutterDocScannerPage({
    super.key,
    required this.sectionId,
    required this.sectionName,
    this.multiPage = false,
  });

  @override
  State<FlutterDocScannerPage> createState() => _FlutterDocScannerPageState();
}

class _FlutterDocScannerPageState extends State<FlutterDocScannerPage> 
    with SingleTickerProviderStateMixin {
  
  final List<String> _scannedPages = [];
  bool _isScanning = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // إعداد الأنيميشن
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _animationController.forward();
    
    // بدء المسح تلقائياً
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScanning();
    });
  }
  

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// بدء عملية المسح
  Future<void> _startScanning() async {
    if (_isScanning) return;
    
    setState(() => _isScanning = true);
    
    try {
      // طلب الصلاحيات أولاً
      await _requestPermissions();
      
      // فتح الماسح مع الإعدادات الاحترافية
      final scannedDocuments = await FlutterDocScanner().getScanDocuments(
        // عدد الصفحات المسموح بها (4 صفحات كحد أقصى)
        page: widget.multiPage ? 4 : 1,
      );
      
      if (scannedDocuments != null && scannedDocuments is List) {
        // حفظ الصور الممسوحة
        for (var doc in scannedDocuments) {
          if (doc is String && doc.isNotEmpty) {
            _scannedPages.add(doc);
          }
        }
        
        if (_scannedPages.isNotEmpty) {
          setState(() {});
          // حفظ مباشرة في القسم المحدد
          await _saveToSection();
        } else {
          // لا توجد صفحات، إغلاق الصفحة
          if (mounted) {
            Navigator.pop(context);
          }
        }
      }
    } on PlatformException catch (e) {
      debugPrint('خطأ في المسح: ${e.message}');
      _showErrorDialog('فشل المسح: ${e.message}');
    } catch (e) {
      debugPrint('خطأ غير متوقع: $e');
      _showErrorDialog('حدث خطأ غير متوقع');
    } finally {
      setState(() => _isScanning = false);
    }
  }

  /// طلب الصلاحيات المطلوبة
  Future<void> _requestPermissions() async {
    // المكتبة تتعامل مع الصلاحيات تلقائياً
    // لكن يمكن إضافة فحص إضافي هنا إذا لزم الأمر
  }

  /// حفظ المستندات الممسوحة في القسم
  Future<void> _saveToSection() async {
    if (_scannedPages.isEmpty) {
      _showErrorDialog('لا توجد مستندات للحفظ');
      return;
    }
    
    // عرض حوار تأكيد
    final confirmed = await _showSaveConfirmationDialog();
    if (confirmed != true) {
      // المستخدم ألغى، حذف الملفات المؤقتة
      await _cleanupTempFiles();
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }
    
    try {
      final db = DatabaseService.instance;
      final dir = await getApplicationDocumentsDirectory();
      final scansDir = Directory('${dir.path}/scans');
      
      if (!await scansDir.exists()) {
        await scansDir.create(recursive: true);
      }
      
      final List<String> savedPaths = [];
      
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      
      for (int i = 0; i < _scannedPages.length; i++) {
        final sourcePath = _scannedPages[i];
        final timestamp = now.millisecondsSinceEpoch;
        final fileName = 'scan_${timestamp}_$i.jpg';
        final destPath = '${scansDir.path}/$fileName';
        
        // نسخ الملف إلى مجلد التطبيق الدائم
        await File(sourcePath).copy(destPath);
        
        // اسم احترافي للمستند
        final docName = _scannedPages.length == 1
            ? 'مستند ${widget.sectionName} $dateStr'
            : 'مستند ${widget.sectionName} $dateStr (${i + 1})';
        
        // حفظ في قاعدة البيانات مع التاريخ
        await db.insertItem(
          docName,
          destPath,
          'image',
          widget.sectionId,
          createdAt: now.toIso8601String(),
        );
        
        savedPaths.add(destPath);
      }
      
      // حذف الملفات المؤقتة
      await _cleanupTempFiles();
      
      if (mounted) {
        // عرض رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حفظ ${_scannedPages.length} ${_scannedPages.length == 1 ? "مستند" : "مستندات"} بنجاح في قسم "${widget.sectionName}" ✅',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        Navigator.pop(context, savedPaths);
      }
    } catch (e) {
      debugPrint('خطأ في الحفظ: $e');
      _showErrorDialog('فشل حفظ المستندات');
    }
  }

  /// عرض حوار تأكيد الحفظ
  Future<bool?> _showSaveConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.save_outlined, color: Colors.blue, size: 28),
            SizedBox(width: 12),
            Text('تأكيد الحفظ'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تم مسح ${_scannedPages.length} ${_scannedPages.length == 1 ? 'مستند' : 'مستندات'}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.folder,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'سيتم الحفظ في:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          widget.sectionName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'هل تريد حفظ المستندات في هذا القسم؟',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check),
            label: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
  
  /// حذف الملفات المؤقتة
  Future<void> _cleanupTempFiles() async {
    try {
      for (final path in _scannedPages) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('خطأ في حذف الملفات المؤقتة: $e');
    }
  }

  /// عرض رسالة خطأ
  void _showErrorDialog(String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('خطأ'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _startScanning();
            },
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  /// حذف صفحة ممسوحة
  void _deletePage(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الصفحة'),
        content: const Text('هل تريد حذف هذه الصفحة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _scannedPages.removeAt(index));
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('ماسح المستندات الاحترافي'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_scannedPages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'حفظ',
              onPressed: _saveToSection,
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _scannedPages.isEmpty
            ? _buildEmptyState(colorScheme)
            : _buildScannedPages(colorScheme),
      ),
      floatingActionButton: _isScanning
          ? null
          : FloatingActionButton.extended(
              onPressed: _startScanning,
              icon: const Icon(Icons.document_scanner),
              label: Text(_scannedPages.isEmpty ? 'بدء المسح' : 'مسح صفحة جديدة'),
              elevation: 4,
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /// بناء حالة فارغة
  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة كبيرة
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.document_scanner,
                size: 80,
                color: colorScheme.primary,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // العنوان
            Text(
              'ماسح مستندات احترافي',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // الوصف
            Text(
              'اضغط على زر "بدء المسح" لالتقاط مستند بجودة احترافية مع:\n'
              '• كشف تلقائي للحواف\n'
              '• قص ذكي للمستند\n'
              '• فلاتر متعددة (أبيض/أسود، رمادي، ملون)\n'
              '• تعديل يدوي للحواف',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // معلومات إضافية
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'تجربة مشابهة لـ CamScanner',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء قائمة الصفحات الممسوحة
  Widget _buildScannedPages(ColorScheme colorScheme) {
    return Column(
      children: [
        // عنوان القائمة
        Container(
          padding: const EdgeInsets.all(16),
          color: colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'تم مسح ${_scannedPages.length} ${_scannedPages.length == 1 ? 'صفحة' : 'صفحات'}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (_scannedPages.length > 1)
                TextButton.icon(
                  onPressed: () {
                    setState(() => _scannedPages.clear());
                  },
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: const Text('حذف الكل'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
            ],
          ),
        ),
        
        // قائمة الصفحات
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _scannedPages.length,
            itemBuilder: (context, index) {
              return _buildPageCard(index, colorScheme);
            },
          ),
        ),
        
        // شريط الإجراءات السفلي
        const SizedBox(height: 80), // مساحة للـ FAB
      ],
    );
  }

  /// بناء بطاقة صفحة ممسوحة
  Widget _buildPageCard(int index, ColorScheme colorScheme) {
    final path = _scannedPages[index];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // عرض الصورة بحجم كامل
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _FullImageView(imagePath: path),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // معاينة الصورة
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(path),
                  width: 80,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 100,
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.broken_image,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(width: 16),
              
              // معلومات الصفحة
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'صفحة ${index + 1}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'اضغط للعرض بحجم كامل',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              // زر الحذف
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
                tooltip: 'حذف',
                onPressed: () => _deletePage(index),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شاشة عرض الصورة بحجم كامل
class _FullImageView extends StatelessWidget {
  final String imagePath;
  
  const _FullImageView({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
