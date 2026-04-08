import 'dart:io';

import 'package:media_store_plus/media_store_plus.dart';
import 'package:office_archiving/constants.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum ManagedDirectory {
  imports('imports'),
  scans('scans'),
  exports('exports'),
  signatures('signatures'),
  temporary('tmp');

  const ManagedDirectory(this.folderName);

  final String folderName;
}

class DocumentStorageService {
  DocumentStorageService._();

  static final DocumentStorageService instance = DocumentStorageService._();

  static const Set<String> imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'heic',
    'heif',
  };

  static const Set<String> pdfExtensions = {'pdf'};

  String extensionOf(String path) {
    final extension = p.extension(path).trim().toLowerCase();
    if (extension.startsWith('.')) {
      return extension.substring(1);
    }
    return extension;
  }

  bool isImagePath(String path) => imageExtensions.contains(extensionOf(path));

  bool isPdfPath(String path) => pdfExtensions.contains(extensionOf(path));

  bool supportsOcr(String path) => isImagePath(path) || isPdfPath(path);

  String fileNameStem(String path) => p.basenameWithoutExtension(path);

  String sanitizeStem(String raw, {String fallback = 'document'}) {
    final sanitized = raw
        .trim()
        .replaceAll(RegExp(r'[^\w\u0600-\u06FF\-\s]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    if (sanitized.isEmpty) {
      return fallback;
    }

    if (sanitized.length <= 80) {
      return sanitized;
    }

    return sanitized.substring(0, 80);
  }

  Future<Directory> getRootDirectory() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final rootDirectory = Directory(
      p.join(documentsDirectory.path, kOfficeArchiving),
    );
    if (!await rootDirectory.exists()) {
      await rootDirectory.create(recursive: true);
    }
    return rootDirectory;
  }

  Future<Directory> getManagedDirectory(ManagedDirectory directory) async {
    final rootDirectory = await getRootDirectory();
    final managedDirectory = Directory(
      p.join(rootDirectory.path, directory.folderName),
    );
    if (!await managedDirectory.exists()) {
      await managedDirectory.create(recursive: true);
    }
    return managedDirectory;
  }

  Future<File> persistFile({
    required String sourcePath,
    required ManagedDirectory directory,
    String? preferredName,
    String? prefix,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source file does not exist', sourcePath);
    }

    final extension = extensionOf(sourcePath);
    final targetDirectory = await getManagedDirectory(directory);
    final safeStem = sanitizeStem(
      preferredName ?? fileNameStem(sourcePath),
      fallback: prefix ?? 'document',
    );
    final fileName = extension.isEmpty
        ? '${safeStem}_${DateTime.now().millisecondsSinceEpoch}'
        : '${safeStem}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final targetPath = p.join(targetDirectory.path, fileName);

    if (p.equals(sourceFile.absolute.path, targetPath)) {
      return sourceFile;
    }

    return sourceFile.copy(targetPath);
  }

  Future<File> writeBytes({
    required List<int> bytes,
    required ManagedDirectory directory,
    required String fileName,
  }) async {
    final targetDirectory = await getManagedDirectory(directory);
    final extension = extensionOf(fileName);
    final safeStem = sanitizeStem(
      p.basenameWithoutExtension(fileName),
      fallback: 'document',
    );
    final normalizedName = extension.isEmpty
        ? safeStem
        : '$safeStem.$extension';
    final targetFile = File(p.join(targetDirectory.path, normalizedName));
    await targetFile.writeAsBytes(bytes, flush: true);
    return targetFile;
  }

  Future<List<String>> saveImagesToGallery(Iterable<String> imagePaths) async {
    final savedPaths = <String>[];

    for (final imagePath in imagePaths) {
      final imageFile = File(imagePath);
      if (!await imageFile.exists() || !isImagePath(imagePath)) {
        continue;
      }

      if (Platform.isAndroid) {
        await MediaStore.ensureInitialized();
        MediaStore.appFolder = kOfficeArchiving;
        final mediaStore = MediaStore();
        final temporaryCopy = await persistFile(
          sourcePath: imagePath,
          directory: ManagedDirectory.temporary,
          preferredName: fileNameStem(imagePath),
          prefix: 'gallery',
        );
        final saveInfo = await mediaStore.saveFile(
          tempFilePath: temporaryCopy.path,
          dirType: DirType.photo,
          dirName: DirName.pictures,
        );
        if (saveInfo != null) {
          savedPaths.add(
            p.join(
              DirType.photo.fullPath(
                relativePath: kOfficeArchiving,
                dirName: DirName.pictures,
              ),
              saveInfo.name,
            ),
          );
        }
        continue;
      }

      final exportedCopy = await persistFile(
        sourcePath: imagePath,
        directory: ManagedDirectory.exports,
        preferredName: fileNameStem(imagePath),
        prefix: 'gallery',
      );
      savedPaths.add(exportedCopy.path);
    }

    return savedPaths;
  }

  Future<File> exportFileToDownloads(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source file does not exist', sourcePath);
    }

    if (!Platform.isAndroid) {
      return persistFile(
        sourcePath: sourcePath,
        directory: ManagedDirectory.exports,
        preferredName: fileNameStem(sourcePath),
        prefix: 'export',
      );
    }

    await MediaStore.ensureInitialized();
    MediaStore.appFolder = kOfficeArchiving;
    final mediaStore = MediaStore();
    final temporaryCopy = await persistFile(
      sourcePath: sourcePath,
      directory: ManagedDirectory.temporary,
      preferredName: fileNameStem(sourcePath),
      prefix: 'export',
    );
    final saveInfo = await mediaStore.saveFile(
      tempFilePath: temporaryCopy.path,
      dirType: DirType.download,
      dirName: DirName.download,
    );

    if (saveInfo == null) {
      throw const FileSystemException('Failed to export file to downloads');
    }

    return File(
      p.join(
        DirType.download.fullPath(
          relativePath: kOfficeArchiving,
          dirName: DirName.download,
        ),
        saveInfo.name,
      ),
    );
  }
}
