import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:office_archiving/service/sqlite_service.dart';

/// نتيجة اختيار القسم
class SectionSelectionResult {
  final int sectionId;
  final String sectionName;
  final bool isNewSection;

  SectionSelectionResult({
    required this.sectionId,
    required this.sectionName,
    this.isNewSection = false,
  });
}

/// عرض حوار موحد لاختيار قسم موجود أو إنشاء قسم جديد
/// 
/// يُستخدم قبل فتح الماسح الضوئي لضمان وجود قسم صالح للحفظ
/// 
/// Returns: [SectionSelectionResult] إذا تم الاختيار/الإنشاء، null إذا تم الإلغاء
Future<SectionSelectionResult?> showSectionSelectorDialog(
  BuildContext context, {
  String title = 'اختر القسم للحفظ',
  String? message,
  bool allowCancel = true,
}) async {
  final db = DatabaseService.instance;
  final sections = await db.getAllSections();

  if (!context.mounted) return null;

  // إذا لم توجد أقسام، نعرض حوار إنشاء مباشرة
  if (sections.isEmpty) {
    final newSectionName = await _showCreateSectionDialog(
      context,
      message: 'لا توجد أقسام متاحة. يرجى إنشاء قسم جديد أولاً.',
      allowCancel: allowCancel,
    );
    
    if (newSectionName == null) return null;
    
    final sectionId = await db.insertSection(newSectionName);
    if (sectionId == -1) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('القسم موجود مسبقاً. يرجى اختيار اسم آخر.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return null;
    }
    
    return SectionSelectionResult(
      sectionId: sectionId,
      sectionName: newSectionName,
      isNewSection: true,
    );
  }

  // عرض قائمة الأقسام مع خيار إنشاء جديد
  return await showModalBottomSheet<SectionSelectionResult>(
    context: context,
    isScrollControlled: true,
    isDismissible: allowCancel,
    enableDrag: allowCancel,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Handle indicator
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Header
            Row(
              children: [
                Icon(
                  Icons.folder_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // زر إنشاء قسم جديد
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
                title: const Text(
                  'إنشاء قسم جديد',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final newSectionName = await _showCreateSectionDialog(ctx);
                  if (newSectionName == null) return;
                  
                  final sectionId = await db.insertSection(newSectionName);
                  if (sectionId == -1) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('القسم موجود مسبقاً. يرجى اختيار اسم آخر.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                    return;
                  }
                  
                  if (ctx.mounted) {
                    Navigator.pop(
                      ctx,
                      SectionSelectionResult(
                        sectionId: sectionId,
                        sectionName: newSectionName,
                        isNewSection: true,
                      ),
                    );
                  }
                },
              ),
            ),
            
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            
            // قائمة الأقسام الموجودة
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  final section = sections[index];
                  final sectionName = section['name'] as String? ?? 'قسم';
                  final sectionId = section['id'] as int;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                        child: Icon(
                          Icons.folder,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      title: Text(
                        sectionName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(
                          context,
                          SectionSelectionResult(
                            sectionId: sectionId,
                            sectionName: sectionName,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            
            // زر إلغاء
            if (allowCancel) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  child: const Text('إلغاء'),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// حوار إنشاء قسم جديد
Future<String?> _showCreateSectionDialog(
  BuildContext context, {
  String? message,
  bool allowCancel = true,
}) async {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  return await showDialog<String>(
    context: context,
    barrierDismissible: allowCancel,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.create_new_folder, color: Colors.blue),
          SizedBox(width: 12),
          Text('إنشاء قسم جديد'),
        ],
      ),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message != null) ...[
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'اسم القسم',
                hintText: 'مثال: الفواتير، العقود، المستندات الشخصية',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.folder_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال اسم القسم';
                }
                if (value.trim().length < 2) {
                  return 'اسم القسم قصير جداً';
                }
                return null;
              },
              onFieldSubmitted: (value) {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx, controller.text.trim());
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        if (allowCancel)
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              Navigator.pop(ctx, controller.text.trim());
            }
          },
          child: const Text('إنشاء'),
        ),
      ],
    ),
  );
}
