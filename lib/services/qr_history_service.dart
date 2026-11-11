// ignore: depend_on_referenced_packages
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/qr_history_model.dart';

class QRHistoryService {
  static final QRHistoryService instance = QRHistoryService._init();

  static Database? _database;

  QRHistoryService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'qr_history.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE qr_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content TEXT NOT NULL,
            qrType TEXT NOT NULL,
            actionType TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> addHistory(QRHistoryModel history) async {
    final db = await database;

    return await db.insert(
      'qr_history',
      history.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<QRHistoryModel>> getHistory({
    String? searchQuery,
    String? actionType,
  }) async {
    final db = await database;

    final conditions = <String>[];
    final arguments = <Object>[];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      conditions.add('(content LIKE ? OR qrType LIKE ?)');
      final query = '%${searchQuery.trim()}%';
      arguments.addAll([query, query]);
    }

    if (actionType != null && actionType.isNotEmpty) {
      conditions.add('actionType = ?');
      arguments.add(actionType);
    }

    final result = await db.query(
      'qr_history',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: arguments.isEmpty ? null : arguments,
      orderBy: 'createdAt DESC',
    );

    return result.map((map) => QRHistoryModel.fromMap(map)).toList();
  }

  Future<int> deleteHistory(int id) async {
    final db = await database;

    return await db.delete('qr_history', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearHistory() async {
    final db = await database;

    return await db.delete('qr_history');
  }
}
