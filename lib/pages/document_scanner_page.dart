import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:office_archiving/services/ocr_service.dart';
import 'package:office_archiving/service/sqlite_service.dart';

class DocumentScannerPage extends StatefulWidget {
  final int? sectionId;
  const DocumentScannerPage({super.key, this.sectionId});

  @override
  State<DocumentScannerPage> createState() => _DocumentScannerPageState();
}

class _DocumentScannerPageState extends State<DocumentScannerPage> {
  final List<ScanPage> _pages = [];
  final ImagePicker _picker = ImagePicker();
  final OCRService _ocrService = OCRService();
  bool _isProcessing = false;
  String _currentFilter = 'original';
  bool _autoEnhance = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('ماسح المستندات الاحترافي'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_pages.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'تصدير PDF',
              onPressed: _exportToPdf,
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'مشاركة',
              onPressed: _shareDocument,
            ),
          ],
        ],
      ),
      body: _pages.isEmpty 
        ? _buildEmptyState(context)
        : _buildPagesView(context),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_pages.isNotEmpty) ...[
            FloatingActionButton.small(
              heroTag: 'add_page',
              onPressed: _addPage,
              tooltip: 'إضافة صفحة',
              backgroundColor: scheme.secondaryContainer,
              child: Icon(Icons.add_a_photo, color: scheme.onSecondaryContainer),
            ),
            const SizedBox(height: 8),
          ],
          FloatingActionButton.extended(
            heroTag: 'scan',
            onPressed: _pages.isEmpty ? _scanDocument : _saveDocument,
            icon: Icon(_pages.isEmpty ? Icons.document_scanner : Icons.save),
            label: Text(_pages.isEmpty ? 'بدء المسح' : 'حفظ المستند'),
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.document_scanner_outlined,
              size: 80,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'ماسح مستندات احترافي',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'امسح، حسّن، وحول مستنداتك إلى PDF',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          _buildFeaturesList(context),
        ],
      ),
    );
  }

  Widget _buildFeaturesList(BuildContext context) {
    final features = [
      {'icon': Icons.auto_fix_high, 'text': 'تحسين تلقائي'},
      {'icon': Icons.crop_rotate, 'text': 'قص وتدوير'},
      {'icon': Icons.filter, 'text': 'فلاتر احترافية'},
      {'icon': Icons.text_fields, 'text': 'OCR متقدم'},
      {'icon': Icons.picture_as_pdf, 'text': 'تحويل PDF'},
      {'icon': Icons.security, 'text': 'حماية بكلمة مرور'},
    ];
    
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: features.map((f) => Chip(
        avatar: Icon(f['icon'] as IconData, size: 18),
        label: Text(f['text'] as String),
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5),
      )).toList(),
    );
  }

  Widget _buildPagesView(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(context),
        Expanded(
          child: _isProcessing 
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _pages.length,
                itemBuilder: (context, index) => _buildPageCard(context, index),
              ),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          FilterChip(
            selected: _autoEnhance,
            onSelected: (v) => setState(() => _autoEnhance = v),
            avatar: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('تحسين تلقائي'),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'اختر فلتر',
            initialValue: _currentFilter,
            onSelected: (filter) {
              setState(() => _currentFilter = filter);
              _applyFilterToAll(filter);
            },
            child: Chip(
              avatar: const Icon(Icons.filter_vintage, size: 18),
              label: Text(_getFilterName(_currentFilter)),
            ),
            itemBuilder: (context) => [
              _buildFilterMenuItem('original', 'أصلي', Colors.green),
              _buildFilterMenuItem('grayscale', 'أبيض وأسود', Colors.grey),
              _buildFilterMenuItem('document', 'مستند', Colors.brown),
              _buildFilterMenuItem('enhance', 'محسّن', Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildFilterMenuItem(String value, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  String _getFilterName(String filter) {
    switch (filter) {
      case 'grayscale': return 'أبيض وأسود';
      case 'document': return 'مستند';
      case 'enhance': return 'محسّن';
      default: return 'أصلي';
    }
  }

  Widget _buildPageCard(BuildContext context, int index) {
    final page = _pages[index];
    final scheme = Theme.of(context).colorScheme;
    
    return Stack(
      children: [
        Card(
          elevation: 4,
          child: InkWell(
            onTap: () => _editPage(index),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.file(
                      File(page.processedPath ?? page.originalPath),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Text('صفحة ${index + 1}', style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: CircleAvatar(
            backgroundColor: Colors.red,
            radius: 15,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.close, size: 18, color: Colors.white),
              onPressed: () {
                setState(() => _pages.removeAt(index));
                HapticFeedback.lightImpact();
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _scanDocument() async {
    final source = await _showSourceDialog();
    if (source == null) return;
    
    setState(() => _isProcessing = true);
    
    try {
      if (source == ImageSource.camera) {
        await _scanFromCamera();
      } else {
        await _selectFromGallery();
      }
    } catch (e) {
      _showError('خطأ في المسح: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _scanFromCamera() async {
    bool continueScanning = true;
    while (continueScanning) {
      final image = await _picker.pickImage(source: ImageSource.camera);
      if (image == null) break;
      
      final processedPath = await _processImage(image.path);
      setState(() {
        _pages.add(ScanPage(
          originalPath: image.path,
          processedPath: processedPath,
        ));
      });
      
      if (!mounted) break;
      
      continueScanning = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('إضافة صفحة أخرى؟'),
          content: Text('تم مسح ${_pages.length} صفحة'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انتهى'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('مسح المزيد'),
            ),
          ],
        ),
      ) ?? false;
    }
  }

  Future<void> _selectFromGallery() async {
    final images = await _picker.pickMultiImage();
    if (images.isEmpty) return;
    
    for (final image in images) {
      final processedPath = await _processImage(image.path);
      setState(() {
        _pages.add(ScanPage(
          originalPath: image.path,
          processedPath: processedPath,
        ));
      });
    }
  }

  Future<void> _addPage() async {
    await _scanDocument();
  }

  Future<String> _processImage(String imagePath) async {
    if (!_autoEnhance && _currentFilter == 'original') {
      return imagePath;
    }
    
    try {
      final bytes = await File(imagePath).readAsBytes();
      var image = img.decodeImage(bytes);
      if (image == null) return imagePath;
      
      if (_autoEnhance) {
        image = img.adjustColor(image, contrast: 1.2, brightness: 1.05);
        image = img.smooth(image, 1);
      }
      
      image = _applyFilter(image, _currentFilter);
      
      final dir = await getTemporaryDirectory();
      final processedFile = File('${dir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await processedFile.writeAsBytes(img.encodeJpg(image, quality: 95));
      
      return processedFile.path;
    } catch (e) {
      return imagePath;
    }
  }

  img.Image _applyFilter(img.Image image, String filter) {
    switch (filter) {
      case 'grayscale':
        return img.grayscale(image);
      case 'document':
        image = img.grayscale(image);
        image = img.adjustColor(image, contrast: 1.5);
        return image;
      case 'enhance':
        return img.adjustColor(image, contrast: 1.3, brightness: 1.1, saturation: 1.2);
      default:
        return image;
    }
  }

  void _applyFilterToAll(String filter) {
    setState(() => _isProcessing = true);
    
    Future.delayed(const Duration(milliseconds: 100), () async {
      for (var page in _pages) {
        final newPath = await _processImage(page.originalPath);
        page.processedPath = newPath;
      }
      setState(() => _isProcessing = false);
    });
  }

  Future<void> _editPage(int index) async {
    // TODO: فتح محرر الصفحة
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('محرر الصفحة قيد التطوير')),
    );
  }

  Future<void> _exportToPdf() async {
    setState(() => _isProcessing = true);
    
    try {
      final pdf = pw.Document();
      
      for (var page in _pages) {
        final imageFile = File(page.processedPath ?? page.originalPath);
        final imageBytes = await imageFile.readAsBytes();
        final image = pw.MemoryImage(imageBytes);
        
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => pw.Center(
              child: pw.Image(image),
            ),
          ),
        );
      }
      
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final pdfFile = File('${dir.path}/scan_$timestamp.pdf');
      await pdfFile.writeAsBytes(await pdf.save());
      
      if (!mounted) return;
      
      await Share.shareXFiles([XFile(pdfFile.path)]);
      
    } catch (e) {
      _showError('خطأ في إنشاء PDF: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveDocument() async {
    if (widget.sectionId != null) {
      await _saveToArchive();
    } else {
      await _exportToPdf();
    }
  }

  Future<void> _saveToArchive() async {
    if (widget.sectionId == null) return;
    
    try {
      final db = DatabaseService.instance;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      for (int i = 0; i < _pages.length; i++) {
        final page = _pages[i];
        final path = page.processedPath ?? page.originalPath;
        
        await db.insertItem(
          'صفحة_${i + 1}_$timestamp',
          path,
          'image',
          widget.sectionId!,
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ المستند بنجاح')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('خطأ في الحفظ: $e');
    }
  }

  Future<void> _shareDocument() async {
    if (_pages.isEmpty) return;
    
    final files = _pages.map((p) => 
      XFile(p.processedPath ?? p.originalPath)
    ).toList();
    
    await Share.shareXFiles(files, text: 'مستند ممسوح');
  }

  Future<ImageSource?> _showSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('الكاميرا'),
              subtitle: const Text('مسح مباشر بالكاميرا'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('المعرض'),
              subtitle: const Text('اختيار من الصور المحفوظة'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

class ScanPage {
  final String originalPath;
  String? processedPath;
  String? ocrText;
  bool hasOcr;
  
  ScanPage({
    required this.originalPath,
    this.processedPath,
    this.ocrText,
    this.hasOcr = false,
  });
}
