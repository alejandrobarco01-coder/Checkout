import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../core/constants.dart';

/// Singleton que gestiona la conexión SQLite (móvil) o SharedPreferences (web).
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
      onUpgrade: _onUpgrade,
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
    await _createLegacyTables(db);
    await _createScheduledTripsTable(db);
  }

  Future<void> _createNewTables(Database db) async {
    await _createLegacyTables(db);
    await _createScheduledTripsTable(db);
  }

  Future<void> _createScheduledTripsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableTrips} (
        id                    TEXT PRIMARY KEY,
        name                  TEXT NOT NULL,
        destination_name      TEXT NOT NULL DEFAULT '',
        destination_place_id  TEXT,
        departure_date        TEXT NOT NULL,
        return_date           TEXT,
        type                  TEXT NOT NULL,
        status                TEXT NOT NULL DEFAULT 'upcoming',
        checklist_id          INTEGER,
        user_id               TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_trips_departure_date
      ON ${AppConstants.tableTrips}(departure_date)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createLegacyTables(db);
    }
    if (oldVersion < 3) {
      try {
        await db.execute(
          'ALTER TABLE ${AppConstants.tableTrips} RENAME TO ${AppConstants.tableCompletedTrips}',
        );
      } catch (_) {
        // Tabla ya migrada o instalación parcial.
      }
      await _createScheduledTripsTable(db);
    }
  }

  Future<void> _createLegacyTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableCompletedTrips} (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre            TEXT    NOT NULL,
        tipo_salida       TEXT    NOT NULL,
        destino           TEXT    NOT NULL DEFAULT '',
        fecha_salida      TEXT    NOT NULL,
        porcentaje        REAL    NOT NULL DEFAULT 0.0,
        peso_total_kg     REAL    NOT NULL DEFAULT 0.0,
        lat               REAL,
        lng               REAL
      )
    ''');

    // Ítems olvidados (ranking)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableForgottenItems} (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre       TEXT    NOT NULL,
        tipo_salida  TEXT    NOT NULL,
        veces        INTEGER NOT NULL DEFAULT 1,
        ultima_fecha TEXT    NOT NULL
      )
    ''');

    // Eventos del calendario personal
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableCalendarEvents} (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo      TEXT    NOT NULL,
        descripcion TEXT,
        tipo        TEXT    NOT NULL DEFAULT 'otro',
        fecha       TEXT    NOT NULL,
        hora        TEXT,
        destino     TEXT,
        lat         REAL,
        lng         REAL,
        color       INTEGER
      )
    ''');
  }

  // ──────────────────────────────────────────────
  // Web storage simulation
  // ──────────────────────────────────────────────
  List<Map<String, dynamic>>? _webChecklists;
  List<Map<String, dynamic>>? _webItems;
  List<Map<String, dynamic>>? _webTrips;
  List<Map<String, dynamic>>? _webCompletedTrips;
  List<Map<String, dynamic>>? _webForgottenItems;
  List<Map<String, dynamic>>? _webCalendarEvents;
  int _webChecklistIdCounter = 1;
  int _webItemIdCounter = 1;
  int _webTripIdCounter = 1;
  int _webForgottenIdCounter = 1;
  int _webEventIdCounter = 1;

  List<Map<String, dynamic>>? _webTableFor(String table) {
    switch (table) {
      case _ when table == AppConstants.tableChecklists:
        return _webChecklists;
      case _ when table == AppConstants.tableItems:
        return _webItems;
      case _ when table == AppConstants.tableTrips:
        return _webTrips;
      case _ when table == AppConstants.tableCompletedTrips:
        return _webCompletedTrips;
      case _ when table == AppConstants.tableForgottenItems:
        return _webForgottenItems;
      case _ when table == AppConstants.tableCalendarEvents:
        return _webCalendarEvents;
      default:
        return null;
    }
  }

  int _nextWebId(String table) {
    switch (table) {
      case _ when table == AppConstants.tableChecklists:
        return _webChecklistIdCounter++;
      case _ when table == AppConstants.tableItems:
        return _webItemIdCounter++;
      case _ when table == AppConstants.tableTrips:
        return _webTripIdCounter++;
      case _ when table == AppConstants.tableCompletedTrips:
        return _webTripIdCounter++;
      case _ when table == AppConstants.tableForgottenItems:
        return _webForgottenIdCounter++;
      case _ when table == AppConstants.tableCalendarEvents:
        return _webEventIdCounter++;
      default:
        return 0;
    }
  }

  void _syncWebIdCounter(String table, List<Map<String, dynamic>> rows) {
    int Function() getter;
    void Function(int) setter;
    switch (table) {
      case _ when table == AppConstants.tableChecklists:
        getter = () => _webChecklistIdCounter;
        setter = (v) => _webChecklistIdCounter = v;
        break;
      case _ when table == AppConstants.tableItems:
        getter = () => _webItemIdCounter;
        setter = (v) => _webItemIdCounter = v;
        break;
      case _ when table == AppConstants.tableTrips:
        getter = () => _webTripIdCounter;
        setter = (v) => _webTripIdCounter = v;
        break;
      case _ when table == AppConstants.tableCompletedTrips:
        getter = () => _webTripIdCounter;
        setter = (v) => _webTripIdCounter = v;
        break;
      case _ when table == AppConstants.tableForgottenItems:
        getter = () => _webForgottenIdCounter;
        setter = (v) => _webForgottenIdCounter = v;
        break;
      case _ when table == AppConstants.tableCalendarEvents:
        getter = () => _webEventIdCounter;
        setter = (v) => _webEventIdCounter = v;
        break;
      default:
        return;
    }
    var counter = getter();
    for (final row in rows) {
      final id = row['id'] as int? ?? 0;
      if (id >= counter) counter = id + 1;
    }
    setter(counter);
  }

  Future<List<Map<String, dynamic>>> _loadWebTable(
    SharedPreferences prefs,
    String prefKey,
    String table,
  ) async {
    final stored = prefs.getString(prefKey);
    if (stored != null) {
      try {
        final decoded = jsonDecode(stored) as List;
        final rows = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        _syncWebIdCounter(table, rows);
        return rows;
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  Future<void> _initWebDatabase() async {
    if (_webChecklists != null) return;

    final prefs = await SharedPreferences.getInstance();
    _webChecklists =
        await _loadWebTable(prefs, 'web_db_checklists', AppConstants.tableChecklists);
    _webItems =
        await _loadWebTable(prefs, 'web_db_items', AppConstants.tableItems);
    _webTrips =
        await _loadWebTable(prefs, 'web_db_scheduled_trips', AppConstants.tableTrips);
    _webCompletedTrips = await _loadWebTable(
        prefs, 'web_db_completed_trips', AppConstants.tableCompletedTrips);
    // Migrar datos legados si existían en web_db_trips
    final legacyTrips = prefs.getString('web_db_trips');
    if (legacyTrips != null && (_webCompletedTrips?.isEmpty ?? true)) {
      try {
        final decoded = jsonDecode(legacyTrips) as List;
        _webCompletedTrips = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        await prefs.setString(
          'web_db_completed_trips',
          jsonEncode(_webCompletedTrips),
        );
      } catch (_) {}
    }
    _webForgottenItems = await _loadWebTable(
        prefs, 'web_db_forgotten', AppConstants.tableForgottenItems);
    _webCalendarEvents = await _loadWebTable(
        prefs, 'web_db_events', AppConstants.tableCalendarEvents);
  }

  Future<void> _saveWebDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    if (_webChecklists != null) {
      await prefs.setString('web_db_checklists', jsonEncode(_webChecklists));
    }
    if (_webItems != null) {
      await prefs.setString('web_db_items', jsonEncode(_webItems));
    }
    if (_webTrips != null) {
      await prefs.setString('web_db_scheduled_trips', jsonEncode(_webTrips));
    }
    if (_webCompletedTrips != null) {
      await prefs.setString(
          'web_db_completed_trips', jsonEncode(_webCompletedTrips));
    }
    if (_webForgottenItems != null) {
      await prefs.setString('web_db_forgotten', jsonEncode(_webForgottenItems));
    }
    if (_webCalendarEvents != null) {
      await prefs.setString('web_db_events', jsonEncode(_webCalendarEvents));
    }
  }

  bool _webRowMatches(String where, List<dynamic> args, Map<String, dynamic> row) {
    final cleanedWhere = where.replaceAll(' ', '');
    if (cleanedWhere == 'id=?') {
      final rowId = row['id'];
      final arg = args[0];
      return rowId == arg || rowId.toString() == arg.toString();
    }
    if (cleanedWhere == 'checklist_id=?') {
      return row['checklist_id'] == args[0];
    }
    return true;
  }

  // ──────────────────────────────────────────────
  // Helpers CRUD genéricos
  // ──────────────────────────────────────────────

  Future<int> insert(String table, Map<String, dynamic> row) async {
    if (kIsWeb) {
      await _initWebDatabase();
      final target = _webTableFor(table);
      if (target == null) return 0;
      final mutableRow = Map<String, dynamic>.from(row);
      if (table == AppConstants.tableTrips && mutableRow['id'] is String) {
        target.add(mutableRow);
        await _saveWebDatabase();
        return mutableRow['id'].hashCode;
      }
      final insertedId = _nextWebId(table);
      mutableRow['id'] = insertedId;
      target.add(mutableRow);
      await _saveWebDatabase();
      return insertedId;
    }

    final db = await database;
    return db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    if (kIsWeb) {
      await _initWebDatabase();
      final target = _webTableFor(table);
      return target != null
          ? List<Map<String, dynamic>>.from(target)
          : [];
    }

    final db = await database;
    return db.query(table);
  }

  Future<List<Map<String, dynamic>>> queryWhere(
    String table,
    String where,
    List<dynamic> args,
  ) async {
    if (kIsWeb) {
      await _initWebDatabase();
      final all = _webTableFor(table) ?? [];
      return all
          .where((row) => _webRowMatches(where, args, row))
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }

    final db = await database;
    return db.query(table, where: where, whereArgs: args);
  }

  Future<int> update(
    String table,
    Map<String, dynamic> row,
    String where,
    List<dynamic> args,
  ) async {
    if (kIsWeb) {
      await _initWebDatabase();
      final all = _webTableFor(table);
      if (all == null) return 0;
      var count = 0;
      for (var i = 0; i < all.length; i++) {
        if (_webRowMatches(where, args, all[i])) {
          all[i] = {...all[i], ...row};
          count++;
        }
      }
      if (count > 0) await _saveWebDatabase();
      return count;
    }

    final db = await database;
    return db.update(table, row, where: where, whereArgs: args);
  }

  Future<int> deleteWhere(
    String table,
    String where,
    List<dynamic> args,
  ) async {
    if (kIsWeb) {
      await _initWebDatabase();
      final all = _webTableFor(table);
      if (all == null) return 0;
      final initialLength = all.length;
      all.removeWhere((row) => _webRowMatches(where, args, row));
      final deletedCount = initialLength - all.length;
      if (deletedCount > 0) await _saveWebDatabase();
      return deletedCount;
    }

    final db = await database;
    return db.delete(table, where: where, whereArgs: args);
  }
}
