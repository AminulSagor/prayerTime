import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart'; // Import the path package
import '../models/user_response.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<void> initDatabase() async {
    // This method initializes the database
    _database = await _initDatabase();
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase(); // If the database isn't initialized yet, initialize it
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'prayer_reminder.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_responses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prayerName TEXT,
        response TEXT,
        timestamp TEXT
      )
    ''');
  }

  Future<void> insertUserResponse(UserResponse response) async {
    final db = await database;
    await db.insert(
      'user_responses',
      response.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<UserResponse>> getUserResponses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('user_responses');
    return List.generate(maps.length, (i) {
      return UserResponse.fromMap(maps[i]);
    });
  }
}
