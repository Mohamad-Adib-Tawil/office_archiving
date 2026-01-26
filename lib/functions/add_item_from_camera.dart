import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/functions/process_image_and_add_item.dart';
import 'package:office_archiving/functions/show_snack_bar.dart';
import 'package:office_archiving/l10n/app_localizations.dart';
import 'package:office_archiving/screens/editor/internal_editor_page.dart';

// إضافة عنصر من الكاميرا مع خيار التحرير عبر المحرر الداخلي بعد الالتقاط
void addItemFromCamera(
    int idSection, ItemSectionCubit itemCubit, BuildContext context) async {
  final picker = ImagePicker();
  try {
    // حوار يحدد التدفق: حفظ مباشر أم تحرير بالمحرر الداخلي
    final flow = await _showCameraFlowDialog(context);
    if (flow == null) return;

    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (!context.mounted) return;

    if (pickedFile != null) {
      final filePath = pickedFile.path;
      log('addItemFromCamera pickedFile $pickedFile -- ');

      if (flow == _CameraFlow.directSave) {
        await processImageAndAddItem(File(filePath), idSection, itemCubit);
      } else {
        // فتح المحرر الداخلي مع الصورة الملتقطة
        final String? resultPath = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => InternalEditorPage(initialImagePath: filePath)),
        );
        if (!context.mounted) return;
        if (resultPath != null) {
          await processImageAndAddItem(File(resultPath), idSection, itemCubit);
        }
      }
    } else {
      showSnackBar(context, AppLocalizations.of(context).no_image_selected);
    }
  } catch (e) {
    if (!context.mounted) return;
    showSnackBar(context, 'Error: $e');
  }
}

enum _CameraFlow { directSave, editAfterCapture }

Future<_CameraFlow?> _showCameraFlowDialog(BuildContext context) {
  return showDialog<_CameraFlow>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(AppLocalizations.of(context).choose_image_source),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('التقاط مباشر'),
            onTap: () => Navigator.pop(ctx, _CameraFlow.directSave),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('التقاط ثم تحرير (المحرر الداخلي)'),
            onTap: () => Navigator.pop(ctx, _CameraFlow.editAfterCapture),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(AppLocalizations.of(context).cancel),
        ),
      ],
    ),
  );
}
