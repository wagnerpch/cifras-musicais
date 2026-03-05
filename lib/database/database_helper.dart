import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/song.dart';

class DatabaseHelper {
  // Singleton
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  // Abertura do banco assíncrona
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'cifras_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Criação da tabela de músicas
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        content TEXT NOT NULL,
        key TEXT NOT NULL,
        bpm INTEGER NOT NULL
      )
    ''');
  }

  // Inserir uma música
  Future<int> insertSong(Song song) async {
    Database db = await instance.database;
    return await db.insert(
      'songs',
      song.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Atualizar uma música
  Future<int> updateSong(Song song) async {
    Database db = await instance.database;
    return await db.update(
      'songs',
      song.toMap(),
      where: 'id = ?',
      whereArgs: [song.id],
    );
  }

  // Deletar uma música
  Future<int> deleteSong(int id) async {
    Database db = await instance.database;
    return await db.delete(
      'songs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Listar todas as músicas
  Future<List<Song>> getSongs() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'songs',
      orderBy: 'title COLLATE NOCASE ASC',
    );

    return List.generate(maps.length, (i) {
      return Song.fromMap(maps[i]);
    });
  }

  // Buscar música por ID
  Future<Song?> getSongById(int id) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'songs',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Song.fromMap(maps.first);
    }
    return null;
  }
}
