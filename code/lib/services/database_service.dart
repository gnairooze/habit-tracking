import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/habit.dart';
import '../models/alert.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'habit_tracking.db';
  static const int _databaseVersion = 1;

  static const String _habitsTable = 'habits';
  static const String _alertsTable = 'alerts';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_habitsTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        schedule_type TEXT NOT NULL,
        occurrences_per_period INTEGER NOT NULL,
        selected_days TEXT,
        times TEXT NOT NULL,
        alert_enabled INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE $_alertsTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        habit_name TEXT NOT NULL,
        habit_description TEXT NOT NULL,
        scheduled_date_time INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        completed_date_time INTEGER,
        FOREIGN KEY (habit_id) REFERENCES $_habitsTable (id) ON DELETE CASCADE
      )
    ''');
  }

  // Habit CRUD operations
  static Future<int> insertHabit(Habit habit) async {
    final db = await database;
    return await db.insert(_habitsTable, habit.toMap());
  }

  static Future<List<Habit>> getHabits() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_habitsTable);
    return List.generate(maps.length, (i) => Habit.fromMap(maps[i]));
  }

  static Future<Habit?> getHabit(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _habitsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Habit.fromMap(maps.first);
    }
    return null;
  }

  static Future<List<Habit>> searchHabits(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _habitsTable,
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) => Habit.fromMap(maps[i]));
  }

  static Future<int> updateHabit(Habit habit) async {
    final db = await database;
    return await db.update(
      _habitsTable,
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  static Future<int> deleteHabit(int id) async {
    final db = await database;
    // Delete associated alerts first
    await db.delete(_alertsTable, where: 'habit_id = ?', whereArgs: [id]);
    return await db.delete(_habitsTable, where: 'id = ?', whereArgs: [id]);
  }

  // Alert CRUD operations
  static Future<int> insertAlert(Alert alert) async {
    final db = await database;
    return await db.insert(_alertsTable, alert.toMap());
  }

  static Future<List<Alert>> getAlerts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _alertsTable,
      orderBy: 'scheduled_date_time ASC',
    );
    return List.generate(maps.length, (i) => Alert.fromMap(maps[i]));
  }

  static Future<List<Alert>> getPendingAlerts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _alertsTable,
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'scheduled_date_time ASC',
    );
    return List.generate(maps.length, (i) => Alert.fromMap(maps[i]));
  }

  static Future<List<Alert>> searchAlerts({
    DateTime? fromDate,
    DateTime? toDate,
    String? habitName,
    String? habitDescription,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (fromDate != null) {
      whereClause += 'scheduled_date_time >= ?';
      whereArgs.add(fromDate.millisecondsSinceEpoch);
    }

    if (toDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'scheduled_date_time <= ?';
      whereArgs.add(toDate.millisecondsSinceEpoch);
    }

    if (habitName != null && habitName.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'habit_name LIKE ?';
      whereArgs.add('%$habitName%');
    }

    if (habitDescription != null && habitDescription.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'habit_description LIKE ?';
      whereArgs.add('%$habitDescription%');
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _alertsTable,
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'scheduled_date_time DESC',
    );

    return List.generate(maps.length, (i) => Alert.fromMap(maps[i]));
  }

  static Future<int> updateAlert(Alert alert) async {
    final db = await database;
    return await db.update(
      _alertsTable,
      alert.toMap(),
      where: 'id = ?',
      whereArgs: [alert.id],
    );
  }

  static Future<int> deleteAlert(int id) async {
    final db = await database;
    return await db.delete(_alertsTable, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> close() async {
    final db = await database;
    db.close();
  }
}
