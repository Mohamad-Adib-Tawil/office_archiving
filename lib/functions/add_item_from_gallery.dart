import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/functions/process_image_and_add_item.dart';
import 'package:office_archiving/functions/show_snack_bar.dart';
import 'package:office_archiving/l10n/app_localizations.dart';
import 'package:office_archiving/screens/editor/internal_editor_page.dart';

// إضافة عنصر من المعرض أو عبر المحرر الداخلي بحسب اختيار المستخدم
void addItemFromGallery(
  BuildContext context,
  int idSection,
  ItemSectionCubit itemCubit,
) async {
  try {
    // حوار يتيح اختيار المسار: المعرض الافتراضي أو المحرر الداخلي
    final route = await _showPickRouteDialog(context);
    if (route == null) return;

    if (route == _PickRoute.systemGallery) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (!context.mounted) return;
      if (pickedFile != null) {
        processImageAndAddItem(File(pickedFile.path), idSection, itemCubit);
      } else {
        showSnackBar(context, AppLocalizations.of(context).no_image_picked);
      }
    } else {
      // المحرر الداخلي بدون اختيار مسبوق من المعرض
      final String? resultPath = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InternalEditorPage()),
      );
      if (!context.mounted) return;
      if (resultPath != null) {
        processImageAndAddItem(File(resultPath), idSection, itemCubit);
      }
    }
  } catch (e) {
    if (!context.mounted) return;
    showSnackBar(context, 'Error: $e');
  }
}

// حوار اختيار المسار: المعرض الافتراضي أم المحرر الداخلي
Future<_PickRoute?> _showPickRouteDialog(BuildContext context) async {
  return showDialog<_PickRoute>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(AppLocalizations.of(context).choose_image_source),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('المعرض الافتراضي'),
              onTap: () => Navigator.of(context).pop(_PickRoute.systemGallery),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('المحرر الداخلي'),
              onTap: () => Navigator.of(context).pop(_PickRoute.internalEditor),
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

enum _PickRoute { systemGallery, internalEditor }