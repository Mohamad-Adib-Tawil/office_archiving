import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

/// معلومات توليد thumbnail
class ThumbnailRequest {
  final String filePath;
  final int maxWidth;
  final int quality;

  const ThumbnailRequest({
    required this.filePath,
    this.maxWidth = 300,
    this.quality = 70,
  });
}

/// توليد thumbnail في isolate منفصل
Future<Uint8List?> generateThumbnail(ThumbnailRequest request) async {
  return await compute(_generateThumbnailSync, request);
}

/// الدالة الفعلية لتوليد thumbnail (تعمل في isolate)
Uint8List? _generateThumbnailSync(ThumbnailRequest request) {
  try {
    final file = File(request.filePath);
    
    if (!file.existsSync()) {
      debugPrint('⚠️ الملف غير موجود: ${request.filePath}');
      return null;
    }

    final bytes = file.readAsBytesSync();
    final image = img.decodeImage(bytes);
    
    if (image == null) {
      debugPrint('⚠️ فشل فك تشفير الصورة: ${request.filePath}');
      return null;
    }

    // تصغير الصورة
    final thumbnail = img.copyResize(
      image,
      width: request.maxWidth,
      interpolation: img.Interpolation.average,
    );

    // ترميز كـ JPG
    final encoded = img.encodeJpg(thumbnail, quality: request.quality);
    
    return Uint8List.fromList(encoded);
  } catch (e) {
    debugPrint('❌ خطأ في توليد thumbnail: $e');
    return null;
  }
}

/// توليد thumbnails لعدة ملفات دفعة واحدة
Future<Map<String, Uint8List>> generateThumbnailsBatch(
  List<String> filePaths, {
  int maxWidth = 300,
  int quality = 70,
}) async {
  final results = <String, Uint8List>{};
  
  // توليد متوازي باستخدام Future.wait
  final futures = filePaths.map((path) async {
    final request = ThumbnailRequest(
      filePath: path,
      maxWidth: maxWidth,
      quality: quality,
    );
    
    final thumbnail = await generateThumbnail(request);
    if (thumbnail != null) {
      results[path] = thumbnail;
    }
  });
  
  await Future.wait(futures);
  
  return results;
}

/// التحقق من وجود الملف
bool fileExists(String? filePath) {
  if (filePath == null || filePath.isEmpty) return false;
  return File(filePath).existsSync();
}

/// حذف ملف بأمان
Future<bool> deleteFileSafely(String? filePath) async {
  try {
    if (filePath == null || filePath.isEmpty) return false;
    
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  } catch (e) {
    debugPrint('❌ خطأ في حذف الملف: $e');
    return false;
  }
}

/// الحصول على حجم الملف بصيغة مقروءة
String getFileSize(String? filePath) {
  try {
    if (filePath == null || filePath.isEmpty) return '0 KB';
    
    final file = File(filePath);
    if (!file.existsSync()) return '0 KB';
    
    final bytes = file.lengthSync();
    
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  } catch (e) {
    return '0 KB';
  }
}
