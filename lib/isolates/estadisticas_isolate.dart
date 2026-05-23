import '../models/tarea_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EstadisticasTareas {
  final int total;
  final int completadas;
  final int pendientes;
  final int vencidas;
  final Map<String, int> porMateria;
  final Map<String, int> porTipo;
  final Map<String, int> porPrioridad;
  final double porcentajeCompletado;
  final Map<String, int> completadasPorDia;
  final String materiaMasCargada;
  final int rachaDias;

  // ── Enfoque ──────────────────────────────────────────────────────────────
  final int pomodorosCompletados;      // sesiones tipo 'Enfoque'
  final int descansosCortos;
  final int descansosLargos;
  final double productividadPromedio;  // promedio del campo 'productividad'
  final int tareasFinalizadasEnfoque;  // suma del campo 'finalizadas'
  final Map<String, int> pomodorosPorDia; // últimos 7 días

  EstadisticasTareas({
    required this.total,
    required this.completadas,
    required this.pendientes,
    required this.vencidas,
    required this.porMateria,
    required this.porTipo,
    required this.porPrioridad,
    required this.porcentajeCompletado,
    required this.completadasPorDia,
    required this.materiaMasCargada,
    required this.rachaDias,
    required this.pomodorosCompletados,
    required this.descansosCortos,
    required this.descansosLargos,
    required this.productividadPromedio,
    required this.tareasFinalizadasEnfoque,
    required this.pomodorosPorDia,
  });
}

// calcularEstadisticas sigue siendo el punto de entrada del isolate
// pero los datos de Firestore los traemos por separado antes de llamarlo
EstadisticasTareas calcularEstadisticas(List<dynamic> args) {
  final tareas = args[0] as List<Tarea>;
  final sesiones = args[1] as List<Map<String, dynamic>>;

  final inicio = DateTime.now();
  print('[Isolate] Iniciado — ${tareas.length} tareas, ${sesiones.length} sesiones');

  final ahora = DateTime.now();
  int completadas = 0;
  int vencidas = 0;
  final porMateria   = <String, int>{};
  final porTipo      = <String, int>{};
  final porPrioridad = <String, int>{};

  // Últimos 7 días inicializados en 0
  final completadasPorDia = <String, int>{};
  final pomodorosPorDia   = <String, int>{};
  for (int i = 6; i >= 0; i--) {
    final dia = ahora.subtract(Duration(days: i));
    final key = '${dia.day}/${dia.month}';
    completadasPorDia[key] = 0;
    pomodorosPorDia[key]   = 0;
  }

  final diasConCompletada = <String>{};

  for (final t in tareas) {
    if (t.completada) {
      completadas++;
      final diaT   = DateTime(t.creadaEn.year, t.creadaEn.month, t.creadaEn.day);
      final diaHoy = DateTime(ahora.year, ahora.month, ahora.day);
      final diff   = diaHoy.difference(diaT).inDays;
      if (diff >= 0 && diff < 7) {
        final key = '${t.creadaEn.day}/${t.creadaEn.month}';
        completadasPorDia[key] = (completadasPorDia[key] ?? 0) + 1;
        diasConCompletada.add(key);
      }
    } else if (t.fechaHoraEntrega.isBefore(ahora)) {
      vencidas++;
    }
    porMateria[t.materia]     = (porMateria[t.materia]     ?? 0) + 1;
    porTipo[t.tipo]           = (porTipo[t.tipo]           ?? 0) + 1;
    porPrioridad[t.prioridad] = (porPrioridad[t.prioridad] ?? 0) + 1;
  }

  // Materia con más tareas
  String materiaMasCargada = '';
  if (porMateria.isNotEmpty) {
    materiaMasCargada = porMateria.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  // Racha
  int rachaDias = 0;
  for (int i = 0; i < 7; i++) {
    final dia = ahora.subtract(Duration(days: i));
    final key = '${dia.day}/${dia.month}';
    if (diasConCompletada.contains(key)) rachaDias++;
    else break;
  }

  // ── Procesar sesiones de enfoque ────────────────────────────────────────
  int pomodorosCompletados   = 0;
  int descansosCortos        = 0;
  int descansosLargos        = 0;
  int tareasFinalizadas      = 0;
  double sumProductividad    = 0;
  int countProductividad     = 0;

  for (final s in sesiones) {
    final tipo      = s['tipo'] as String? ?? '';
    final fechaStr  = s['fecha'] as String? ?? '';
    final finalizadas   = (s['finalizadas']  as num?)?.toInt() ?? 0;
    final productividad = (s['productividad'] as num?)?.toDouble() ?? 0;

    if (tipo == 'Enfoque') {
      pomodorosCompletados++;
      tareasFinalizadas += finalizadas;
      if (productividad > 0) {
        sumProductividad += productividad;
        countProductividad++;
      }
      // Pomodoros por día (últimos 7 días)
      try {
        final fecha = DateTime.parse(fechaStr);
        final diaHoy = DateTime(ahora.year, ahora.month, ahora.day);
        final diaS   = DateTime(fecha.year, fecha.month, fecha.day);
        final diff   = diaHoy.difference(diaS).inDays;
        if (diff >= 0 && diff < 7) {
          final key = '${fecha.day}/${fecha.month}';
          pomodorosPorDia[key] = (pomodorosPorDia[key] ?? 0) + 1;
        }
      } catch (_) {}
    } else if (tipo == 'Descanso corto') {
      descansosCortos++;
    } else if (tipo == 'Descanso largo') {
      descansosLargos++;
    }
  }

  final productividadPromedio = countProductividad > 0
      ? sumProductividad / countProductividad
      : 0.0;

  final pct = tareas.isEmpty ? 0.0 : (completadas / tareas.length * 100);

  final ms = DateTime.now().difference(inicio).inMilliseconds;
  print('[Isolate] Completado en $ms ms');

  return EstadisticasTareas(
    total:                  tareas.length,
    completadas:            completadas,
    pendientes:             tareas.length - completadas - vencidas,
    vencidas:               vencidas,
    porMateria:             porMateria,
    porTipo:                porTipo,
    porPrioridad:           porPrioridad,
    porcentajeCompletado:   pct,
    completadasPorDia:      completadasPorDia,
    materiaMasCargada:      materiaMasCargada,
    rachaDias:              rachaDias,
    pomodorosCompletados:   pomodorosCompletados,
    descansosCortos:        descansosCortos,
    descansosLargos:        descansosLargos,
    productividadPromedio:  productividadPromedio,
    tareasFinalizadasEnfoque: tareasFinalizadas,
    pomodorosPorDia:        pomodorosPorDia,
  );
}