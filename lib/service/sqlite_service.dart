import 'dart:developer';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static late Database db;
  static final DatabaseService _instance = DatabaseService._();
  DatabaseService._();
  static DatabaseService get instance => _instance;

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
  }

  Future<List<Map<String, dynamic>>> getAllSections() async {
    log('databse getAllSections');
    await initDatabase();
    List<Map<String, dynamic>> sections = await db.query('section');
    log('databse getAllSections sections ::: $sections');
    return sections;
  }

  Future<int> insertSection(String name) async {
    log('insertSection $name');
    await initDatabase();

    List<Map<String, dynamic>> existingSections = await db.query(
      'section',
      where: 'name = ?',
      whereArgs: [name],
    );

    if (existingSections.isNotEmpty) {
      log('existingSections.isNotEmpty ${existingSections.isNotEmpty}');
      return -1;
    } else {
      return await db.insert('section', {'name': name});
    }
  }

  Future<void> updateSectionName(int id, String newName) async {
    log('updateSectionName ::: $newName');
    await initDatabase();
    int index = await db.update('section', {'name': newName},
        where: 'id = ?', whereArgs: [id]);
    log('updateSectionName :::  index = $index');
    log('updateSectionName ::: new name $newName');
    await getAllSections();
  }

  Future<void> updateSectionCover(int id, String? coverPath) async {
    log('updateSectionCover id=$id coverPath=$coverPath');
    await initDatabase();
    await db.update('section', {'coverPath': coverPath}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteSection(int id) async {
    log('deleteSection $id');
    await initDatabase();
    // First delete all items that belong to this section to avoid orphans
    await db.delete('items', where: 'sectionId = ?', whereArgs: [id]);
    // Then delete the section itself
    await db.delete('section', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getItemsBySectionId(int sectionId) async {
    await initDatabase();
    return await db
        .query('items', where: 'sectionId = ?', whereArgs: [sectionId]);
  }

  Future<String?> getLatestImagePathForSection(int sectionId) async {
    await initDatabase();
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
    await initDatabase();
    final coverRows = await db.query('section', columns: ['coverPath'], where: 'id = ?', whereArgs: [sectionId]);
    if (coverRows.isNotEmpty) {
      final cover = coverRows.first['coverPath'] as String?;
      if (cover != null && cover.isNotEmpty) return cover;
    }
    return getLatestImagePathForSection(sectionId);
  }

  Future<int> insertItem(
      String name, String filePath, String fileType, int sectionId) async {
    await initDatabase();
    return await db.insert('items', {
      'name': name,
      'filePath': filePath,
      'fileType': fileType,
      'sectionId': sectionId
    });
  }

  Future<void> updateItemName(int id, String newName) async {
    log('updateItemName');
    await initDatabase();
    await db.update('items', {'name': newName},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteItem(int id) async {
    log('deleteItem');
    await initDatabase();
    await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> searchItemsByName(String query) async {
    await initDatabase();
    return await db.query(
      'items',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
  }

  /// Search items by name within a specific section
  Future<List<Map<String, dynamic>>> searchItemsByNameInSection(
      String query, int sectionId) async {
    await initDatabase();
    return await db.query(
      'items',
      where: 'name LIKE ? AND sectionId = ?',
      whereArgs: ['%$query%', sectionId],
    );
  }

  Future<void> dispose() async {
    log('dispose DataBase');
    await db.close();
  }
}