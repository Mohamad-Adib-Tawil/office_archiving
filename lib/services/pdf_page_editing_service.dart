import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:office_archiving/services/document_storage_service.dart';
import 'package:office_archiving/services/pdf_service.dart';
import 'package:path/path.dart' as p;

class PdfEditablePage {
  const PdfEditablePage({
    required this.id,
    required this.imagePath,
    this.revision = 0,
  });

  final String id;
  final String imagePath;
  final int revision;

  PdfEditablePage copyWith({String? id, String? imagePath, int? revision}) {
    return PdfEditablePage(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      revision: revision ?? this.revision,
    );
  }
}

class PdfEditingSession {
  const PdfEditingSession({
    required this.sourcePdfPath,
    required this.workingDirectory,
    required this.pages,
  });

  final String sourcePdfPath;
  final Directory workingDirectory;
  final List<PdfEditablePage> pages;
}

class PdfPageEditingService {
  PdfPageEditingService._();

  static final PdfPageEditingService instance = PdfPageEditingService._();

  final DocumentStorageService _storageService =
      DocumentStorageService.instance;
  final PdfService _pdfService = PdfService();

  Future<PdfEditingSession> openSession(String pdfPath) async {
    final sourceFile = File(pdfPath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source PDF does not exist', pdfPath);
    }

    final temporaryRoot = await _storageService.getManagedDirectory(
      ManagedDirectory.temporary,
    );
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final workingDirectory = Directory(
      p.join(temporaryRoot.path, 'pdf_editor_$timestamp'),
    );
    await workingDirectory.create(recursive: true);

    final safeStem = _storageService.sanitizeStem(
      _storageService.fileNameStem(pdfPath),
      fallback: 'pdf',
    );
    final pageFiles = await _pdfService.rasterizePdfToImages(
      sourceFile,
      outputDir: workingDirectory,
      namePrefix: '${safeStem}_page',
      dpi: 170,
    );

    if (pageFiles.isEmpty) {
      throw const FileSystemException(
        'No readable pages were found in the PDF.',
      );
    }

    final pages = <PdfEditablePage>[
      for (var index = 0; index < pageFiles.length; index++)
        PdfEditablePage(
          id: 'page_${index + 1}_$timestamp',
          imagePath: pageFiles[index].path,
          revision: 0,
        ),
    ];

    return PdfEditingSession(
      sourcePdfPath: pdfPath,
      workingDirectory: workingDirectory,
      pages: pages,
    );
  }

  Future<void> rotatePage(
    PdfEditablePage page, {
    required bool clockwise,
  }) async {
    final file = File(page.imagePath);
    if (!await file.exists()) {
      throw FileSystemException('Page image does not exist', page.imagePath);
    }

    final bytes = await file.readAsBytes();
    final decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) {
      throw const FileSystemException('Failed to decode page image');
    }

    final rotatedImage = img.copyRotate(
      decodedImage,
      angle: clockwise ? 90 : 270,
    );
    await file.writeAsBytes(img.encodePng(rotatedImage), flush: true);
  }

  Future<File> exportPageAsImage({
    required PdfEditablePage page,
    required String baseName,
    required int pageNumber,
  }) {
    return _storageService.persistFile(
      sourcePath: page.imagePath,
      directory: ManagedDirectory.exports,
      preferredName: '${_safeBaseName(baseName)}_page_$pageNumber',
      prefix: 'page',
    );
  }

  Future<File> exportPageAsPdf({
    required PdfEditablePage page,
    required String baseName,
    required int pageNumber,
  }) {
    return _pdfService.createPdfFromImages(
      [page.imagePath],
      fileName: _buildOutputName(
        baseName: baseName,
        suffix: 'page_$pageNumber',
        extension: 'pdf',
      ),
    );
  }

  Future<File> saveEditedPdf({
    required List<PdfEditablePage> pages,
    required String baseName,
  }) async {
    if (pages.isEmpty) {
      throw ArgumentError('At least one page is required to save a PDF.');
    }

    return _pdfService.createPdfFromImages(
      pages.map((page) => page.imagePath).toList(),
      fileName: _buildOutputName(
        baseName: baseName,
        suffix: 'edited',
        extension: 'pdf',
      ),
    );
  }

  Future<void> cleanupSession(Directory? workingDirectory) async {
    if (workingDirectory == null) {
      return;
    }
    if (await workingDirectory.exists()) {
      await workingDirectory.delete(recursive: true);
    }
  }

  String _buildOutputName({
    required String baseName,
    required String suffix,
    required String extension,
  }) {
    final safeBaseName = _safeBaseName(baseName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${safeBaseName}_${suffix}_$timestamp.$extension';
  }

  String _safeBaseName(String baseName) {
    return _storageService.sanitizeStem(baseName, fallback: 'document');
  }
}
