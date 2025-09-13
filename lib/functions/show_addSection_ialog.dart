import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:office_archiving/cubit/section_cubit/section_cubit.dart';

void showAddSectionDialog(
  BuildContext context,
  TextEditingController sectionNameController,
  SectionCubit sectionCubit,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Add Section'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: sectionNameController,
              decoration: const InputDecoration(labelText: 'Section Name'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child:
                      const Text('Cancel', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (sectionNameController.text.isNotEmpty) {
                      String? errorMessage = await sectionCubit.addSection(
                        sectionNameController.text,
                      );
                      log('_sectionNameController.text.isNotEmpty ');
                      if (errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(errorMessage)),
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    }
                    sectionNameController.clear();
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
