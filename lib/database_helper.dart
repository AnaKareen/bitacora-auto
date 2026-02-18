import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bitacora.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {

    // Tabla gasolina
    await db.execute('''
    CREATE TABLE gasolina (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      fecha TEXT,
      kilometraje REAL,
      litros REAL,
      precio_litro REAL,
      total REAL
    )
    ''');

    // Tabla servicios
    await db.execute('''
    CREATE TABLE servicios (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tipo TEXT,
      fecha TEXT,
      kilometraje REAL,
      costo REAL,
      lugar TEXT,
      notas TEXT
    )
    ''');

    // Tabla seguro
    await db.execute('''
    CREATE TABLE seguro (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      aseguradora TEXT,
      poliza TEXT,
      telefono TEXT,
      inicio TEXT,
      fin TEXT,
      notas TEXT
    )
    ''');
  }

  /// Actualizar registro de gasolina
  Future<int> actualizarGasolina(int id, {
    required String fecha,
    required double kilometraje,
    required double litros,
    required double preciolitro,
    required double total,
  }) async {
    final db = await database;
    return await db.update(
      'gasolina',
      {
        'fecha': fecha,
        'kilometraje': kilometraje,
        'litros': litros,
        'precio_litro': preciolitro,
        'total': total,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Insertar servicio
  Future<int> insertarServicio({
    required String tipo,
    required String fecha,
    required double kilometraje,
    required double costo,
    required String lugar,
    required String notas,
  }) async {
    final db = await database;
    return await db.insert('servicios', {
      'tipo': tipo,
      'fecha': fecha,
      'kilometraje': kilometraje,
      'costo': costo,
      'lugar': lugar,
      'notas': notas,
    });
  }

  /// Obtener todos los servicios
  Future<List<Map<String, dynamic>>> obtenerServicios() async {
    final db = await database;
    return await db.query('servicios', orderBy: 'id DESC');
  }

  /// Actualizar servicio
  Future<int> actualizarServicio(int id, {
    required String tipo,
    required String fecha,
    required double kilometraje,
    required double costo,
    required String lugar,
    required String notas,
  }) async {
    final db = await database;
    return await db.update(
      'servicios',
      {
        'tipo': tipo,
        'fecha': fecha,
        'kilometraje': kilometraje,
        'costo': costo,
        'lugar': lugar,
        'notas': notas,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Eliminar servicio
  Future<int> eliminarServicio(int id) async {
    final db = await database;
    return await db.delete(
      'servicios',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Insertar seguro
  Future<int> insertarSeguro({
    required String aseguradora,
    required String poliza,
    required String telefono,
    required String inicio,
    required String fin,
    required String notas,
  }) async {
    final db = await database;
    return await db.insert('seguro', {
      'aseguradora': aseguradora,
      'poliza': poliza,
      'telefono': telefono,
      'inicio': inicio,
      'fin': fin,
      'notas': notas,
    });
  }

  /// Obtener seguro (solo uno)
  Future<Map<String, dynamic>?> obtenerSeguro() async {
    final db = await database;
    final result = await db.query('seguro', limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  /// Actualizar seguro
  Future<int> actualizarSeguro(int id, {
    required String aseguradora,
    required String poliza,
    required String telefono,
    required String inicio,
    required String fin,
    required String notas,
  }) async {
    final db = await database;
    return await db.update(
      'seguro',
      {
        'aseguradora': aseguradora,
        'poliza': poliza,
        'telefono': telefono,
        'inicio': inicio,
        'fin': fin,
        'notas': notas,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Eliminar seguro
  Future<int> eliminarSeguro(int id) async {
    final db = await database;
    return await db.delete(
      'seguro',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
