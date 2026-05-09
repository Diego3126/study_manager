import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../themes/app_theme.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey   = GlobalKey<FormState>();
  final _email     = TextEditingController();
  final _password  = TextEditingController();
  bool _cargando   = false;
  bool _verPass    = false;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _cargando = true; _error = null; });
    try {
      await AuthService().login(
        email:    _email.text.trim(),
        password: _password.text.trim(),
      );
      if (!mounted) return;
      context.go('/');
    } on Exception catch (e) {
      setState(() => _error = _mensajeError(e.toString()));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _mensajeError(String e) {
    if (e.contains('user-not-found'))   return 'No existe una cuenta con ese correo.';
    if (e.contains('wrong-password'))   return 'Contraseña incorrecta.';
    if (e.contains('invalid-email'))    return 'El correo no es válido.';
    if (e.contains('too-many-requests'))return 'Demasiados intentos. Intenta más tarde.';
    if (e.contains('invalid-credential'))return 'Correo o contraseña incorrectos.';
    return 'Error al iniciar sesión. Intenta de nuevo.';
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Logo e título
                const Icon(Icons.menu_book_rounded,
                    size: 72, color: AppTheme.primary),
                const SizedBox(height: 16),
                const Text('StudyManager',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold)),
                const Text('Tu agenda académica inteligente',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey)),

                const SizedBox(height: 48),
                const Text('Iniciar sesión',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // Email
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || v.isEmpty
                      ? 'Ingresa tu correo' : null,
                ),
                const SizedBox(height: 12),

                // Password
                TextFormField(
                  controller: _password,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_verPass
                          ? Icons.visibility_off : Icons.visibility),
                      onPressed: () =>
                          setState(() => _verPass = !_verPass),
                    ),
                  ),
                  obscureText: !_verPass,
                  validator: (v) => v == null || v.isEmpty
                      ? 'Ingresa tu contraseña' : null,
                ),
                const SizedBox(height: 8),

                // Error
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13))),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Botón login
                ElevatedButton(
                  onPressed: _cargando ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _cargando
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Iniciar sesión',
                          style: TextStyle(fontSize: 16)),
                ),

                const SizedBox(height: 16),

                // Ir a registro
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿No tienes cuenta?'),
                    TextButton(
                      onPressed: () => context.push('/registro'),
                      child: const Text('Regístrate'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}