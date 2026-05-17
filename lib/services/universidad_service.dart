import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/universidad_model.dart';

class UniversidadService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('universidades');

  // Stream en tiempo real
  Stream<List<Universidad>> getStream() {
    return _col
        .orderBy('nombre')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Universidad.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  // Obtener todas una vez
  Future<List<Universidad>> getAll() async {
    final snap = await _col.orderBy('nombre').get();
    return snap.docs
        .map((doc) => Universidad.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  // Crear universidad
  Future<void> crear(Universidad u) async {
    await _col.add(u.toFirestore());
  }

  // Eliminar universidad
  Future<void> eliminar(String id) async {
    await _col.doc(id).delete();
  }
}