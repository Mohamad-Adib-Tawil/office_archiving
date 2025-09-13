import 'package:flutter/material.dart';
import 'package:office_archiving/constants.dart';
import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/functions/addItemFromGallery.dart';
import 'package:office_archiving/functions/add_item_from_camera.dart';
import 'package:office_archiving/functions/add_item_from_memory_storage.dart';

void showAddItemDialog(
  BuildContext context,
  int idSection,
  ItemSectionCubit itemCubit,
) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Center(
          child: const Text(
            'Add Item',
            style: TextStyle(
              color: kPrimaryColor,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 45, // Set desired height for buttons
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kPrimaryColor.withOpacity(.6),
                      kPrimaryColor.withOpacity(.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    addItemFromMemoryStorage(context, idSection, itemCubit);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.transparent, // Make button transparent
                    elevation: 0, // Remove button shadow
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Add Item from Memory Storage',
                    style: TextStyle(
                        color: Colors.white), // Set text color to white
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 45, // Set desired height for buttons
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kPrimaryColor.withOpacity(.6),
                      kPrimaryColor.withOpacity(.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(
                      12), // Adjust border radius as needed
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    addItemFromCamera(idSection, itemCubit, context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.transparent, // Make button transparent
                    elevation: 0, // Remove button shadow
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            8)), // Same as container's border radius
                  ),
                  child: const Text(
                    'Add Item from Camera',
                    style: TextStyle(
                        color: Colors.white), // Set text color to white
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 45, // Set desired height for buttons
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kPrimaryColor.withOpacity(.6),
                      kPrimaryColor.withOpacity(.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(
                      8), // Adjust border radius as needed
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    addItemFromGallery(context, idSection, itemCubit);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.transparent, // Make button transparent
                    elevation: 0, // Remove button shadow
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            8)), // Same as container's border radius
                  ),
                  child: const Text(
                    'Add Item from Gallery',
                    style: TextStyle(
                        color: Colors.white), // Set text color to white
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
    },
  );
}
