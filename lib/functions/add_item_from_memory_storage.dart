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
    int sdkInt = (await Permission.storage.status).toString().contains("granted") ? 29 : 33;

    if (sdkInt >= 33) {
      // Android 13+
      var photos = await Permission.photos.request();
      var videos = await Permission.videos.request();
      var audio = await Permission.audio.request();
      if (photos.isGranted || videos.isGranted || audio.isGranted) {
        return true;
      }
    } else {
      // Android 12 and below
      var storage = await Permission.storage.request();
      if (storage.isGranted) {
        return true;
      }
    }
  } else {
    // iOS or others
    return true;
  }

  if (context.mounted) {
    showSnackBar(context, 'مطلوب إذن للوصول إلى الملفات');
  }
  return false;
}
