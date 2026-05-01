import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/asset.dart';
import '../models/transaction.dart' as model;

class AppDatabase {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'walletmanage.db');
    return openDatabase(path, version: 2,
      onCreate: (db, _) async {
        await db.execute('CREATE TABLE assets(id TEXT PRIMARY KEY, name TEXT, type INTEGER, balance REAL, currency TEXT, note TEXT, updatedAt INTEGER)');
        await db.execute('CREATE TABLE transactions(id TEXT PRIMARY KEY, assetId TEXT, amount REAL, balanceAfter REAL, note TEXT, createdAt INTEGER)');
        await db.execute('CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT)');
      },
      onUpgrade: (db, oldV, _) async {
        if (oldV < 2) await db.execute('CREATE TABLE IF NOT EXISTS settings(key TEXT PRIMARY KEY, value TEXT)');
      },
    );
  }

  static Future<List<Asset>> getAssets() async {
    final rows = await (await db).query('assets', orderBy: 'updatedAt DESC');
    return rows.map(Asset.fromMap).toList();
  }

  static Future<void> saveAsset(Asset a) async =>
      (await db).insert('assets', a.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  static Future<void> deleteAsset(String id) async {
    final d = await db;
    await d.delete('assets', where: 'id=?', whereArgs: [id]);
    await d.delete('transactions', where: 'assetId=?', whereArgs: [id]);
  }

  static Future<List<model.Transaction>> getTransactions(String assetId) async {
    final rows = await (await db).query(
      'transactions', where: 'assetId=?', whereArgs: [assetId], orderBy: 'createdAt DESC',
    );
    return rows.map(model.Transaction.fromMap).toList();
  }

  static Future<void> saveTransaction(model.Transaction t) async =>
      (await db).insert('transactions', t.toMap());

  static Future<String?> getSetting(String key) async {
    final rows = await (await db).query('settings', where: 'key=?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  static Future<void> setSetting(String key, String value) async =>
      (await db).insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);

  static Future<Map<String, dynamic>> exportAll() async {
    final d = await db;
    return {
      'assets': await d.query('assets'),
      'transactions': await d.query('transactions'),
      'exportedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Future<void> importAll(Map<String, dynamic> data) async {
    final d = await db;
    await d.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('assets');
      for (final row in (data['assets'] as List)) {
        await txn.insert('assets', Map<String, dynamic>.from(row));
      }
      for (final row in (data['transactions'] as List)) {
        await txn.insert('transactions', Map<String, dynamic>.from(row));
      }
    });
  }
}
