import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/functions/process_image_and_add_item.dart';
import 'package:office_archiving/functions/show_snack_bar.dart';
import 'package:office_archiving/l10n/app_localizations.dart';

void addItemFromGallery(BuildContext context, int idSection,ItemSectionCubit itemCubit,) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (!context.mounted) return;
      
      if (pickedFile != null) {
        processImageAndAddItem(File(pickedFile.path),idSection ,itemCubit );
      } else {
        showSnackBar(context, AppLocalizations.of(context).no_image_picked);
      }
    } catch (e) {
      if (!context.mounted) return;
      showSnackBar(context ,'Error: $e',);
    }
  }