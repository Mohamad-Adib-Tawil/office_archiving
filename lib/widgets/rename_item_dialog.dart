import 'dart:developer';

import 'package:flutter/material.dart';

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
    return AlertDialog(
      title: const Text('Rename item'),
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
              Navigator.of(context).pop(newName);
            }
          },
          child: const Text('Rename'),
        ),
      ],
    );
  }
}
