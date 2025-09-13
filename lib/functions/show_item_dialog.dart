import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/models/item.dart';
import 'package:office_archiving/widgets/rename_item_dialog.dart';

void showItemOptionsDialog(BuildContext context, ItemSection itemSection,
      ItemSectionCubit itemSectionCubit) {
    log('_showOptionsDialog ${itemSection.id}');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Options for ${itemSection.name}'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                handleRenameItem(context, itemSection, itemSectionCubit);
              },
              child: const Text('Rename'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                handleDeleteItem(context, itemSection);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void handleDeleteItem(BuildContext context, ItemSection itemSection) {
    context
        .read<ItemSectionCubit>()
        .deleteItem(itemSection.id, itemSection.idSection);
  }

  void handleRenameItem(BuildContext context, ItemSection itemSection,
      ItemSectionCubit itemSectionCubit) async {
    String? newName = await showDialog<String>(
      context: context,
      builder: (context) => const RenameItemDialog(),
    );

    if (newName != null) {
      itemSectionCubit.updateItemName(
          itemSection.id, newName, itemSection.idSection);
    }
  }