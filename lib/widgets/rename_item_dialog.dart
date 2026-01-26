import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:office_archiving/constants.dart';
import 'package:office_archiving/l10n/app_localizations.dart';
import 'package:office_archiving/theme/app_icons.dart';

class RenameItemDialog extends StatefulWidget {
  const RenameItemDialog({
    super.key,
  });
  @override
  State<RenameItemDialog> createState() => _RenameItemDialogState();
}

class _RenameItemDialogState extends State<RenameItemDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    log("_controller $_controller");
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    String? errorText;

    void submit() {
      FocusScope.of(context).unfocus();
      final newName = _controller.text.trim();
      log('Rename dialog submit: $newName');
      if (newName.isEmpty) {
        setState(() => errorText = t.nameRequired);
        return;
      }
      Navigator.of(context).pop(newName);
    }

    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
      ),
      titlePadding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      contentPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: Icon(AppIcons.rename, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              t.renameItemTitle,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => submit(),
            decoration: InputDecoration(
              labelText: t.newNameLabel,
              hintText: t.newNameLabel,
              errorText: errorText,
              prefixIcon: const Icon(AppIcons.edit),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: Text(t.cancel),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: submit,
                  icon: const Icon(AppIcons.check),
                  label: Text(t.renameAction),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
