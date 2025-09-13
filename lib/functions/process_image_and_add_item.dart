import 'dart:developer';
import 'dart:io';

import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';

void processImageAndAddItem(
    File imageFile, int idSection, ItemSectionCubit itemCubit) {
  final filePath = imageFile.path;

  final fileNameWithExtension = filePath.split('/').last; // name.jpg
  final itemName = fileNameWithExtension.split('.').first; // name
  final fileType = filePath.split('.').last; //jpg
  log('ksaj kldsj lkjfdslj  fileNameWithExtension$fileNameWithExtension---- itemName:$itemName----fileType:$fileType');

  itemCubit.addItem(itemName, filePath, fileType, idSection);
}
