import 'dart:developer';
import 'dart:io';

import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/service/sqlite_service.dart';
import 'package:office_archiving/services/ocr_service.dart';

Future<void> processImageAndAddItem(
    File imageFile, int idSection, ItemSectionCubit itemCubit) async {
  final filePath = imageFile.path;

  final fileNameWithExtension = filePath.split('/').last; // name.jpg
  final itemName = fileNameWithExtension.split('.').first; // name
  final fileType = filePath.split('.').last; //jpg
  log('processImageAndAddItem name=$itemName type=$fileType');

  await itemCubit.addItem(itemName, filePath, fileType, idSection);

  // Run OCR in background after insertion
  try {
    final itemRow = await DatabaseService.instance.getItemByFilePath(filePath);
    if (itemRow != null) {
      final id = itemRow['id'] as int;
      final type = (itemRow['fileType'] as String?) ?? fileType;
      // Fire-and-forget
      // ignore: unawaited_futures
      OCRService().processItemAndSaveOcr(
        id: id,
        filePath: filePath,
        fileType: type,
        lang: 'auto',
      );
    }
  } catch (e) {
    log('Auto OCR after add failed: $e');
  }
}
