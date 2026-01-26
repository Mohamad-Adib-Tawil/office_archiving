import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:office_archiving/utils/image_utils.dart';
import 'package:office_archiving/pages/document_view_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:office_archiving/service/sqlite_service.dart';

/// بطاقة عرض ملف/مستند داخل القسم
class SectionFileCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onDeleted;

  const SectionFileCard({
    super.key,
    required this.item,
    this.onDeleted,
  });

  @override
  State<SectionFileCard> createState() => _SectionFileCardState();
}

class _SectionFileCardState extends State<SectionFileCard> {
  Uint8List? _thumbnail;
  bool _isLoading = true;
  bool _fileExists = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final filePath = widget.item['filePath'] as String?;
    
    if (filePath == null || filePath.isEmpty) {
      setState(() {
        _isLoading = false;
        _fileExists = false;
      });
      return;
    }

    // التحقق من وجود الملف
    if (!fileExists(filePath)) {
      setState(() {
        _isLoading = false;
        _fileExists = false;
      });
      return;
    }

    // توليد thumbnail
    final request = ThumbnailRequest(
      filePath: filePath,
      maxWidth: 300,
      quality: 70,
    );

    final thumbnail = await generateThumbnail(request);

    if (mounted) {
      setState(() {
        _thumbnail = thumbnail;
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'غير محدد';
    
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        return 'اليوم ${DateFormat('HH:mm').format(date)}';
      } else if (diff.inDays == 1) {
        return 'أمس ${DateFormat('HH:mm').format(date)}';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} أيام';
      } else {
        return DateFormat('yyyy-MM-dd').format(date);
      }
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _openDocument() async {
    final filePath = widget.item['filePath'] as String?;
    
    if (filePath == null || !fileExists(filePath)) {
      _showErrorSnackBar('الملف غير موجود');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentViewPage(
          filePath: filePath,
          documentName: widget.item['name'] as String? ?? 'مستند',
        ),
      ),
    );
  }

  Future<void> _shareDocument() async {
    final filePath = widget.item['filePath'] as String?;
    
    if (filePath == null || !fileExists(filePath)) {
      _showErrorSnackBar('الملف غير موجود');
      return;
    }

    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: widget.item['name'] as String? ?? 'مستند',
      );
    } catch (e) {
      _showErrorSnackBar('فشلت المشاركة');
    }
  }

  Future<void> _deleteDocument() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('تأكيد الحذف'),
          ],
        ),
        content: Text(
          'هل تريد حذف "${widget.item['name']}"؟\nلا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final itemId = widget.item['id'] as int;
      final filePath = widget.item['filePath'] as String?;

      // حذف من قاعدة البيانات
      await DatabaseService.instance.deleteItemAndFixSection(itemId);

      // حذف الملف من القرص
      if (filePath != null) {
        await deleteFileSafely(filePath);
      }

      if (mounted) {
        _showSuccessSnackBar('تم الحذف بنجاح');
        widget.onDeleted?.call();
      }
    } catch (e) {
      _showErrorSnackBar('فشل الحذف: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _openDocument,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // معاينة الصورة
            Expanded(
              flex: 3,
              child: _buildThumbnail(colorScheme),
            ),
            
            // معلومات الملف
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اسم الملف
                    Text(
                      widget.item['name'] as String? ?? 'مستند',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // التاريخ
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatDate(widget.item['createdAt'] as String?),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // أزرار الإجراءات
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.share, size: 18),
                          onPressed: _shareDocument,
                          tooltip: 'مشاركة',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          onPressed: _deleteDocument,
                          tooltip: 'حذف',
                          color: Colors.red,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(ColorScheme colorScheme) {
    if (!_fileExists) {
      return Container(
        color: colorScheme.errorContainer,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(
              'الملف مفقود',
              style: TextStyle(
                color: colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return Container(
        color: colorScheme.surfaceContainerHighest,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.primary,
          ),
        ),
      );
    }

    if (_thumbnail == null) {
      return Container(
        color: colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.image_not_supported,
          size: 48,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Image.memory(
      _thumbnail!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: colorScheme.errorContainer,
          child: Icon(
            Icons.error_outline,
            size: 48,
            color: colorScheme.error,
          ),
        );
      },
    );
  }
}
