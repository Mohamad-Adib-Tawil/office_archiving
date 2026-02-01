import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// أنواع الفلاتر المتاحة
enum FilterType {
  original,      // الصورة الأصلية
  blackWhite,    // أبيض وأسود
  grayscale,     // رمادي
  enhance,       // تحسين
}

/// خدمة تطبيق الفلاتر على المستندات الممسوحة
class DocumentFilterService {

  /// تطبيق فلتر على صورة
  static Future<File> applyFilter(
    File imageFile,
    FilterType filterType,
  ) async {
    try {
      final resultPath = await compute(_applyFilterSync, {
        'path': imageFile.path,
        'filter': filterType.index,
      });
      return File(resultPath as String);
    } catch (e) {
      throw Exception('خطأ في تطبيق الفلتر: $e');
    }
  }

  /// فلتر أبيض وأسود (Black & White)
  static img.Image _applyBlackWhiteFilter(img.Image image) {
    // تحويل لرمادي أولاً
    final grayscale = img.grayscale(image);

    // حساب threshold تلقائي (متوسط الإضاءة)
    int totalBrightness = 0;
    int pixelCount = 0;

    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        final pixel = grayscale.getPixelSafe(x, y);
        final brightness = (pixel.r + pixel.g + pixel.b) ~/ 3;
        totalBrightness += brightness;
        pixelCount++;
      }
    }

    final threshold = totalBrightness ~/ pixelCount;

    // تطبيق threshold
    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        final pixel = grayscale.getPixelSafe(x, y);
        final brightness = (pixel.r + pixel.g + pixel.b) ~/ 3;
        final value = brightness > threshold ? 255 : 0;
        grayscale.setPixelRgba(x, y, value, value, value, 255);
      }
    }

    return grayscale;
  }

  /// فلتر رمادي محسّن (Grayscale)
  static img.Image _applyGrayscaleFilter(img.Image image) {
    var grayscale = img.grayscale(image);

    // زيادة التباين قليلاً
    grayscale = img.adjustColor(
      grayscale,
      contrast: 1.2,
    );

    return grayscale;
  }

  /// فلتر تحسين (Enhance)
  static img.Image _applyEnhanceFilter(img.Image image) {
    // زيادة التباين والسطوع والتشبع
    return img.adjustColor(
      image,
      contrast: 1.3,
      brightness: 1.1,
      saturation: 1.05,
    );
  }

  /// الحصول على اسم الفلتر
  static String getFilterName(FilterType filterType) {
    return switch (filterType) {
      FilterType.original => 'أصلي',
      FilterType.blackWhite => 'أبيض وأسود',
      FilterType.grayscale => 'رمادي',
      FilterType.enhance => 'تحسين',
    };
  }

  /// الحصول على أيقونة الفلتر
  static String getFilterEmoji(FilterType filterType) {
    return switch (filterType) {
      FilterType.original => '🎨',
      FilterType.blackWhite => '⚫',
      FilterType.grayscale => '⚪',
      FilterType.enhance => '✨',
    };
  }
}

// تُنفَّذ في isolate باستخدام compute
String _applyFilterSync(Map<String, dynamic> args) {
  final String path = args['path'] as String;
  final int filterIndex = args['filter'] as int;
  final filterType = FilterType.values[filterIndex];

  final file = File(path);
  final bytes = file.readAsBytesSync();
  var image = img.decodeImage(bytes);
  if (image == null) {
    throw Exception('فشل في فك تشفير الصورة');
  }

  switch (filterType) {
    case FilterType.original:
      break;
    case FilterType.blackWhite:
      image = DocumentFilterService._applyBlackWhiteFilter(image);
      break;
    case FilterType.grayscale:
      image = DocumentFilterService._applyGrayscaleFilter(image);
      break;
    case FilterType.enhance:
      image = DocumentFilterService._applyEnhanceFilter(image);
      break;
  }

  final filteredBytes = img.encodeJpg(image, quality: 95);
  file.writeAsBytesSync(filteredBytes);
  return file.path;
}
