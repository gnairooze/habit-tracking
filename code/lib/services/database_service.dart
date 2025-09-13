import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/habit.dart';
import '../models/alert.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'habit_tracking.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create habits table
    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        schedule_type TEXT NOT NULL,
        schedule_frequency INTEGER NOT NULL,
        schedule_times TEXT NOT NULL,
        schedule_days TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create alerts table
    await db.execute('''
      CREATE TABLE alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        habit_name TEXT NOT NULL,
        habit_description TEXT NOT NULL,
        scheduled_date_time INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'AlertStatus.pending',
        completed_at INTEGER,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_habits_name ON habits(name)');
    await db.execute('CREATE INDEX idx_alerts_habit_id ON alerts(habit_id)');
    await db.execute(
        'CREATE INDEX idx_alerts_scheduled_date ON alerts(scheduled_date_time)');
    await db.execute('CREATE INDEX idx_alerts_status ON alerts(status)');
  }

  // Habit CRUD operations
  Future<int> insertHabit(Habit habit) async {
    final db = await database;
    return await db.insert('habits', habit.toMap());
  }

  Future<List<Habit>> getHabits({String? searchQuery}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;

    if (searchQuery != null && searchQuery.isNotEmpty) {
      maps = await db.query(
        'habits',
        where: 'name LIKE ? OR description LIKE ?',
        whereArgs: ['%$searchQuery%', '%$searchQuery%'],
        orderBy: 'updated_at DESC',
      );
    } else {
      maps = await db.query('habits', orderBy: 'updated_at DESC');
    }

    return List.generate(maps.length, (i) => Habit.fromMap(maps[i]));
  }

  Future<Habit?> getHabit(int id) async {
    final db = await database;
    final maps = await db.query(
      'habits',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Habit.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateHabit(Habit habit) async {
    final db = await database;
    return await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<int> deleteHabit(int id) async {
    final db = await database;
    return await db.delete(
      'habits',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Alert CRUD operations
  Future<int> insertAlert(Alert alert) async {
    final db = await database;
    return await db.insert('alerts', alert.toMap());
  }

  Future<List<Alert>> getAlerts({
    String? searchQuery,
    DateTime? fromDate,
    DateTime? toDate,
    String? habitName,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    List<String> conditions = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      conditions.add('(habit_name LIKE ? OR habit_description LIKE ?)');
      whereArgs.addAll(['%$searchQuery%', '%$searchQuery%']);
    }

    if (fromDate != null) {
      conditions.add('scheduled_date_time >= ?');
      whereArgs.add(fromDate.millisecondsSinceEpoch);
    }

    if (toDate != null) {
      conditions.add('scheduled_date_time <= ?');
      whereArgs.add(toDate.millisecondsSinceEpoch);
    }

    if (habitName != null && habitName.isNotEmpty) {
      conditions.add('habit_name LIKE ?');
      whereArgs.add('%$habitName%');
    }

    if (conditions.isNotEmpty) {
      whereClause = conditions.join(' AND ');
    }

    final maps = await db.query(
      'alerts',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'scheduled_date_time DESC',
    );

    return List.generate(maps.length, (i) => Alert.fromMap(maps[i]));
  }

  Future<List<Alert>> getPendingAlerts() async {
    final db = await database;
    final maps = await db.query(
      'alerts',
      where: 'status = ? AND scheduled_date_time <= ?',
      whereArgs: ['AlertStatus.pending', DateTime.now().millisecondsSinceEpoch],
      orderBy: 'scheduled_date_time ASC',
    );

    return List.generate(maps.length, (i) => Alert.fromMap(maps[i]));
  }

  Future<Alert?> getAlert(int id) async {
    final db = await database;
    final maps = await db.query(
      'alerts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Alert.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateAlert(Alert alert) async {
    final db = await database;
    return await db.update(
      'alerts',
      alert.toMap(),
      where: 'id = ?',
      whereArgs: [alert.id],
    );
  }

  Future<int> deleteAlert(int id) async {
    final db = await database;
    return await db.delete(
      'alerts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAlertsForHabit(int habitId) async {
    final db = await database;
    return await db.delete(
      'alerts',
      where: 'habit_id = ?',
      whereArgs: [habitId],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
