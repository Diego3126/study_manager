import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario_model.dart';

class AuthService {
  final FirebaseAuth            _auth    = FirebaseAuth.instance;
  final FirebaseFirestore        _db      = FirebaseFirestore.instance;
  final FlutterSecureStorage     _secure  = const FlutterSecureStorage();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser              => _auth.currentUser;

  // Referencia al documento del usuario actual
  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('usuarios').doc(_auth.currentUser!.uid);

  // ── REGISTRO ──────────────────────────────────────────────────────────────
  Future<UserCredential> registrar({
    required String nombre,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email, password: password,
    );
    await credential.user!.updateDisplayName(nombre);

    // Crear documento del usuario en Firestore
    await _db.collection('usuarios').doc(credential.user!.uid).set({
      'nombre':      nombre,
      'email':       email,
      'telefono':    '',
      'carrera':     '',
      'semestre':    '',
      'universidad': '',
      'creadoEn':    DateTime.now().toIso8601String(),
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
      email: email, password: password,
    );
    await _guardarLocal(
      nombre: credential.user!.displayName ?? '',
      email:  email,
      user:   credential.user!,
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
    await prefs.setString('email',  usuario.email);
  }

  // ── CAMBIAR CONTRASEÑA ────────────────────────────────────────────────────
  Future<void> cambiarPassword({
    required String passwordActual,
    required String passwordNuevo,
  }) async {
    final user  = _auth.currentUser!;
    final cred  = EmailAuthProvider.credential(
      email:    user.email!,
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
    required User   user,
  }) async {
    final token = await user.getIdToken();
    await _secure.write(key: 'access_token', value: token);
    await _secure.write(key: 'uid',          value: user.uid);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nombre', nombre);
    await prefs.setString('email',  email);
    await prefs.setString('uid',    user.uid);
  }
}