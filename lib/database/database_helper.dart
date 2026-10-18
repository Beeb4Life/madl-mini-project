import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/pet.dart';
import '../models/care_task.dart';
import '../models/health_entry.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('petsync.db');
    return _database!;
  }

  static bool _ffiInitialized = false;

  Future<Database> _initDB(String filePath) async {
    // Cross-platform desktop initialization for Linux / macOS / Windows
    if ((Platform.isLinux || Platform.isWindows || Platform.isMacOS) && !_ffiInitialized) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _ffiInitialized = true;
    }

    final dbPath = await _getDatabaseDirectory();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onConfigure: _onConfigure,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<String> _getDatabaseDirectory() async {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      final dir = await getApplicationSupportDirectory();
      final dbDir = Directory(p.join(dir.path, 'databases'));
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
      }
      return dbDir.path;
    }
    return await getDatabasesPath();
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        species TEXT NOT NULL,
        breed TEXT,
        date_of_birth TEXT,
        weight REAL,
        notes TEXT,
        image_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE care_tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        scheduled_time TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        task_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (pet_id) REFERENCES pets (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE health_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER NOT NULL,
        entry_type TEXT NOT NULL,
        entry_date TEXT NOT NULL,
        title TEXT NOT NULL,
        notes TEXT,
        weight_value REAL,
        veterinarian TEXT,
        image_path TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (pet_id) REFERENCES pets (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE pets ADD COLUMN image_path TEXT;');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE health_entries ADD COLUMN image_path TEXT;');
      } catch (_) {}
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS app_settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      } catch (_) {}
    }
  }

  // ==========================================
  // SETTINGS
  // ==========================================

  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final results = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return results.first['value'] as String?;
    }
    return null;
  }

  // ==========================================
  // PETS CRUD
  // ==========================================

  Future<int> insertPet(Pet pet) async {
    final db = await database;
    return await db.insert('pets', pet.toMap());
  }

  Future<int> updatePet(Pet pet) async {
    final db = await database;
    return await db.update(
      'pets',
      pet.toMap(),
      where: 'id = ?',
      whereArgs: [pet.id],
    );
  }

  Future<int> deletePet(int petId) async {
    final db = await database;
    return await db.transaction((txn) async {
      await txn.delete('care_tasks', where: 'pet_id = ?', whereArgs: [petId]);
      await txn.delete('health_entries', where: 'pet_id = ?', whereArgs: [petId]);
      return await txn.delete('pets', where: 'id = ?', whereArgs: [petId]);
    });
  }

  Future<List<Pet>> getAllPets() async {
    final db = await database;
    final result = await db.query('pets', orderBy: 'name ASC');
    return result.map((map) => Pet.fromMap(map)).toList();
  }

  Future<Pet?> getPetById(int id) async {
    final db = await database;
    final maps = await db.query(
      'pets',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Pet.fromMap(maps.first);
    }
    return null;
  }

  Future<int> getPetCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM pets'),
    );
    return count ?? 0;
  }

  // ==========================================
  // CARE TASKS CRUD
  // ==========================================

  Future<int> insertCareTask(CareTask task) async {
    final db = await database;
    return await db.insert('care_tasks', task.toMap());
  }

  Future<int> updateCareTask(CareTask task) async {
    final db = await database;
    return await db.update(
      'care_tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> toggleCareTask(int id, bool isCompleted) async {
    final db = await database;
    return await db.update(
      'care_tasks',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCareTask(int id) async {
    final db = await database;
    return await db.delete('care_tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<CareTask>> getTasksForDate(String date, {int? petId}) async {
    final db = await database;
    String sql = '''
      SELECT ct.*, p.name AS pet_name, p.species AS pet_species
      FROM care_tasks ct
      JOIN pets p ON ct.pet_id = p.id
      WHERE ct.task_date = ?
    ''';
    List<dynamic> args = [date];

    if (petId != null) {
      sql += ' AND ct.pet_id = ?';
      args.add(petId);
    }

    sql += ' ORDER BY ct.is_completed ASC, ct.scheduled_time ASC, ct.id DESC';
    final result = await db.rawQuery(sql, args);
    return result.map((map) => CareTask.fromMap(map)).toList();
  }

  Future<List<CareTask>> getAllTasks({int? petId}) async {
    final db = await database;
    String sql = '''
      SELECT ct.*, p.name AS pet_name, p.species AS pet_species
      FROM care_tasks ct
      JOIN pets p ON ct.pet_id = p.id
    ''';
    List<dynamic> args = [];

    if (petId != null) {
      sql += ' WHERE ct.pet_id = ?';
      args.add(petId);
    }

    sql += ' ORDER BY ct.task_date DESC, ct.is_completed ASC, ct.scheduled_time ASC';
    final result = await db.rawQuery(sql, args);
    return result.map((map) => CareTask.fromMap(map)).toList();
  }

  Future<List<CareTask>> getTasksForPet(int petId) async {
    return getAllTasks(petId: petId);
  }

  Future<Map<String, int>> getTodayTaskStats() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as total FROM care_tasks WHERE task_date = ?',
      [today],
    );
    final completedResult = await db.rawQuery(
      'SELECT COUNT(*) as completed FROM care_tasks WHERE task_date = ? AND is_completed = 1',
      [today],
    );

    final total = Sqflite.firstIntValue(totalResult) ?? 0;
    final completed = Sqflite.firstIntValue(completedResult) ?? 0;
    final pending = total - completed;

    return {
      'total': total,
      'completed': completed,
      'pending': pending,
    };
  }

  // ==========================================
  // HEALTH JOURNAL CRUD
  // ==========================================

  Future<int> insertHealthEntry(HealthEntry entry) async {
    final db = await database;
    return await db.transaction((txn) async {
      final id = await txn.insert('health_entries', entry.toMap());
      if (entry.entryType == 'weight' && entry.weightValue != null) {
        await txn.update(
          'pets',
          {'weight': entry.weightValue},
          where: 'id = ?',
          whereArgs: [entry.petId],
        );
      }
      return id;
    });
  }

  Future<int> updateHealthEntry(HealthEntry entry) async {
    final db = await database;
    return await db.update(
      'health_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteHealthEntry(int id) async {
    final db = await database;
    return await db.delete('health_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<HealthEntry>> getAllHealthEntries({int? petId}) async {
    final db = await database;
    String sql = '''
      SELECT he.*, p.name AS pet_name, p.species AS pet_species
      FROM health_entries he
      JOIN pets p ON he.pet_id = p.id
    ''';
    List<dynamic> args = [];

    if (petId != null) {
      sql += ' WHERE he.pet_id = ?';
      args.add(petId);
    }

    sql += ' ORDER BY he.entry_date DESC, he.id DESC';
    final result = await db.rawQuery(sql, args);
    return result.map((map) => HealthEntry.fromMap(map)).toList();
  }

  Future<List<HealthEntry>> getHealthEntriesForPet(int petId) async {
    return getAllHealthEntries(petId: petId);
  }

  Future<int> getHealthEntryCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM health_entries'),
    );
    return count ?? 0;
  }

  // Demo Data Seeding with Avatar styling
  Future<void> seedDemoData() async {
    final count = await getPetCount();
    if (count > 0) return;

    final today = DateTime.now().toIso8601String().substring(0, 10);

    final pet1Id = await insertPet(
      Pet(
        name: 'Luna',
        species: 'Dog',
        breed: 'Border Collie',
        dateOfBirth: '2023-04-12',
        weight: 18.5,
        imagePath: 'avatar:dog',
        notes: 'High energy, loves agility training, allergic to chicken.',
      ),
    );

    final pet2Id = await insertPet(
      Pet(
        name: 'Mochi',
        species: 'Cat',
        breed: 'Scottish Fold',
        dateOfBirth: '2024-01-20',
        weight: 4.2,
        imagePath: 'avatar:cat',
        notes: 'Indoor only. Very calm, prefers salmon kibbles.',
      ),
    );

    // Seed tasks for today
    await insertCareTask(
      CareTask(
        petId: pet1Id,
        title: 'Morning Park Walk & Frisbee',
        category: 'walking',
        scheduledTime: '07:30',
        isCompleted: true,
        taskDate: today,
        notes: 'Completed 3km trail walk.',
      ),
    );

    await insertCareTask(
      CareTask(
        petId: pet1Id,
        title: 'Evening Salmon Meal + Glucosamine',
        category: 'feeding',
        scheduledTime: '18:30',
        isCompleted: false,
        taskDate: today,
      ),
    );

    await insertCareTask(
      CareTask(
        petId: pet2Id,
        title: 'Brush coat & clean water fountain',
        category: 'grooming',
        scheduledTime: '15:00',
        isCompleted: false,
        taskDate: today,
      ),
    );

    // Seed health entries
    await insertHealthEntry(
      HealthEntry(
        petId: pet1Id,
        entryType: 'vaccination',
        entryDate: today,
        title: 'Annual Rabies & DHPP Booster',
        veterinarian: 'Dr. Sarah Vance (Metro Pet Clinic)',
        notes: 'Mild fatigue post-vaccine, normal appetite. Next due in 12 months.',
      ),
    );

    await insertHealthEntry(
      HealthEntry(
        petId: pet2Id,
        entryType: 'weight',
        entryDate: today,
        title: 'Monthly Weight Check',
        weightValue: 4.2,
        notes: 'Stable healthy weight. Maintained active play.',
      ),
    );
  }
}
