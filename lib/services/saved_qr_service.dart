// ignore: depend_on_referenced_packages
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/saved_qr_model.dart';

class SavedQRService {
  static final SavedQRService instance = SavedQRService._init();

  static Database? _database;

  SavedQRService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'saved_qr.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
      CREATE TABLE saved_qr (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL UNIQUE,
        qrType TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isFavorite INTEGER NOT NULL DEFAULT 0
      )
    ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
        ALTER TABLE saved_qr
        ADD COLUMN isFavorite INTEGER NOT NULL DEFAULT 0
      ''');
        }
      },
    );
  }

  Future<bool> saveQR(SavedQRModel qr) async {
    final db = await database;

    final existing = await db.query(
      'saved_qr',
      columns: ['id'],
      where: 'content = ?',
      whereArgs: [qr.content],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return false;
    }

    await db.insert(
      'saved_qr',
      qr.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    return true;
  }

  Future<List<SavedQRModel>> getSavedQRs({String? searchQuery}) async {
    final db = await database;

    final result = await db.query(
      'saved_qr',
      where: searchQuery != null && searchQuery.trim().isNotEmpty
          ? '(content LIKE ? OR qrType LIKE ?)'
          : null,
      whereArgs: searchQuery != null && searchQuery.trim().isNotEmpty
          ? ['%${searchQuery.trim()}%', '%${searchQuery.trim()}%']
          : null,
      orderBy: 'createdAt DESC',
    );

    return result.map((map) => SavedQRModel.fromMap(map)).toList();
  }

  Future<int> deleteSavedQR(int id) async {
    final db = await database;

    return await db.delete('saved_qr', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearSavedQRs() async {
    final db = await database;

    return await db.delete('saved_qr');
  }

  Future<bool> isSaved(String content) async {
    final db = await database;

    final result = await db.query(
      'saved_qr',
      columns: ['id'],
      where: 'content = ?',
      whereArgs: [content],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // Add or remove a QR code from favorites.
  Future<void> toggleFavorite(int id, bool isFavorite) async {
    final db = await database;

    await db.update(
      'saved_qr',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get only favorite QR codes.
  Future<List<SavedQRModel>> getFavoriteQRs({String? searchQuery}) async {
    final db = await database;

    final result = await db.query(
      'saved_qr',
      where: searchQuery != null && searchQuery.trim().isNotEmpty
          ? 'isFavorite = 1 AND (content LIKE ? OR qrType LIKE ?)'
          : 'isFavorite = 1',
      whereArgs: searchQuery != null && searchQuery.trim().isNotEmpty
          ? ['%${searchQuery.trim()}%', '%${searchQuery.trim()}%']
          : null,
      orderBy: 'createdAt DESC',
    );

    return result.map((map) => SavedQRModel.fromMap(map)).toList();
  }

  // Check whether a QR code is a favorite.
  Future<bool> isFavorite(int id) async {
    final db = await database;

    final result = await db.query(
      'saved_qr',
      columns: ['isFavorite'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return result.isNotEmpty && result.first['isFavorite'] == 1;
  }
}
