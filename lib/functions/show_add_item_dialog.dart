import 'package:flutter/material.dart';
import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/functions/addItemFromGallery.dart';
import 'package:office_archiving/functions/add_item_from_camera.dart';
import 'package:office_archiving/functions/add_item_from_memory_storage.dart';

void showAddItemDialog(BuildContext context, int idSection, ItemSectionCubit itemCubit) {
  final theme = Theme.of(context);
  final primary = theme.colorScheme.primary;
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Center(
          child: Text(
            'Add Item',
            style: TextStyle(color: primary),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 45,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primary.withOpacity(.6), primary.withOpacity(.15)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    addItemFromMemoryStorage(context, idSection, itemCubit);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add Item from Memory Storage', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primary.withOpacity(.6), primary.withOpacity(.15)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    addItemFromCamera(idSection, itemCubit, context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Add Item from Camera', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primary.withOpacity(.6), primary.withOpacity(.15)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    addItemFromGallery(context, idSection, itemCubit);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Add Item from Gallery', style: TextStyle(color: Colors.white)),
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
