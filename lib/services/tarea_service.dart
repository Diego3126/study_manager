import '../models/tarea_model.dart';
import 'firestore_service.dart';

class TareaService {
  final FirestoreService _fs = FirestoreService();

  Stream<List<Tarea>> getTareasStream() => _fs.getTareasStream();

  Future<List<Tarea>> getAll()          => _fs.getAll();
  Future<List<Tarea>> getHoy()          => _fs.getHoy();
  Future<Tarea>       getById(String id) => _fs.getById(id);
  Future<String>      crear(Tarea t)    => _fs.crear(t);
  Future<void>        editar(Tarea t)   => _fs.editar(t);
  Future<void>        eliminar(String id) => _fs.eliminar(id);

  Future<void> marcarCompletada(String id, bool completada) =>
      _fs.marcarCompletada(id, completada);

  Future<List<Tarea>> getPendientes() async {
    final todas = await _fs.getAll();
    return todas.where((t) => !t.completada).toList();
  }
}