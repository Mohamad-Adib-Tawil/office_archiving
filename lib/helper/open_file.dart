import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:office_archiving/functions/show_snack_bar.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:office_archiving/helper/pdf_viwer.dart';
import 'package:office_archiving/helper/text_viewer.dart';

Future<void> openFile({
  required String pathFile,
  required BuildContext context,
}) async {
  try {
    if (!context.mounted) return;

    bool isGranted = await _checkStoragePermission(context);

    if (!isGranted) {
      if (context.mounted) {
        showSnackBar(context, 'يجب منح صلاحية التخزين لفتح الملف');
      }
      return;
    }

    final lower = pathFile.toLowerCase();
    if (lower.endsWith('.pdf')) {
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MyPdfViewer(filePath: pathFile)),
      );
      return;
    } else if (lower.endsWith('.txt')) {
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TextViewer(filePath: pathFile)),
      );
      return;
    } else {
      OpenResult result = await OpenFile.open(pathFile);
      if (result.type == ResultType.done) {
        log('openFile opened successfully');
      } else {
        if (context.mounted) {
          showSnackBar(context, 'خطأ أثناء فتح الملف');
        }
      }
    }
  } catch (e) {
    if (context.mounted) {
      showSnackBar(context, 'خطأ: $e');
    }
  }
}

Future<bool> _checkStoragePermission(BuildContext context) async {
  if (Platform.isAndroid) {
    if (await Permission.storage.isGranted) return true;

    // Android 13+ (API 33) need special permissions
    var photos = await Permission.photos.status;
    var videos = await Permission.videos.status;
    var audio = await Permission.audio.status;

    if (photos.isGranted || videos.isGranted || audio.isGranted) return true;

    // Request needed
    Map<Permission, PermissionStatus> statuses =
        await [Permission.storage, Permission.photos, Permission.videos, Permission.audio].request();

    if (statuses[Permission.storage]?.isGranted == true ||
        statuses[Permission.photos]?.isGranted == true ||
        statuses[Permission.videos]?.isGranted == true ||
        statuses[Permission.audio]?.isGranted == true) {
      return true;
    }
  }

  if (Platform.isIOS) {
    return true; // iOS normally auto-granted for file picker
  }

  return false;
}
