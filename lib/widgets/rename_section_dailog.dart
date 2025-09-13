import 'dart:developer';

import 'package:flutter/material.dart';

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
      title: const Text('Rename Section'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(labelText: 'New Name'),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
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
          child: const Text('Rename'),
        ),
      ],
    );
  }
}
