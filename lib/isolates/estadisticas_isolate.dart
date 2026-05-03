import '../models/tarea_model.dart';

class EstadisticasTareas {
  final int total;
  final int completadas;
  final int pendientes;
  final int vencidas;
  final Map<String, int> porMateria;
  final Map<String, int> porTipo;
  final double porcentajeCompletado;

  EstadisticasTareas({
    required this.total,
    required this.completadas,
    required this.pendientes,
    required this.vencidas,
    required this.porMateria,
    required this.porTipo,
    required this.porcentajeCompletado,
  });
}

EstadisticasTareas calcularEstadisticas(List<Tarea> tareas) {
  final inicio = DateTime.now();
  print('[Isolate] Iniciado — ${tareas.length} tareas recibidas');

  final ahora       = DateTime.now();
  int completadas   = 0;
  int vencidas      = 0;
  final porMateria  = <String, int>{};
  final porTipo     = <String, int>{};

  for (final t in tareas) {
    if (t.completada) {
      completadas++;
    } else if (t.fechaEntrega.isBefore(ahora)) {
      vencidas++;
    }
    porMateria[t.materia] = (porMateria[t.materia] ?? 0) + 1;
    porTipo[t.tipo]       = (porTipo[t.tipo]       ?? 0) + 1;
  }

  final pct = tareas.isEmpty
      ? 0.0
      : (completadas / tareas.length * 100);

  final ms = DateTime.now().difference(inicio).inMilliseconds;
  print('[Isolate] Completado en $ms ms');

  return EstadisticasTareas(
    total:                 tareas.length,
    completadas:           completadas,
    pendientes:            tareas.length - completadas - vencidas,
    vencidas:              vencidas,
    porMateria:            porMateria,
    porTipo:               porTipo,
    porcentajeCompletado:  pct,
  );
}