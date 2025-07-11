import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'lab04_app.db';
  static const int _version = 1;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT,
        content TEXT,
        published INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  }

  // User CRUD operations

  // TODO: Implement createUser method
   static Future<User> createUser(CreateUserRequest request) async {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      final id = await db.insert('users', {
        'name': request.name,
        'email': request.email,
        'created_at': now,
        'updated_at': now,
      });

      return User(
        id: id,
        name: request.name,
        email: request.email,
        createdAt: DateTime.parse(now),
        updatedAt: DateTime.parse(now),
      );
    }

  // TODO: Implement getUser method
  static Future<User?> getUser(int id) async {
      final db = await database;
      final results = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (results.isEmpty) return null;

      return User.fromMap(results.first);
    }

  // TODO: Implement getAllUsers method
  static Future<List<User>> getAllUsers() async {
      final db = await database;
      final results = await db.query(
        'users',
        orderBy: 'created_at ASC',
      );

      return results.map((map) => User.fromMap(map)).toList();
    }

  // TODO: Implement updateUser method
  static Future<User> updateUser(int id, Map<String, dynamic> updates) async {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      updates['updated_at'] = now;

      await db.update(
        'users',
        updates,
        where: 'id = ?',
        whereArgs: [id],
      );

      final result = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );

      return User.fromMap(result.first);
    }

  // TODO: Implement deleteUser method
  static Future<void> deleteUser(int id) async {
      final db = await database;
      await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );
    }

  // TODO: Implement getUserCount method
  static Future<int> getUserCount() async {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
      return Sqflite.firstIntValue(result) ?? 0;
    }

  // TODO: Implement searchUsers method
  static Future<List<User>> searchUsers(String query) async {
      final db = await database;
      final results = await db.query(
        'users',
        where: 'name LIKE ? OR email LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
      );

      return results.map((map) => User.fromMap(map)).toList();
    }

  // Database utility methods

  // TODO: Implement closeDatabase method
  static Future<void> closeDatabase() async {
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
    }

  // TODO: Implement clearAllData method
  static Future<void> clearAllData() async {
      final db = await database;
      await db.delete('posts');
      await db.delete('users');
    }

  // TODO: Implement getDatabasePath method
  static Future<String> getDatabasePath() async {
      final dbPath = await getDatabasesPath();
      return join(dbPath, _dbName);
    }
}
