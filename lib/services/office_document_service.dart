import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:office_archiving/services/document_storage_service.dart';

/// إنشاء مستندات مكتبية جديدة (نص / Word / Excel) وحفظها كملفات داخل التطبيق.
class OfficeDocumentService {
  OfficeDocumentService._();

  static final OfficeDocumentService instance = OfficeDocumentService._();

  final DocumentStorageService _storage = DocumentStorageService.instance;

  /// إنشاء/تحديث ملف نصّي `.txt`.
  /// إذا مُرّر [existingPath] تُكتب نفس الملف (تعديل) بدل إنشاء ملف جديد.
  Future<File> createOrUpdateTextFile({
    required String title,
    required String body,
    String? existingPath,
  }) async {
    final bytes = utf8.encode(body);
    if (existingPath != null && existingPath.isNotEmpty) {
      final file = File(existingPath);
      await file.writeAsBytes(bytes, flush: true);
      return file;
    }
    return _storage.writeBytes(
      bytes: bytes,
      directory: ManagedDirectory.imports,
      fileName: '${_safe(title, 'document')}.txt',
    );
  }

  /// إنشاء أو تحديث ملف Word `.docx` من عنوان وفقرات.
  /// إذا مُرّر [existingPath] يُعاد كتابة نفس الملف.
  Future<File> createWordFile({
    required String title,
    required List<String> paragraphs,
    String? existingPath,
  }) async {
    final bytes = _buildDocx(title: title, paragraphs: paragraphs);
    if (existingPath != null && existingPath.isNotEmpty) {
      final file = File(existingPath);
      await file.writeAsBytes(bytes, flush: true);
      return file;
    }
    return _storage.writeBytes(
      bytes: bytes,
      directory: ManagedDirectory.imports,
      fileName: '${_safe(title, 'document')}.docx',
    );
  }

  /// إنشاء أو تحديث ملف Excel `.xlsx` من جدول صفوف وأعمدة نصّية.
  /// إذا مُرّر [existingPath] يُعاد كتابة نفس الملف.
  Future<File> createExcelFile({
    required String title,
    required List<List<String>> rows,
    String? existingPath,
  }) async {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    final sheet = excel['Sheet1'];
    for (var r = 0; r < rows.length; r++) {
      final row = rows[r];
      for (var c = 0; c < row.length; c++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r),
        );
        cell.value = TextCellValue(row[c]);
      }
    }
    // إزالة الورقة الافتراضية إن اختلف اسمها عن Sheet1.
    if (defaultSheet != null && defaultSheet != 'Sheet1') {
      excel.delete(defaultSheet);
    }
    final bytes = excel.save() ?? <int>[];
    if (existingPath != null && existingPath.isNotEmpty) {
      final file = File(existingPath);
      await file.writeAsBytes(bytes, flush: true);
      return file;
    }
    return _storage.writeBytes(
      bytes: bytes,
      directory: ManagedDirectory.imports,
      fileName: '${_safe(title, 'spreadsheet')}.xlsx',
    );
  }

  String _safe(String raw, String fallback) =>
      _storage.sanitizeStem(raw, fallback: fallback);

  // ===== قرّاء المستندات (عرض داخل التطبيق) =====

  /// قراءة فقرات ملف Word `.docx` كنصوص (لأغراض العرض فقط).
  Future<List<String>> readDocxParagraphs(String path) async {
    final bytes = await File(path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    ArchiveFile? docFile;
    for (final f in archive.files) {
      if (f.name == 'word/document.xml') {
        docFile = f;
        break;
      }
    }
    if (docFile == null) return const [];
    final xmlString = utf8.decode(docFile.content as List<int>);
    final paragraphs = <String>[];
    // كل <w:p> ... </w:p> فقرة، ونجمع نصوص <w:t> بداخلها.
    final pRegex = RegExp(r'<w:p[ >].*?</w:p>', dotAll: true);
    final tRegex = RegExp(r'<w:t[^>]*>(.*?)</w:t>', dotAll: true);
    for (final pMatch in pRegex.allMatches(xmlString)) {
      final pXml = pMatch.group(0)!;
      final buffer = StringBuffer();
      for (final tMatch in tRegex.allMatches(pXml)) {
        buffer.write(_unescapeXml(tMatch.group(1) ?? ''));
      }
      paragraphs.add(buffer.toString());
    }
    return paragraphs;
  }

  /// قراءة أوّل ورقة من ملف Excel `.xlsx` كصفوف نصّية (لأغراض العرض فقط).
  Future<List<List<String>>> readExcelRows(String path) async {
    final bytes = await File(path).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return const [];
    final sheet = excel.tables.values.first;
    final rows = <List<String>>[];
    for (final row in sheet.rows) {
      rows.add(
        row.map((cell) => cell?.value?.toString() ?? '').toList(),
      );
    }
    return rows;
  }

  String _unescapeXml(String input) => input
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');

  // ----- بناء OOXML بسيط لملف docx -----
  List<int> _buildDocx({
    required String title,
    required List<String> paragraphs,
  }) {
    final body = StringBuffer();
    if (title.trim().isNotEmpty) {
      body.write(_docParagraph(title, bold: true, sizeHalfPoints: 36));
    }
    for (final para in paragraphs) {
      body.write(_docParagraph(para));
    }

    final documentXml =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
        '<w:body>$body'
        '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/>'
        '<w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"/>'
        '</w:sectPr></w:body></w:document>';

    const contentTypes =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
        '</Types>';

    const rels =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
        '</Relationships>';

    final archive = Archive()
      ..addFile(_archiveFile('[Content_Types].xml', contentTypes))
      ..addFile(_archiveFile('_rels/.rels', rels))
      ..addFile(_archiveFile('word/document.xml', documentXml));

    return ZipEncoder().encode(archive) ?? <int>[];
  }

  String _docParagraph(
    String text, {
    bool bold = false,
    int sizeHalfPoints = 24,
  }) {
    final runProps = StringBuffer('<w:rPr>')
      ..write(bold ? '<w:b/>' : '')
      ..write('<w:sz w:val="$sizeHalfPoints"/>')
      ..write('</w:rPr>');
    return '<w:p><w:r>$runProps'
        '<w:t xml:space="preserve">${_escapeXml(text)}</w:t>'
        '</w:r></w:p>';
  }

  ArchiveFile _archiveFile(String name, String content) {
    final data = utf8.encode(content);
    return ArchiveFile(name, data.length, data);
  }

  String _escapeXml(String input) => input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
