import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:deneme/models/course.dart';
import 'package:deneme/models/week.dart';
import 'package:deneme/models/note.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Get a location using getDatabasesPath
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'notes.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE courses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        favorite_count INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE weeks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        week_number INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        content TEXT,
        is_favorite INTEGER DEFAULT 0,
        FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        week_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        page_number INTEGER NOT NULL,
        x_position REAL NOT NULL,
        y_position REAL NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (week_id) REFERENCES weeks (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE media_files (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        week_id INTEGER NOT NULL,
        file_name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_type TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (week_id) REFERENCES weeks (id) ON DELETE CASCADE
      )
    ''');

    print('Database tables created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Version 2'ye geçiş: weeks tablosuna content ve is_favorite kolonları ekle
      await db.execute('ALTER TABLE weeks ADD COLUMN content TEXT');
      await db.execute(
        'ALTER TABLE weeks ADD COLUMN is_favorite INTEGER DEFAULT 0',
      );
      print(
        'Database upgraded to version 2: Added content and is_favorite columns',
      );
    }
    if (oldVersion < 3) {
      // Version 3'e geçiş: media_files tablosunu ekle
      await db.execute('''
        CREATE TABLE media_files (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          week_id INTEGER NOT NULL,
          file_name TEXT NOT NULL,
          file_path TEXT NOT NULL,
          file_type TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (week_id) REFERENCES weeks (id) ON DELETE CASCADE
        )
      ''');
      print('Database upgraded to version 3: Added media_files table');
    }
  }
}
