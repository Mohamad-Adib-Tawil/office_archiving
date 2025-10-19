import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/functions/process_image_and_add_item.dart';
import 'package:office_archiving/functions/show_snack_bar.dart';
import 'package:office_archiving/l10n/app_localizations.dart';

void addItemFromGallery(
  BuildContext context,
  int idSection,
  ItemSectionCubit itemCubit,
) async {
  try {
    String? imagePath;

    // عرض خيارات للمستخدم لاختيار مصدر الصورة
    final source = await _showImageSourceDialog(context);
    if (source == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 85, // ضغط الصورة لتوفير المساحة
    );
    if (pickedFile != null) {
      imagePath = pickedFile.path;
    }

    if (!context.mounted) return;
    if (imagePath != null) {
      processImageAndAddItem(File(imagePath), idSection, itemCubit);
    } else {
      showSnackBar(context, AppLocalizations.of(context).no_image_picked);
    }
  } catch (e) {
    if (!context.mounted) return;
    showSnackBar(
      context,
      'Error: $e',
    );
  }
}

Future<ImageSource?> _showImageSourceDialog(BuildContext context) async {
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