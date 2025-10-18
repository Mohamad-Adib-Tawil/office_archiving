import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:office_archiving/l10n/app_localizations.dart';

class RenameSectionDialog extends StatefulWidget {
  const RenameSectionDialog({
    super.key,
  });

  @override
  State<RenameSectionDialog> createState() => _RenameSectionDialogState();
}

class _RenameSectionDialogState extends State<RenameSectionDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    log("_controller $_controller");
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context).rename_section_title),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(labelText: AppLocalizations.of(context).new_name_label),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context).cancel),
        ),
        TextButton(
          onPressed: () {
            String newName = _controller.text.trim();
            log("AlertDialog rename newName $newName");

            if (newName.isNotEmpty) {
              Navigator.of(context)
                  .pop(newName); // Pass the new name back to the caller
            }
          },
          child: Text(AppLocalizations.of(context).renameAction),
        ),
      ],
    );
  }
}
