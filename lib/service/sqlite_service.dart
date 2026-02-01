import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
class DatabaseService {
  static late Database db;
  static final DatabaseService _instance = DatabaseService._();
  static bool _isInitialized = false;
  DatabaseService._();

  static DatabaseService get instance {
    if (!_isInitialized) {
      log('DatabaseService accessed before initialization!');
    }
    return _instance;
  }

  // Change notification stream for UI to react to DB mutations
  final StreamController<void> _changeController =
      StreamController<void>.broadcast();
  Stream<void> get changes => _changeController.stream;
  void _notifyChange() {
    if (!_changeController.isClosed) {
      _changeController.add(null);
    }
  }

  static Future<void> initDatabase() async {
    log('initDatabase');
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, 'office_archiving.db');
    db = await openDatabase(path, readOnly: false);

    await db.execute('''
      CREATE TABLE IF NOT EXISTS section (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');
    // Migration: add coverPath column if missing
    try {
      final columns = await db.rawQuery("PRAGMA table_info('section')");
      final hasCover = columns.any((c) => c['name'] == 'coverPath');
      if (!hasCover) {
        await db.execute("ALTER TABLE section ADD COLUMN coverPath TEXT");
      }
    } catch (e) {
      log('section coverPath migration error: $e');
    }
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        filePath TEXT NOT NULL,
        fileType TEXT NOT NULL,
        sectionId INTEGER NOT NULL,
        FOREIGN KEY(sectionId) REFERENCES section(id)
      )
    ''');
    // Migration: add OCR columns if missing
    try {
      final columns = await db.rawQuery("PRAGMA table_info('items')");
      bool hasOcrText = columns.any((c) => c['name'] == 'ocrText');
      bool hasOcrLang = columns.any((c) => c['name'] == 'ocrLang');
      bool hasOcrProcessedAt = columns.any((c) => c['name'] == 'ocrProcessedAt');
      bool hasOcrHasText = columns.any((c) => c['name'] == 'ocrHasText');
      bool hasCreatedAt = columns.any((c) => c['name'] == 'createdAt');
      
      if (!hasOcrText) {
        await db.execute("ALTER TABLE items ADD COLUMN ocrText TEXT");
      }
      if (!hasOcrLang) {
        await db.execute("ALTER TABLE items ADD COLUMN ocrLang TEXT");
      }
      if (!hasOcrProcessedAt) {
        await db.execute("ALTER TABLE items ADD COLUMN ocrProcessedAt TEXT");
      }
      if (!hasOcrHasText) {
        await db.execute("ALTER TABLE items ADD COLUMN ocrHasText INTEGER DEFAULT 0");
      }
      if (!hasCreatedAt) {
        await db.execute("ALTER TABLE items ADD COLUMN createdAt TEXT");
      }
    } catch (e) {
      log('items columns migration error: $e');
    }
    // Ensure helpful indexes exist for performance
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_items_sectionId ON items(sectionId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_items_name ON items(name)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_items_filePath ON items(filePath)');
    } catch (e) {
      log('create indexes error: $e');
    }
    
    _isInitialized = true;
    log('Database initialized successfully');
  }

  Future<List<Map<String, dynamic>>> getAllSections() async {
    log('databse getAllSections');
    List<Map<String, dynamic>> sections = await db.query('section');
    log('databse getAllSections sections ::: $sections');
    return sections;
  }

  Future<int> insertSection(String name) async {
    log('insertSection $name');
    
    List<Map<String, dynamic>> existingSections = await db.query(
      'section',
      where: 'name = ?',
      whereArgs: [name],
    );

    if (existingSections.isNotEmpty) {
      log('existingSections.isNotEmpty ${existingSections.isNotEmpty}');
      return -1;
    } else {
      final id = await db.insert('section', {'name': name});
      _notifyChange();
      return id;
    }
  }

  Future<void> updateSectionName(int id, String newName) async {
    log('updateSectionName ::: $newName');
    int index = await db.update('section', {'name': newName},
        where: 'id = ?', whereArgs: [id]);
    log('updateSectionName :::  index = $index');
    log('updateSectionName ::: new name $newName');
    await getAllSections();
    _notifyChange();
  }

  Future<void> updateSectionCover(int id, String? coverPath) async {
    log('updateSectionCover id=$id coverPath=$coverPath');
    await db.update('section', {'coverPath': coverPath}, where: 'id = ?', whereArgs: [id]);
    _notifyChange();
  }

  Future<void> deleteSection(int id) async {
    log('deleteSection $id');
    // First delete all items that belong to this section to avoid orphans
    await db.delete('items', where: 'sectionId = ?', whereArgs: [id]);
    // Then delete the section itself
    await db.delete('section', where: 'id = ?', whereArgs: [id]);
    _notifyChange();
  }

  Future<List<Map<String, dynamic>>> getItemsBySectionId(int sectionId, {int? limit, int? offset}) async {
    return await db.query(
      'items',
      where: 'sectionId = ?',
      whereArgs: [sectionId],
      orderBy: 'createdAt DESC', // أحدث أولاً
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> getAllItems() async {
    return await db.query('items');
  }

  Future<String?> getLatestImagePathForSection(int sectionId) async {
    // Assuming fileType holds extensions like 'jpg', 'png', etc.
    final rows = await db.query(
      'items',
      columns: ['filePath'],
      where: 'sectionId = ? AND (fileType IN ("jpg","jpeg","png","gif","webp","image"))',
      whereArgs: [sectionId],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (rows.isNotEmpty) return rows.first['filePath'] as String?;
    return null;
  }

  Future<String?> getSectionCoverOrLatest(int sectionId) async {
    final coverRows = await db.query('section', columns: ['coverPath'], where: 'id = ?', whereArgs: [sectionId]);
    if (coverRows.isNotEmpty) {
      final cover = coverRows.first['coverPath'] as String?;
      if (cover != null && cover.isNotEmpty) return cover;
    }
    return getLatestImagePathForSection(sectionId);
  }

  Future<int> insertItem(
      String name, String filePath, String fileType, int sectionId, {String? createdAt}) async {
    final id = await db.insert('items', {
      'name': name,
      'filePath': filePath,
      'fileType': fileType,
      'sectionId': sectionId,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
    });
    _notifyChange();
    return id;
  }

  Future<void> updateItemName(int id, String newName) async {
    log('updateItemName');
    await db.update('items', {'name': newName},
        where: 'id = ?', whereArgs: [id]);
    _notifyChange();
  }

  Future<void> deleteItem(int id) async {
    log('deleteItem');
    await db.delete('items', where: 'id = ?', whereArgs: [id]);
    _notifyChange();
  }

  /// Delete an item and fix its section metadata.
  /// - Removes the item row.
  /// - If the section's coverPath equals the item's filePath, clears the coverPath.
  Future<void> deleteItemAndFixSection(int id) async {
    log('deleteItemAndFixSection id=$id');
    try {
      // Read item before deletion to get sectionId and filePath
      final rows = await db.query(
        'items',
        columns: ['sectionId', 'filePath'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      int? sectionId;
      String? filePath;
      if (rows.isNotEmpty) {
        sectionId = rows.first['sectionId'] as int?;
        filePath = rows.first['filePath'] as String?;
      }

      // Delete the item
      await db.delete('items', where: 'id = ?', whereArgs: [id]);

      // If section cover equals this file, clear it
      if (sectionId != null && filePath != null) {
        final coverRows = await db.query(
          'section',
          columns: ['coverPath'],
          where: 'id = ?',
          whereArgs: [sectionId],
          limit: 1,
        );
        if (coverRows.isNotEmpty) {
          final cover = coverRows.first['coverPath'] as String?;
          if (cover == filePath) {
            await db.update(
              'section',
              {'coverPath': null},
              where: 'id = ?',
              whereArgs: [sectionId],
            );
            log('Cleared section($sectionId) coverPath because file was deleted');
          }
        }
      }
      _notifyChange();
    } catch (e) {
      log('deleteItemAndFixSection error: $e');
      rethrow;
    }
  }

  /// Unified delete: removes the item, optionally fixes section cover, and deletes the file on disk.
  Future<void> deleteItemWithFile(
    int id, {
    bool fixSectionCover = true,
    bool deleteFile = true,
  }) async {
    log('deleteItemWithFile id=$id');
    try {
      // Fetch item details before deletion
      final rows = await db.query(
        'items',
        columns: ['sectionId', 'filePath'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      int? sectionId;
      String? filePath;
      if (rows.isNotEmpty) {
        sectionId = rows.first['sectionId'] as int?;
        filePath = rows.first['filePath'] as String?;
      }

      // Delete the DB row
      await db.delete('items', where: 'id = ?', whereArgs: [id]);

      // Optionally fix section cover if it points to this file
      if (fixSectionCover && sectionId != null && filePath != null) {
        final coverRows = await db.query(
          'section',
          columns: ['coverPath'],
          where: 'id = ?',
          whereArgs: [sectionId],
          limit: 1,
        );
        if (coverRows.isNotEmpty) {
          final cover = coverRows.first['coverPath'] as String?;
          if (cover == filePath) {
            await db.update(
              'section',
              {'coverPath': null},
              where: 'id = ?',
              whereArgs: [sectionId],
            );
            log('Cleared section($sectionId) coverPath because file was deleted');
          }
        }
      }

      // Optionally delete the on-disk file
      if (deleteFile && filePath != null && filePath.isNotEmpty) {
        try {
          final f = File(filePath);
          if (await f.exists()) {
            await f.delete();
          }
        } catch (e) {
          log('deleteItemWithFile: failed to delete file $filePath: $e');
        }
      }

      _notifyChange();
    } catch (e) {
      log('deleteItemWithFile error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchItemsByName(String query) async {
    return await db.query(
      'items',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
  }

  // Save OCR result for an item
  Future<void> updateItemOcr(
    int id, {
    required String ocrText,
    String? ocrLang,
    bool? hasText,
    DateTime? processedAt,
  }) async {
    await db.update(
      'items',
      {
        'ocrText': ocrText,
        'ocrLang': ocrLang,
        'ocrHasText': (hasText ?? ocrText.trim().isNotEmpty) ? 1 : 0,
        'ocrProcessedAt': (processedAt ?? DateTime.now()).toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    _notifyChange();
  }

  // Items missing OCR (either null or empty text)
  Future<List<Map<String, dynamic>>> getItemsMissingOcr({int? limit}) async {
    return await db.query(
      'items',
      where: '(ocrText IS NULL OR ocrText = "")',
      limit: limit,
    );
  }

  // Search within OCR text
  Future<List<Map<String, dynamic>>> searchByOcrText(String query) async {
    return await db.query(
      'items',
      where: 'ocrText LIKE ?',
      whereArgs: ['%$query%'],
    );
  }

  // Search by name or OCR text
  Future<List<Map<String, dynamic>>> searchByNameOrOcr(String query) async {
    return await db.query(
      'items',
      where: 'name LIKE ? OR ocrText LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
  }

  Future<Map<String, dynamic>?> getItemByFilePath(String filePath) async {
    final rows = await db.query('items', where: 'filePath = ?', whereArgs: [filePath], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<List<Map<String, dynamic>>> searchByNameOrOcrInSection(String query, int sectionId) async {
    return await db.query(
      'items',
      where: '(name LIKE ? OR ocrText LIKE ?) AND sectionId = ?',
      whereArgs: ['%$query%', '%$query%', sectionId],
    );
  }

  /// Search items by name within a specific section
  Future<List<Map<String, dynamic>>> searchItemsByNameInSection(
      String query, int sectionId) async {
    return await db.query(
      'items',
      where: 'name LIKE ? AND sectionId = ?',
      whereArgs: ['%$query%', sectionId],
    );
  }

  // Get document count for a specific section
  Future<int> getDocumentCountBySection(int sectionId) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM items WHERE sectionId = ?',
      [sectionId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Analytics methods
  Future<Map<String, dynamic>> getStorageAnalytics() async {
    // Totals
    final totalFiles = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM items')) ?? 0;
    final totalSections = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM section')) ?? 0;

    // File type distribution
    final fileTypeRows = await db.rawQuery('SELECT fileType, COUNT(*) as count FROM items GROUP BY fileType ORDER BY count DESC');
    final Map<String, int> fileTypeCount = {
      for (var r in fileTypeRows) (r['fileType'] as String): r['count'] as int
    };

    // Recent activity (last 7 days) based on createdAt
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    final rows = await db.query(
      'items',
      columns: ['createdAt', 'filePath'],
      where: 'createdAt IS NOT NULL AND createdAt >= ?',
      whereArgs: [sevenDaysAgo.toIso8601String()],
    );
    // Initialize buckets per day (YYYY-MM-DD)
    final Map<String, Map<String, num>> buckets = {};
    for (int i = 0; i < 7; i++) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
      final key = d.toIso8601String().substring(0, 10);
      buckets[key] = {'filesAdded': 0, 'sizeAdded': 0};
    }
    for (final r in rows) {
      final createdAt = r['createdAt'] as String?;
      final filePath = r['filePath'] as String?;
      if (createdAt == null) continue;
      final dayKey = createdAt.substring(0, 10);
      if (!buckets.containsKey(dayKey)) continue;
      buckets[dayKey]!['filesAdded'] = (buckets[dayKey]!['filesAdded'] as int) + 1;
      // Approximate size by file length if exists
      if (filePath != null) {
        try {
          final f = File(filePath);
          if (f.existsSync()) {
            buckets[dayKey]!['sizeAdded'] = (buckets[dayKey]!['sizeAdded'] as num) + f.lengthSync();
          }
        } catch (_) {}
      }
    }
    final List<Map<String, dynamic>> dailyUsage = buckets.entries.map((e) {
      final dateIso = '${e.key}T00:00:00.000';
      return {
        'date': dateIso,
        'filesAdded': e.value['filesAdded'],
        'sizeAdded': e.value['sizeAdded'],
      };
    }).toList();

    // Popular files placeholder (no access metric yet)
    final previewItems = await db.query('items', limit: 5);
    final List<Map<String, dynamic>> popularFiles = [
      for (int i = 0; i < previewItems.length; i++)
        {
          'name': previewItems[i]['name'],
          'type': previewItems[i]['fileType'],
          'accessCount': 0,
          'lastAccessed': now.toIso8601String(),
        }
    ];

    // Total size bytes (approximate by summing current files)
    num totalSizeBytes = 0;
    try {
      final all = await db.query('items', columns: ['filePath']);
      for (final r in all) {
        final p = r['filePath'] as String?;
        if (p == null) continue;
        try {
          final f = File(p);
          if (f.existsSync()) totalSizeBytes += f.lengthSync();
        } catch (_) {}
      }
    } catch (_) {}

    return {
      'totalFiles': totalFiles,
      'totalSections': totalSections,
      'totalSizeBytes': totalSizeBytes,
      'fileTypeCount': fileTypeCount,
      'dailyUsage': dailyUsage,
      'mostAccessedFiles': popularFiles,
    };
  }

  Future<void> dispose() async {
    log('dispose DataBase');
    await db.close();
    await _changeController.close();
  }
}