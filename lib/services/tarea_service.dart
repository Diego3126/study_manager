import '../models/tarea_model.dart';
import 'database_service.dart';

class TareaService {
  final DatabaseService _db = DatabaseService();

  Future<List<Tarea>> getAll() async {
    final db   = await _db.database;
    final maps = await db.query(
      'tareas',
      orderBy: 'fechaEntrega ASC',
    );
    return maps.map((m) => Tarea.fromMap(m)).toList();
  }

  Future<List<Tarea>> getPendientes() async {
    final db   = await _db.database;
    final maps = await db.query(
      'tareas',
      where:   'completada = ?',
      whereArgs: [0],
      orderBy: 'fechaEntrega ASC',
    );
    return maps.map((m) => Tarea.fromMap(m)).toList();
  }

  Future<List<Tarea>> getHoy() async {
    final db    = await _db.database;
    final hoy   = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day).toIso8601String();
    final fin    = DateTime(hoy.year, hoy.month, hoy.day, 23, 59).toIso8601String();
    final maps  = await db.query(
      'tareas',
      where:     'fechaEntrega BETWEEN ? AND ?',
      whereArgs: [inicio, fin],
      orderBy:   'fechaEntrega ASC',
    );
    return maps.map((m) => Tarea.fromMap(m)).toList();
  }

  Future<Tarea> getById(int id) async {
    final db   = await _db.database;
    final maps = await db.query(
      'tareas',
      where:     'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) throw Exception('Tarea no encontrada');
    return Tarea.fromMap(maps.first);
  }

  Future<int> crear(Tarea tarea) async {
    final db = await _db.database;
    return await db.insert('tareas', tarea.toMap());
  }

  Future<void> editar(Tarea tarea) async {
    final db = await _db.database;
    await db.update(
      'tareas',
      tarea.toMap(),
      where:     'id = ?',
      whereArgs: [tarea.id],
    );
  }

  Future<void> marcarCompletada(int id, bool completada) async {
    final db = await _db.database;
    await db.update(
      'tareas',
      {'completada': completada ? 1 : 0},
      where:     'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> eliminar(int id) async {
    final db = await _db.database;
    await db.delete(
      'tareas',
      where:     'id = ?',
      whereArgs: [id],
    );
  }
}