import 'dart:io';

import 'package:intl/intl.dart';
import 'package:office_archiving/services/sqlite_service.dart';
import 'package:office_archiving/services/document_storage_service.dart';
import 'package:office_archiving/services/pdf_service.dart';

class ScanImportResult {
  const ScanImportResult({required this.savedCount, required this.savedPaths});

  final int savedCount;
  final List<String> savedPaths;
}

class ScannerImportService {
  ScannerImportService._();

  static final ScannerImportService instance = ScannerImportService._();

  final DocumentStorageService _storageService =
      DocumentStorageService.instance;

  List<String> extractPaths(dynamic rawResult) {
    final paths = <String>{};
    _collectPaths(rawResult, paths);
    return paths.toList(growable: false);
  }

  Future<ScanImportResult> importScannerResultToSection({
    required dynamic rawResult,
    required int sectionId,
    required String sectionName,
  }) async {
    final rawPaths = extractPaths(rawResult);
    if (rawPaths.isEmpty) {
      return const ScanImportResult(savedCount: 0, savedPaths: []);
    }

    final scanDirectory = await _storageService.getManagedDirectory(
      ManagedDirectory.scans,
    );
    final now = DateTime.now();
    final dateLabel = DateFormat('yyyy-MM-dd').format(now);
    final savedPaths = <String>[];
    var savedCount = 0;

    for (var index = 0; index < rawPaths.length; index++) {
      final normalizedPath = _normalizePath(rawPaths[index]);
      if (normalizedPath.isEmpty) {
        continue;
      }

      final file = File(normalizedPath);
      if (!await file.exists()) {
        continue;
      }

      final extension = _storageService.extensionOf(normalizedPath);
      if (_storageService.isPdfPath(normalizedPath)) {
        final rasterizedPages = await PdfService().rasterizePdfToImages(
          file,
          outputDir: scanDirectory,
          namePrefix: 'scan_${now.millisecondsSinceEpoch}_$index',
        );
        for (
          var pageIndex = 0;
          pageIndex < rasterizedPages.length;
          pageIndex++
        ) {
          final pageFile = rasterizedPages[pageIndex];
          final pageExtension = _storageService.extensionOf(pageFile.path);
          final itemName =
              'مستند $sectionName $dateLabel ${index + 1}-${pageIndex + 1}';
          await DatabaseService.instance.insertItem(
            itemName,
            pageFile.path,
            pageExtension,
            sectionId,
            createdAt: now.toIso8601String(),
          );
          savedPaths.add(pageFile.path);
          savedCount++;
        }
        continue;
      }

      final persistedFile = await _storageService.persistFile(
        sourcePath: normalizedPath,
        directory: ManagedDirectory.scans,
        preferredName: 'scan_${sectionName}_${dateLabel}_${index + 1}',
        prefix: 'scan',
      );
      final itemName = 'مستند $sectionName $dateLabel ${index + 1}';
      await DatabaseService.instance.insertItem(
        itemName,
        persistedFile.path,
        extension,
        sectionId,
        createdAt: now.toIso8601String(),
      );
      savedPaths.add(persistedFile.path);
      savedCount++;
    }

    return ScanImportResult(savedCount: savedCount, savedPaths: savedPaths);
  }

  String _normalizePath(String input) {
    if (input.startsWith('file://')) {
      try {
        return Uri.parse(input).toFilePath();
      } catch (_) {
        return input.replaceFirst('file://', '');
      }
    }
    return input;
  }

  void _collectPaths(dynamic value, Set<String> paths) {
    if (value == null) {
      return;
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        paths.add(trimmed);
      }
      return;
    }

    if (value is Iterable) {
      for (final item in value) {
        _collectPaths(item, paths);
      }
      return;
    }

    if (value is Map) {
      const singleKeys = ['path', 'filePath', 'imagePath', 'pdfUri'];
      const listKeys = ['paths', 'images', 'files', 'savedPaths'];

      for (final key in singleKeys) {
        _collectPaths(value[key], paths);
      }
      for (final key in listKeys) {
        _collectPaths(value[key], paths);
      }
      return;
    }

    try {
      _collectPaths((value as dynamic).path, paths);
      _collectPaths((value as dynamic).filePath, paths);
      _collectPaths((value as dynamic).imagePath, paths);
      _collectPaths((value as dynamic).pdfUri, paths);
      _collectPaths((value as dynamic).paths, paths);
      _collectPaths((value as dynamic).savedPaths, paths);
    } catch (_) {}
  }
}
