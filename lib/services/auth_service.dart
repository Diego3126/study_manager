import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Stream para escuchar cambios de sesión
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuario actual
  User? get currentUser => _auth.currentUser;

  // ── REGISTRO ──────────────────────────────────────────────────────────────
  Future<UserCredential> registrar({
    required String nombre,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email:    email,
      password: password,
    );

    // Actualizar nombre en Firebase Auth
    await credential.user!.updateDisplayName(nombre);

    // Guardar datos localmente
    await _guardarDatosLocales(
      nombre: nombre,
      email:  email,
      user:   credential.user!,
    );

    return credential;
  }

  // ── LOGIN ─────────────────────────────────────────────────────────────────
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email:    email,
      password: password,
    );

    // Guardar datos localmente
    await _guardarDatosLocales(
      nombre: credential.user!.displayName ?? '',
      email:  email,
      user:   credential.user!,
    );

    return credential;
  }

  // ── CERRAR SESIÓN ─────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
    await _limpiarDatosLocales();
  }

  // ── GUARDAR DATOS LOCALES ─────────────────────────────────────────────────
  Future<void> _guardarDatosLocales({
    required String nombre,
    required String email,
    required User user,
  }) async {
    // Token JWT desde Firebase
    final token = await user.getIdToken();

    // flutter_secure_storage — datos sensibles
    await _secureStorage.write(key: 'access_token', value: token);
    await _secureStorage.write(key: 'uid',          value: user.uid);

    // shared_preferences — datos no sensibles
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nombre', nombre);
    await prefs.setString('email',  email);
    await prefs.setString('uid',    user.uid);
  }

  // ── LIMPIAR DATOS LOCALES ─────────────────────────────────────────────────
  Future<void> _limpiarDatosLocales() async {
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ── LEER DATOS LOCALES ────────────────────────────────────────────────────
  Future<Map<String, String?>> getDatosLocales() async {
    final prefs  = await SharedPreferences.getInstance();
    final token  = await _secureStorage.read(key: 'access_token');
    final uid    = await _secureStorage.read(key: 'uid');

    return {
      'nombre': prefs.getString('nombre'),
      'email':  prefs.getString('email'),
      'uid':    prefs.getString('uid'),
      'token':  token,
      'uid_secure': uid,
    };
  }

  // ── VERIFICAR SI HAY SESIÓN ───────────────────────────────────────────────
  Future<bool> haySesion() async {
    final token = await _secureStorage.read(key: 'access_token');
    return token != null && _auth.currentUser != null;
  }
}