import 'package:flutter/material.dart';
import 'package:office_archiving/functions/show_snack_bar.dart';
import 'package:open_file/open_file.dart';
import 'package:office_archiving/l10n/app_localizations.dart';
import 'dart:developer';
import 'package:office_archiving/helper/pdf_viewer.dart';
import 'package:office_archiving/helper/text_viewer.dart';

Future<void> openFile({
  required String pathFile,
  required BuildContext context,
}) async {
  try {
    if (!context.mounted) return;

    final lower = pathFile.toLowerCase();
    if (lower.endsWith('.pdf')) {
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MyPdfViewer(filePath: pathFile)),
      );
      return;
    } else if (lower.endsWith('.txt')) {
      if (!context.mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => TextViewer(filePath: pathFile)));
      return;
    } else {
      OpenResult result = await OpenFile.open(pathFile);
      if (result.type == ResultType.done) {
        log('openFile opened successfully');
      } else {
        if (context.mounted) {
          showSnackBar(context, AppLocalizations.of(context).file_open_error);
        }
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
