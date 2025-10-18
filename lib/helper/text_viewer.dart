import 'dart:io';

import 'package:flutter/material.dart';

class TextViewer extends StatefulWidget {
  final String filePath;
  const TextViewer({super.key, required this.filePath});

  @override
  State<TextViewer> createState() => _TextViewerState();
}

class _TextViewerState extends State<TextViewer> {
  late Future<String> _textFuture;

  @override
  void initState() {
    super.initState();
    _textFuture = _loadText(widget.filePath);
  }

  Future<String> _loadText(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return file.readAsString();
      } else {
        return 'File not found: $path';
      }
    } catch (e) {
      return 'Error reading file: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.filePath.split(Platform.pathSeparator).last;
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName, overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: FutureBuilder<String>(
        future: _textFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final text = snapshot.data ?? '';
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SelectionArea(
              child: SingleChildScrollView(
                child: Text(
                  text,
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
