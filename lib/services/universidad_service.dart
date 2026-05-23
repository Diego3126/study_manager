import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
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
        .map(
          (snap) => snap.docs
              .map((doc) => Universidad.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
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

  // Subir logo a Cloudinary
  Future<String> subirLogo(Uint8List bytes, String nombreUniversidad) async {
    const cloudName = 'dpuave3zd';
    const uploadPreset = 'StudyManager';
    final slug = nombreUniversidad
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^\w]'), '');
    final publicId = 'logos_universidades/$slug';

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['public_id'] = publicId
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: '$slug.jpg'),
      );

    final streamed = await request.send();
    final body = jsonDecode(await streamed.stream.bytesToString());

    if (streamed.statusCode != 200) {
      throw Exception(body['error']?['message'] ?? 'Error al subir logo');
    }

    return body['secure_url'] as String;
  }
}
