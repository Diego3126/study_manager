import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tarea_model.dart';

class FirestoreService {
  final FirebaseFirestore _db  = FirebaseFirestore.instance;
  final FirebaseAuth      _auth = FirebaseAuth.instance;

  // Subcolección de tareas del usuario actual
  CollectionReference<Map<String, dynamic>> get _tareas {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuario no autenticado');
    return _db.collection('usuarios').doc(uid).collection('tareas');
  }

  // Stream en tiempo real
  Stream<List<Tarea>> getTareasStream() {
    return _tareas
        .orderBy('fechaEntrega', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Tarea.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  // Obtener todas
  Future<List<Tarea>> getAll() async {
    final snap = await _tareas.orderBy('fechaEntrega').get();
    return snap.docs
        .map((doc) => Tarea.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  Future<List<Tarea>> getHoy() async {
  final hoy    = DateTime.now();
  final inicio = DateTime(hoy.year, hoy.month, hoy.day);
  final fin    = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59);

  final snap = await _tareas
      .where('fechaEntrega', isGreaterThanOrEqualTo: inicio.toIso8601String())
      .where('fechaEntrega', isLessThanOrEqualTo: fin.toIso8601String())
      .get();

  final tareas = snap.docs
      .map((doc) => Tarea.fromFirestore(doc.id, doc.data()))
      .toList();

  // ← Filtra por hora real, no solo por día
  return tareas
      .where((t) => t.fechaHoraEntrega.isAfter(hoy) ||
                    _mismoMinuto(t.fechaHoraEntrega, hoy))
      .toList();
}

bool _mismoMinuto(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day &&
    a.hour == b.hour && a.minute == b.minute;

  // Obtener por ID
  Future<Tarea> getById(String id) async {
    final doc = await _tareas.doc(id).get();
    if (!doc.exists) throw Exception('Tarea no encontrada');
    return Tarea.fromFirestore(doc.id, doc.data()!);
  }

  // Crear
  Future<String> crear(Tarea tarea) async {
    final ref = await _tareas.add(tarea.toFirestore());
    return ref.id;
  }

  // Editar
  Future<void> editar(Tarea tarea) async {
    await _tareas.doc(tarea.firestoreId).update(tarea.toFirestore());
  }

  // Marcar completada
  Future<void> marcarCompletada(String id, bool completada) async {
    await _tareas.doc(id).update({'completada': completada});
  }

  // Eliminar
  Future<void> eliminar(String id) async {
    await _tareas.doc(id).delete();
  }

  // ── Chat asistente ────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _chat {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuario no autenticado');
    return _db.collection('usuarios').doc(uid).collection('chat_asistente');
  }

  Future<void> guardarMensaje({
    required String texto,
    required bool esUsuario,
    required DateTime hora,
  }) async {
    await _chat.add({
      'texto': texto,
      'esUsuario': esUsuario,
      'hora': Timestamp.fromDate(hora),
    });
  }

  Future<List<Map<String, dynamic>>> obtenerHistorialChat({int limite = 50}) async {
    final snap = await _chat
        .orderBy('hora', descending: false)
        .limitToLast(limite)
        .get();
    return snap.docs.map((doc) => doc.data()).toList();
  }

  Future<void> limpiarHistorialChat() async {
    final snap = await _chat.get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ── Sesiones pomodoro ─────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _sesiones {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuario no autenticado');
    return _db.collection('usuarios').doc(uid).collection('sesiones_pomodoro');
  }

  Future<Map<String, dynamic>> obtenerResumenPomodoro() async {
    final ahora = DateTime.now();
    final inicioDia = DateTime(ahora.year, ahora.month, ahora.day);
    final inicioSemana = inicioDia.subtract(Duration(days: ahora.weekday - 1));

    final snap = await _sesiones.get();
    final docs = snap.docs.map((d) => d.data()).toList();

    // Sesiones de hoy
    final hoy = docs.where((d) {
      final fecha = DateTime.tryParse(d['fecha'] ?? '');
      return fecha != null && fecha.isAfter(inicioDia);
    }).toList();

    // Sesiones de esta semana
    final semana = docs.where((d) {
      final fecha = DateTime.tryParse(d['fecha'] ?? '');
      return fecha != null && fecha.isAfter(inicioSemana);
    }).toList();

    // Conteos de hoy
    final enfoqueHoy = hoy.where((d) => d['tipo'] == 'Enfoque').length;
    final descansosHoy = hoy.where((d) => d['tipo'] != 'Enfoque').length;
    final productividadHoy = hoy.isEmpty
        ? 0
        : (hoy.map((d) => (d['productividad'] as num?) ?? 0).reduce((a, b) => a + b) / hoy.length).round();

    // Conteos de la semana
    final enfoqueSemana = semana.where((d) => d['tipo'] == 'Enfoque').length;
    final mejorProductividad = semana.isEmpty
        ? 0
        : semana.map((d) => (d['productividad'] as num?) ?? 0).reduce((a, b) => a > b ? a : b);

    return {
      'enfoqueHoy': enfoqueHoy,
      'descansosHoy': descansosHoy,
      'productividadHoy': productividadHoy,
      'enfoqueSemana': enfoqueSemana,
      'mejorProductividad': mejorProductividad,
      'totalSesiones': docs.length,
    };
  }
}