import 'package:flutter_test/flutter_test.dart';
import 'package:office_archiving/services/document_storage_service.dart';

void main() {
  test('sanitizeStem removes unsafe characters and preserves Arabic text', () {
    final storage = DocumentStorageService.instance;

    expect(
      storage.sanitizeStem('  Invoice #2026 / نسخة  '),
      'Invoice_2026_نسخة',
    );
  });
}
