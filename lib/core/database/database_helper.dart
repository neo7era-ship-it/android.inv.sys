import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, AppConstants.dbName);
    return await openDatabase(path, version: AppConstants.dbVersion, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.medicalItemsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        itemName TEXT NOT NULL,
        category TEXT,
        createdAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('CREATE INDEX idx_items_name ON ${AppConstants.medicalItemsTable}(itemName)');
    await db.execute('CREATE INDEX idx_items_cat ON ${AppConstants.medicalItemsTable}(category)');

    await db.execute('''
      CREATE TABLE ${AppConstants.requestsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        date TEXT NOT NULL,
        department TEXT,
        requester TEXT,
        signature TEXT,
        status TEXT NOT NULL DEFAULT 'draft',
        createdAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.requestItemsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        requestId INTEGER NOT NULL,
        itemId INTEGER,
        itemName TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        orderIndex INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (requestId) REFERENCES ${AppConstants.requestsTable}(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_ri_req ON ${AppConstants.requestItemsTable}(requestId)');
  }

  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}
