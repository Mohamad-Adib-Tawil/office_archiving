// خدمة المسح المبدئية باستخدام الكاميرا عبر image_picker
// لاحقاً يمكن استبدالها بمسح ذكي يدعم كشف الزوايا.

import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ScanService {
  ScanService._();
  static final ScanService _instance = ScanService._();
  factory ScanService() => _instance;

  // التقاط صورة من الكاميرا كمسح مبدئي
  Future<File?> scanDocument({int pageLimit = 1}) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (xfile == null) return null;
    return File(xfile.path);
  }
}
