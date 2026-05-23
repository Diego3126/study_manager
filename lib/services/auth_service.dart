import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario_model.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Referencia al documento del usuario actual
  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('usuarios').doc(_auth.currentUser!.uid);

  // ── REGISTRO ──────────────────────────────────────────────────────────────
  Future<UserCredential> registrar({
    required String nombre,
    required String email,
    required String password,
    String universidad = '',
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user!.updateDisplayName(nombre);

    // Crear documento del usuario en Firestore
    await _db.collection('usuarios').doc(credential.user!.uid).set({
      'nombre': nombre,
      'email': email,
      'telefono': '',
      'carrera': '',
      'semestre': '',
      'universidad': universidad,
      'creadoEn': DateTime.now().toIso8601String(),
    });

    await _guardarLocal(nombre: nombre, email: email, user: credential.user!);
    return credential;
  }

  // ── LOGIN ─────────────────────────────────────────────────────────────────
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _guardarLocal(
      nombre: credential.user!.displayName ?? '',
      email: email,
      user: credential.user!,
    );
    return credential;
  }

  // ── LOGOUT ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
    await _secure.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ── OBTENER PERFIL ────────────────────────────────────────────────────────
  Future<Usuario?> getPerfil() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;
      await sincronizarEmail();
      final doc = await _db.collection('usuarios').doc(uid).get();
      if (!doc.exists) return null;
      return Usuario.fromFirestore(uid, doc.data()!);
    } catch (_) {
      return null;
    }
  }

  // ── ACTUALIZAR PERFIL ─────────────────────────────────────────────────────
  Future<void> actualizarPerfil(Usuario usuario) async {
    // Actualizar en Firestore
    await _userDoc.update(usuario.toFirestore());

    // Actualizar nombre en Firebase Auth
    await _auth.currentUser!.updateDisplayName(usuario.nombre);

    // Actualizar shared_preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nombre', usuario.nombre);
    await prefs.setString('email', usuario.email);
  }

  // ── CAMBIAR CONTRASEÑA ────────────────────────────────────────────────────
  Future<void> cambiarPassword({
    required String passwordActual,
    required String passwordNuevo,
  }) async {
    final user = _auth.currentUser!;
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: passwordActual,
    );
    // Reautenticar antes de cambiar la contraseña
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(passwordNuevo);
  }

  // ── GUARDAR LOCAL ─────────────────────────────────────────────────────────
  Future<void> _guardarLocal({
    required String nombre,
    required String email,
    required User user,
  }) async {
    final token = await user.getIdToken();
    await _secure.write(key: 'access_token', value: token);
    await _secure.write(key: 'uid', value: user.uid);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nombre', nombre);
    await prefs.setString('email', email);
    await prefs.setString('uid', user.uid);
  }

  // ── ENVIAR VERIFICACIÓN DE EMAIL ──────────────────────────────────────────
  Future<void> enviarVerificacionEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  // ── VERIFICAR SI EL EMAIL YA FUE CONFIRMADO ───────────────────────────────
  Future<bool> emailVerificado() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // ── RECUPERAR CONTRASEÑA ──────────────────────────────────────────────────
  Future<void> enviarResetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ── SUBIR FOTO DE PERFIL (CLOUDINARY) ─────────────────────────────────────
  // Solo se llama al confirmar "Guardar cambios" en editar_perfil_view.dart
  Future<String> subirFotoPerfil(Uint8List bytes) async {
    const cloudName = 'dpuave3zd';
    const uploadPreset = 'StudyManager';

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = 'fotos_perfil'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: '${_auth.currentUser!.uid}.jpg',
        ),
      );

    final streamed = await request.send();
    final body = jsonDecode(await streamed.stream.bytesToString());

    if (streamed.statusCode != 200) {
      throw Exception(body['error']?['message'] ?? 'Error al subir imagen');
    }

    final url = body['secure_url'] as String;

    // Guarda URL en Firestore — solo desde editar perfil
    await _userDoc.update({'fotoPerfil': url});

    return url;
  }

  // ── SUBIR IMAGEN DE TAREA (CLOUDINARY) ────────────────────────────────────
  Future<String> subirImagenTarea(Uint8List bytes) async {
    const cloudName = 'dpuave3zd';
    const uploadPreset = 'StudyManager';

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] =
          'imagenes_tareas' // carpeta separada
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: '${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

    final streamed = await request.send();
    final body = jsonDecode(await streamed.stream.bytesToString());

    if (streamed.statusCode != 200) {
      throw Exception(body['error']?['message'] ?? 'Error al subir imagen');
    }

    // Solo retorna la URL, no modifica ningún documento de Firestore
    return body['secure_url'] as String;
  }

  // ── SUBIR ARCHIVO PDF (CLOUDINARY) ────────────────────────────────────────
  Future<String> subirArchivoPdf(Uint8List bytes, String nombreArchivo) async {
    const cloudName = 'dpuave3zd';
    const uploadPreset = 'StudyManager';

    final nombreSinExtension = nombreArchivo
        .replaceAll(RegExp(r'\.[^.]+$'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^\w\-]'), '');

    final publicId = 'archivos_tareas/$nombreSinExtension';

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/raw/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['public_id'] = publicId
      ..fields['resource_type'] = 'raw'
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: nombreArchivo),
      );

    final streamed = await request.send();
    final body = jsonDecode(await streamed.stream.bytesToString());

    if (streamed.statusCode != 200) {
      throw Exception(body['error']?['message'] ?? 'Error al subir archivo');
    }

    return body['secure_url'] as String;
  }

  // ── CAMBIAR EMAIL CON VERIFICACIÓN ────────────────────────────────────────
  Future<void> cambiarEmail({
    required String emailNuevo,
    required String passwordActual,
  }) async {
    final user = _auth.currentUser!;

    // Reautenticar primero por seguridad
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: passwordActual,
    );
    await user.reauthenticateWithCredential(cred);

    // Envía verificación al nuevo correo; solo cambia al hacer clic en el enlace
    await user.verifyBeforeUpdateEmail(emailNuevo);
  }

  // ── SINCRONIZAR EMAIL DE AUTH CON FIRESTORE ───────────────────────────────
  Future<void> sincronizarEmail() async {
    await _auth.currentUser?.reload();
    final emailAuth = _auth.currentUser?.email;
    if (emailAuth == null) return;

    final doc = await _userDoc.get();
    if (!doc.exists) return;

    final emailFirestore = doc.data()?['email'] as String?;

    if (emailAuth != emailFirestore) {
      await _userDoc.update({'email': emailAuth});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', emailAuth);
    }
  }

  // ── VERIFICAR SI UN EMAIL YA ESTÁ EN USO ─────────────────────────────────
  Future<bool> emailEnUso(String email) async {
    try {
      // Buscar en Firestore si ya existe un documento con ese email
      final query = await _db
          .collection('usuarios')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ── VERIFICAR CONTRASEÑA ACTUAL ───────────────────────────────────────────
  Future<void> verificarPassword(String password) async {
    final user = _auth.currentUser!;
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(cred);
  }

  // ── RECUÉRDAME ────────────────────────────────────────────────────────────
  Future<void> guardarPreferenciaRecordar(bool recordar) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('recordar_sesion', recordar);
  }

  Future<bool> debeRecordarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    // Si nunca se guardó la preferencia, por defecto no recuerda
    return prefs.getBool('recordar_sesion') ?? false;
  }

  Future<void> cerrarSesionSiNoRecuerda() async {
    final hayUsuario = _auth.currentUser != null;
    if (!hayUsuario) return;

    final recuerda = await debeRecordarSesion();
    if (!recuerda) {
      await logout(); // Limpia auth + secure storage + prefs
    }
  }
}
