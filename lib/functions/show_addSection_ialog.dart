import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:office_archiving/cubit/section_cubit/section_cubit.dart';
import 'package:office_archiving/constants.dart';
import 'package:office_archiving/l10n/app_localizations.dart';

void showAddSectionDialog(
  BuildContext context,
  TextEditingController sectionNameController,
  SectionCubit sectionCubit,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      final theme = Theme.of(context);
      return StatefulBuilder(
        builder: (context, setState) {
          bool isSubmitting = false;
          String? errorText;

          Future<void> submit() async {
            FocusScope.of(context).unfocus();
            final name = sectionNameController.text.trim();
            if (name.isEmpty) {
              setState(() => errorText = AppLocalizations.of(context).sectionNameRequired);
              return;
            }
            setState(() {
              isSubmitting = true;
              errorText = null;
            });
            try {
              String? message = await sectionCubit.addSection(name);
              if (!context.mounted) return;
              
              if (message != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              } else {
                Navigator.pop(context);
              }
            } catch (e) {
              log('addSection error: $e');
              if (!context.mounted) return;
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            } finally {
              setState(() => isSubmitting = false);
              sectionNameController.clear();
            }
          }

          return AlertDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
            ),
            titlePadding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            contentPadding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.folder_copy_rounded, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).addSectionTitle,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField
                  (
                    controller: sectionNameController,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => submit(),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).sectionNameLabel,
                      hintText: AppLocalizations.of(context).sectionNameLabel,
                      errorText: errorText,
                      prefixIcon: const Icon(Icons.drive_file_rename_outline),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSubmitting ? null : () {
                            sectionNameController.clear();
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                          ),
                          child: Text(AppLocalizations.of(context).cancel),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isSubmitting ? null : submit,
                          icon: isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_rounded),
                          label: Text(AppLocalizations.of(context).addAction),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
