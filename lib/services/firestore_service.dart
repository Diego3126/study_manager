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

  // Obtener tareas de hoy
  Future<List<Tarea>> getHoy() async {
    final hoy   = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day);
    final fin    = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59);
    final snap  = await _tareas
        .where('fechaEntrega',
            isGreaterThanOrEqualTo: inicio.toIso8601String())
        .where('fechaEntrega',
            isLessThanOrEqualTo: fin.toIso8601String())
        .get();
    return snap.docs
        .map((doc) => Tarea.fromFirestore(doc.id, doc.data()))
        .toList();
  }

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
}