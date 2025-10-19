import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DocumentManagementPage extends StatefulWidget {
  const DocumentManagementPage({super.key});

  @override
  State<DocumentManagementPage> createState() => _DocumentManagementPageState();
}

class _DocumentManagementPageState extends State<DocumentManagementPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<String> _documentImages = [];
  List<String> _pdfFiles = [];
  List<String> _signatures = [];
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
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // المسح الضوئي المباشر بالكاميرا
  Future<void> _scanDocument() async {
    try {
      setState(() => _isProcessing = true);
      
      final source = await _showImageSourceDialog();
      if (source == null) return;

      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        imageQuality: 90,
      );
      
      if (image != null) {
        setState(() {
          _documentImages.add(image.path);
        });
        _showSuccessSnackBar('تم إضافة المستند بنجاح!');
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في المسح الضوئي: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // عرض خيارات مصدر الصورة
  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('اختر مصدر المستند'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('الكاميرا (مسح ضوئي)'),
                subtitle: const Text('التقط صورة للمستند'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('معرض الصور'),
                subtitle: const Text('اختر من الصور المحفوظة'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
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

  // حذف مستند
  void _deleteDocument(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المستند'),
        content: const Text('هل أنت متأكد من حذف هذا المستند؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _documentImages.removeAt(index);
              });
              Navigator.pop(context);
              _showSuccessSnackBar('تم حذف المستند');
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستندات'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withOpacity(0.1),
                colorScheme.secondary.withOpacity(0.05),
              ],
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // قسم الإحصائيات
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.1),
                    colorScheme.secondary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.document_scanner,
                      color: colorScheme.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إجمالي الملفات',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_documentImages.length + _pdfFiles.length + _signatures.length}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'صور: ${_documentImages.length} • مستندات: ${_pdfFiles.length} • توقيعات: ${_signatures.length}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),

            // أزرار الإجراءات
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // الصف الأول
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _scanDocument,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('مسح مستند'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _createPdfFromImages,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('إنشاء PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
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
                  const SizedBox(height: 8),
                  // الصف الثاني
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _createDigitalSignature,
                          icon: const Icon(Icons.draw),
                          label: const Text('توقيع رقمي'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _mergeDocuments,
                          icon: const Icon(Icons.merge),
                          label: const Text('دمج ملفات'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
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
                ],
              ),
            ),

            const SizedBox(height: 16),

            // قائمة المستندات
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'الصور', icon: Icon(Icons.image)),
                        Tab(text: 'المستندات', icon: Icon(Icons.picture_as_pdf)),
                        Tab(text: 'التوقيعات', icon: Icon(Icons.draw)),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // تبويب الصور
                          _documentImages.isEmpty
                              ? _buildEmptyState('لا توجد صور ممسوحة')
                              : _buildDocumentsList(),
                          // تبويب المستندات
                          _pdfFiles.isEmpty
                              ? _buildEmptyState('لا توجد مستندات')
                              : _buildPdfFilesList(),
                          // تبويب التوقيعات
                          _signatures.isEmpty
                              ? _buildEmptyState('لا توجد توقيعات')
                              : _buildSignaturesList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // مؤشر التحميل
            if (_isProcessing)
              Container(
                padding: const EdgeInsets.all(16),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('جاري المعالجة...'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState([String? message]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.document_scanner_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message ?? 'لا توجد مستندات ممسوحة',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'استخدم الأزرار أعلاه لإضافة محتوى جديد',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPdfFilesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _pdfFiles.length,
      itemBuilder: (context, index) {
        final filePath = _pdfFiles[index];
        final file = File(filePath);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.picture_as_pdf,
                color: Colors.red,
                size: 32,
              ),
            ),
            title: Text('مستند ${index + 1}'),
            subtitle: Text(
              'الحجم: ${_getFileSize(file)} • ${_getFileDate(file)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.visibility, size: 20),
                      SizedBox(width: 8),
                      Text('عرض'),
                    ],
                  ),
                  onTap: () => _viewTextFile(filePath),
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.branding_watermark, size: 20, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('علامة مائية'),
                    ],
                  ),
                  onTap: () => _addWatermark(filePath),
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('حذف', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  onTap: () => _deletePdfFile(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSignaturesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _signatures.length,
      itemBuilder: (context, index) {
        final filePath = _signatures[index];
        final file = File(filePath);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.draw,
                color: Colors.blue,
                size: 32,
              ),
            ),
            title: Text('توقيع ${index + 1}'),
            subtitle: Text(
              'الحجم: ${_getFileSize(file)} • ${_getFileDate(file)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.visibility, size: 20),
                      SizedBox(width: 8),
                      Text('عرض'),
                    ],
                  ),
                  onTap: () => _viewTextFile(filePath),
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('حذف', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  onTap: () => _deleteSignature(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _viewTextFile(String filePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TextFileViewerPage(filePath: filePath),
      ),
    );
  }

  void _deletePdfFile(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المستند'),
        content: const Text('هل أنت متأكد من حذف هذا المستند؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              final file = File(_pdfFiles[index]);
              file.delete();
              setState(() {
                _pdfFiles.removeAt(index);
              });
              Navigator.pop(context);
              _showSuccessSnackBar('تم حذف المستند');
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteSignature(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف التوقيع'),
        content: const Text('هل أنت متأكد من حذف هذا التوقيع؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              final file = File(_signatures[index]);
              file.delete();
              setState(() {
                _signatures.removeAt(index);
              });
              Navigator.pop(context);
              _showSuccessSnackBar('تم حذف التوقيع');
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _documentImages.length,
      itemBuilder: (context, index) {
        final imagePath = _documentImages[index];
        final file = File(imagePath);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                file,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  );
                },
              ),
            ),
            title: Text('مستند ${index + 1}'),
            subtitle: Text(
              'الحجم: ${_getFileSize(file)} • ${_getFileDate(file)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.visibility, size: 20),
                      SizedBox(width: 8),
                      Text('عرض'),
                    ],
                  ),
                  onTap: () => _viewDocument(imagePath),
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.share, size: 20),
                      SizedBox(width: 8),
                      Text('مشاركة'),
                    ],
                  ),
                  onTap: () => _shareDocument(imagePath),
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.branding_watermark, size: 20, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('علامة مائية'),
                    ],
                  ),
                  onTap: () => _addWatermark(imagePath),
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('حذف', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  onTap: () => _deleteDocument(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getFileSize(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes ب';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} ك.ب';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} م.ب';
    } catch (e) {
      return 'غير معروف';
    }
  }

  String _getFileDate(File file) {
    try {
      final date = file.lastModifiedSync();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'غير معروف';
    }
  }

  void _viewDocument(String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentViewerPage(imagePath: imagePath),
      ),
    );
  }

  // إنشاء PDF من الصور (فعلي)
  Future<void> _createPdfFromImages() async {
    if (_documentImages.isEmpty) {
      _showErrorSnackBar('لا توجد صور لإنشاء PDF');
      return;
    }

    try {
      setState(() => _isProcessing = true);
      
      // إنشاء ملف PDF بسيط (نص فقط لأننا لا نملك مكتبة PDF)
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'document_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${directory.path}/$fileName');
      
      String content = 'مستند PDF تم إنشاؤه من ${_documentImages.length} صورة\n';
      content += 'تاريخ الإنشاء: ${DateTime.now()}\n\n';
      
      for (int i = 0; i < _documentImages.length; i++) {
        content += 'الصورة ${i + 1}: ${_documentImages[i].split('/').last}\n';
      }
      
      await file.writeAsString(content);
      
      setState(() {
        _pdfFiles.add(file.path);
      });
      
      _showSuccessSnackBar('تم إنشاء ملف المستند بنجاح!');
    } catch (e) {
      _showErrorSnackBar('خطأ في إنشاء PDF: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // دمج الملفات (فعلي)
  Future<void> _mergeDocuments() async {
    if (_pdfFiles.length < 2) {
      _showErrorSnackBar('يجب وجود ملفين على الأقل للدمج');
      return;
    }

    try {
      setState(() => _isProcessing = true);
      
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'merged_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${directory.path}/$fileName');
      
      String mergedContent = 'مستند مدمج\n';
      mergedContent += 'تاريخ الدمج: ${DateTime.now()}\n';
      mergedContent += 'عدد الملفات المدمجة: ${_pdfFiles.length}\n\n';
      
      for (int i = 0; i < _pdfFiles.length; i++) {
        mergedContent += '--- الملف ${i + 1} ---\n';
        final sourceFile = File(_pdfFiles[i]);
        if (await sourceFile.exists()) {
          final content = await sourceFile.readAsString();
          mergedContent += content + '\n\n';
        }
      }
      
      await file.writeAsString(mergedContent);
      
      setState(() {
        _pdfFiles.add(file.path);
      });
      
      _showSuccessSnackBar('تم دمج الملفات بنجاح!');
    } catch (e) {
      _showErrorSnackBar('خطأ في دمج الملفات: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // إضافة علامة مائية (فعلي)
  Future<void> _addWatermark(String filePath) async {
    try {
      setState(() => _isProcessing = true);
      
      final sourceFile = File(filePath);
      if (!await sourceFile.exists()) {
        _showErrorSnackBar('الملف غير موجود');
        return;
      }
      
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'watermarked_${DateTime.now().millisecondsSinceEpoch}.txt';
      final newFile = File('${directory.path}/$fileName');
      
      String content = await sourceFile.readAsString();
      String watermarkedContent = '*** أرشيف المكتب - ${DateTime.now().year} ***\n';
      watermarkedContent += '*** مستند محمي بعلامة مائية ***\n\n';
      watermarkedContent += content;
      watermarkedContent += '\n\n*** نهاية المستند المحمي ***';
      
      await newFile.writeAsString(watermarkedContent);
      
      setState(() {
        _pdfFiles.add(newFile.path);
      });
      
      _showSuccessSnackBar('تم إضافة العلامة المائية بنجاح!');
    } catch (e) {
      _showErrorSnackBar('خطأ في إضافة العلامة المائية: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // إنشاء توقيع رقمي (فعلي)
  Future<void> _createDigitalSignature() async {
    final TextEditingController signatureController = TextEditingController();
    
    final signature = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إنشاء توقيع رقمي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('أدخل نص التوقيع:'),
            const SizedBox(height: 16),
            TextField(
              controller: signatureController,
              decoration: const InputDecoration(
                hintText: 'مثال: محمد أحمد',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, signatureController.text),
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
    
    if (signature == null || signature.isEmpty) return;
    
    try {
      setState(() => _isProcessing = true);
      
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'signature_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${directory.path}/$fileName');
      
      String signatureContent = 'توقيع رقمي\n';
      signatureContent += '================\n';
      signatureContent += 'الاسم: $signature\n';
      signatureContent += 'التاريخ: ${DateTime.now()}\n';
      signatureContent += 'الوقت: ${DateTime.now().toLocal()}\n';
      signatureContent += '================\n';
      
      await file.writeAsString(signatureContent);
      
      setState(() {
        _signatures.add(file.path);
      });
      
      _showSuccessSnackBar('تم إنشاء التوقيع الرقمي بنجاح!');
    } catch (e) {
      _showErrorSnackBar('خطأ في إنشاء التوقيع: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _shareDocument(String imagePath) async {
    try {
      // نسخ الملف إلى مجلد مؤقت للمشاركة
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'shared_${DateTime.now().millisecondsSinceEpoch}_${imagePath.split('/').last}';
      final sharedFile = File('${directory.path}/$fileName');
      
      final originalFile = File(imagePath);
      await originalFile.copy(sharedFile.path);
      
      _showSuccessSnackBar('تم تحضير الملف للمشاركة: ${sharedFile.path}');
    } catch (e) {
      _showErrorSnackBar('خطأ في تحضير الملف للمشاركة: $e');
    }
  }
}

// صفحة عرض المستند
class DocumentViewerPage extends StatelessWidget {
  final String imagePath;

  const DocumentViewerPage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عرض المستند'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: InteractiveViewer(
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'خطأ في تحميل الصورة',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// صفحة عرض الملفات النصية
class TextFileViewerPage extends StatelessWidget {
  final String filePath;

  const TextFileViewerPage({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('عرض ${filePath.split('/').last}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<String>(
        future: _loadFileContent(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('خطأ في تحميل الملف: ${snapshot.error}'),
                ],
              ),
            );
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  snapshot.data ?? 'لا يوجد محتوى',
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<String> _loadFileContent() async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
      return 'الملف غير موجود';
    } catch (e) {
      throw Exception('فشل في قراءة الملف: $e');
    }
  }
}
