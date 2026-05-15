import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import '../models/hike_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('trailmate.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const syncType = 'INTEGER DEFAULT 0'; 

    await db.execute('''
      CREATE TABLE hikes (
        id $idType, title $textType, distance $realType,
        elevation $realType, duration $textType, date $textType,
        firebase_id TEXT, is_synced $syncType
      )
    ''');

    await db.execute('''
      CREATE TABLE waypoints (
        id $idType, hike_id INTEGER, latitude $realType, longitude $realType, 
        name $textType, is_synced $syncType
      )
    ''');

    await db.execute('''
      CREATE TABLE albums (
        id $idType, hike_id INTEGER, image_path $textType,
        caption $textType, latitude $realType, longitude $realType, is_synced $syncType
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE hikes ADD COLUMN firebase_id TEXT;");
      await db.execute("ALTER TABLE hikes ADD COLUMN is_synced INTEGER DEFAULT 0;");
      await db.execute("ALTER TABLE waypoints ADD COLUMN is_synced INTEGER DEFAULT 0;");
      await db.execute("ALTER TABLE albums ADD COLUMN is_synced INTEGER DEFAULT 0;");
    }
  }

  Future<int> insertHike(HikeModel hike) async {
    final db = await instance.database;
    return await db.insert('hikes', hike.toMap());
  }

  Future<int> updateHike(HikeModel hike) async {
    final db = await instance.database;
    return await db.update('hikes', hike.toMap(), where: 'id = ?', whereArgs: [hike.id]);
  }

  Future<int> insertPhoto(Map<String, dynamic> photoData) async {
    final db = await instance.database;
    return await db.insert('albums', photoData);
  }

  Future<List<HikeModel>> getAllHikes() async {
    final db = await instance.database;
    final result = await db.query('hikes', orderBy: 'date DESC');
    return result.map((json) => HikeModel.fromMap(json)).toList();
  }

  Future<List<Map<String, dynamic>>> getAlbumsSummary() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT hikes.id as hike_id, hikes.title, MIN(albums.image_path) as cover_image, COUNT(albums.id) as photo_count
      FROM hikes
      LEFT JOIN albums ON hikes.id = albums.hike_id
      GROUP BY hikes.id
      ORDER BY hikes.date DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getPhotosForHike(int hikeId) async {
    final db = await instance.database;
    return await db.query('albums', where: 'hike_id = ?', whereArgs: [hikeId], orderBy: 'id DESC');
  }

  Future<void> deleteHike(int hikeId) async {
    final db = await instance.database;
    await db.delete('hikes', where: 'id = ?', whereArgs: [hikeId]);
    await db.delete('waypoints', where: 'hike_id = ?', whereArgs: [hikeId]);
    await db.delete('albums', where: 'hike_id = ?', whereArgs: [hikeId]);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedHikes() async {
    final db = await instance.database;
    return await db.query('hikes', where: 'is_synced = ?', whereArgs: [0]);
  }

  Future<void> markHikeSynced(int id, String firebaseId) async {
    final db = await instance.database;
    await db.update('hikes', {'is_synced': 1, 'firebase_id': firebaseId}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllData() async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, 'trailmate.db');
    await deleteDatabase(path);
    _database = null;
  }
}