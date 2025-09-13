import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/functions/process_image_and_add_item.dart';

import 'package:image_picker/image_picker.dart';

import 'show_snack_bar.dart';

void addItemFromCamera(
    int idSection, ItemSectionCubit itemCubit, BuildContext context) async {
  final picker = ImagePicker();
  try {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final filePath = pickedFile.path;
      // final fileName = path.basename(filePath);
      log('addItemFromCamera pickedFile $pickedFile -- ');

      processImageAndAddItem(File(filePath), idSection, itemCubit);
    } else {
      showSnackBar(context, 'No image selected');
    }
  } catch (e) {
    showSnackBar(context, 'Error: $e');
  }
}
