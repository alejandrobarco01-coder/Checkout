import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../core/constants.dart';

/// Singleton que gestiona la conexión SQLite.
/// Patrón Singleton para evitar múltiples instancias de la base de datos.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
    );
  }

  /// Crea las tablas al iniciar la BD por primera vez.
  Future<void> _onCreate(Database db, int version) async {
    // Tabla de checklists
    await db.execute('''
      CREATE TABLE ${AppConstants.tableChecklists} (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre         TEXT    NOT NULL,
        tipo_salida    TEXT    NOT NULL,
        fecha_creacion TEXT    NOT NULL
      )
    ''');

    // Tabla de ítems con FK al checklist
    await db.execute('''
      CREATE TABLE ${AppConstants.tableItems} (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        checklist_id  INTEGER NOT NULL,
        nombre        TEXT    NOT NULL,
        completado    INTEGER NOT NULL DEFAULT 0,
        peso_kg       REAL    NOT NULL DEFAULT 0.0,
        FOREIGN KEY (checklist_id)
          REFERENCES ${AppConstants.tableChecklists}(id)
      )
    ''');
  }

  // ──────────────────────────────────────────────
  // Helpers CRUD genéricos
  // ──────────────────────────────────────────────

  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await database;
    return db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return db.query(table);
  }

  Future<List<Map<String, dynamic>>> queryWhere(
    String table,
    String where,
    List<dynamic> args,
  ) async {
    final db = await database;
    return db.query(table, where: where, whereArgs: args);
  }

  Future<int> update(
    String table,
    Map<String, dynamic> row,
    String where,
    List<dynamic> args,
  ) async {
    final db = await database;
    return db.update(table, row, where: where, whereArgs: args);
  }

  Future<int> deleteWhere(
    String table,
    String where,
    List<dynamic> args,
  ) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: args);
  }
}
