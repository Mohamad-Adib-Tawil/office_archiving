import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/functions/show_snack_bar.dart';
import 'package:permission_handler/permission_handler.dart';

void addItemFromMemoryStorage(BuildContext context, int idSection, ItemSectionCubit itemCubit) async {
  try {
    if (!context.mounted) return;

    if (!(await _requestPermission(context))) {
      return;
    }

    if (!context.mounted) return;

    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      final fileNameWithExtension = filePath.split('/').last;
      final fileName = fileNameWithExtension.split('.').first;
      final fileType = fileNameWithExtension.split('.').last;

      log('|| addItemFromMemoryStorage || fileName: $fileName, fileType: $fileType, path: $filePath ');

      itemCubit.addItem(fileName, filePath, fileType, idSection);
    } else {
      if (context.mounted) {
        showSnackBar(context, 'لم يتم تحديد أي ملف');
      }
    }
  } catch (e) {
    if (context.mounted) {
      showSnackBar(context, 'حدث خطأ: $e');
    }
  }
}

Future<bool> _requestPermission(BuildContext context) async {
  if (Platform.isAndroid) {
    // Request a set of relevant permissions and proceed if any is granted
    final statuses = await [
      Permission.storage,
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ].request();

    final granted = statuses.values.any((s) => s.isGranted);
    if (granted) return true;
  } else {
    // iOS and others: generally allowed for file picker
    return true;
  }

  if (context.mounted) {
    showSnackBar(context, 'مطلوب إذن للوصول إلى الملفات');
  }
  return false;
}
