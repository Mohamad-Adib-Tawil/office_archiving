import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/models/item.dart';
import 'package:office_archiving/widgets/rename_item_dialog.dart';
import 'package:office_archiving/cubit/section_cubit/section_cubit.dart';
import 'package:office_archiving/theme/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:office_archiving/ui/feedback.dart';
import 'package:office_archiving/l10n/app_localizations.dart';

void showItemOptionsDialog(
  BuildContext context,
  ItemSection itemSection,
  ItemSectionCubit itemSectionCubit,
) {
  log('_showOptionsDialog ${itemSection.id}');
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;

  showModalBottomSheet(
    context: context,
    isScrollControlled: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) {
      final t = AppLocalizations.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              Text(
                t.item_options_title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(AppIcons.image, color: scheme.primary),
                title: Text(t.action_set_as_cover),
                onTap: () async {
                  HapticFeedback.lightImpact();
                  Navigator.pop(sheetCtx);
                  final path = itemSection.filePath;
                  if (path != null && path.isNotEmpty) {
                    await context.read<SectionCubit>().updateSectionCover(
                          itemSection.idSection,
                          path,
                        );
                    UIFeedback.success(context, t.snackbar_cover_set);
                  }
                },
              ),
              ListTile(
                leading: Icon(AppIcons.edit, color: scheme.primary),
                title: Text(t.action_rename),
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(sheetCtx);
                  handleRenameItem(context, itemSection, itemSectionCubit);
                  UIFeedback.info(context, t.snackbar_rename_done);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(AppIcons.delete, color: Colors.red.shade700),
                title: Text(t.action_delete),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(sheetCtx);
                  handleDeleteItem(context, itemSection);
                  UIFeedback.error(context, t.snackbar_item_deleted);
                },
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetCtx),
                  child: Text(
                    t.action_cancel,
                    style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
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