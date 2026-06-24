import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/functions/show_snack_bar.dart';
import 'package:office_archiving/l10n/app_localizations.dart';
import 'package:office_archiving/services/sqlite_service.dart';
import 'package:office_archiving/services/document_storage_service.dart';
import 'package:office_archiving/services/ocr_service.dart';

void addItemFromMemoryStorage(
  BuildContext context,
  int idSection,
  ItemSectionCubit itemCubit,
) async {
  try {
    if (!context.mounted) return;

    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final originalPath = result.files.single.path!;
      final persistedFile = await DocumentStorageService.instance.persistFile(
        sourcePath: originalPath,
        directory: ManagedDirectory.imports,
        preferredName: DocumentStorageService.instance.fileNameStem(
          originalPath,
        ),
        prefix: 'import',
      );
      final filePath = persistedFile.path;
      final fileNameWithExtension = filePath.split('/').last;
      final fileName = fileNameWithExtension.split('.').first;
      final fileType = DocumentStorageService.instance.extensionOf(filePath);

      log(
        '|| addItemFromMemoryStorage || fileName: $fileName, fileType: $fileType, path: $filePath ',
      );

      await itemCubit.addItem(fileName, filePath, fileType, idSection);

      if (DocumentStorageService.instance.isImagePath(filePath)) {
        final itemRow = await DatabaseService.instance.getItemByFilePath(
          filePath,
        );
        if (itemRow != null) {
          final itemId = itemRow['id'] as int;
          // ignore: unawaited_futures
          OCRService().processItemAndSaveOcr(
            id: itemId,
            filePath: filePath,
            fileType: fileType,
            lang: 'auto',
            allowPdf: false,
          );
        }
      }
    } else {
      if (context.mounted) {
        showSnackBar(context, AppLocalizations.of(context).no_file_selected);
      }
    }
  } catch (e) {
    if (context.mounted) {
      showSnackBar(
        context,
        '${AppLocalizations.of(context).generic_error}: $e',
      );
    }
  }
}
