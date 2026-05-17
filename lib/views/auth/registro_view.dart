import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/universidad_model.dart';
import '../../services/auth_service.dart';
import '../../services/universidad_service.dart';
import '../../themes/app_theme.dart';

class RegistroView extends StatefulWidget {
  const RegistroView({super.key});

  @override
  State<RegistroView> createState() => _RegistroViewState();
}

class _RegistroViewState extends State<RegistroView> {
  final _formKey    = GlobalKey<FormState>();
  final _nombre     = TextEditingController();
  final _email      = TextEditingController();
  final _password   = TextEditingController();
  final _confirm    = TextEditingController();

  bool          _cargando   = false;
  bool          _verPass    = false;
  String?       _error;

  // Universidad seleccionada
  List<Universidad> _universidades   = [];
  Universidad?      _uniSeleccionada;
  bool              _cargandoUnis    = true;

  @override
  void initState() {
    super.initState();
    _cargarUniversidades();
  }

  Future<void> _cargarUniversidades() async {
    try {
      final unis = await UniversidadService().getAll();
      if (!mounted) return;
      setState(() {
        _universidades  = unis;
        _cargandoUnis   = false;
      });
    } catch (_) {
      setState(() => _cargandoUnis = false);
    }
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _cargando = true; _error = null; });
    try {
      await AuthService().registrar(
        nombre:      _nombre.text.trim(),
        email:       _email.text.trim(),
        password:    _password.text.trim(),
        universidad: _uniSeleccionada?.nombre ?? '',
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
    if (e.contains('email-already-in-use'))
      return 'Ya existe una cuenta con ese correo.';
    if (e.contains('weak-password'))
      return 'La contraseña debe tener al menos 6 caracteres.';
    if (e.contains('invalid-email'))
      return 'El correo no es válido.';
    return 'Error al registrarse. Intenta de nuevo.';
  }

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        leading: IconButton(
          icon:      const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.person_add_rounded,
                    size: 64, color: AppTheme.primary),
                const SizedBox(height: 12),
                const Text('Únete a StudyManager',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize:   20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),

                // Nombre
                TextFormField(
                  controller: _nombre,
                  decoration: const InputDecoration(
                    labelText:  'Nombre completo *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Ingresa tu nombre' : null,
                ),
                const SizedBox(height: 12),

                // Email
                TextFormField(
                  controller:   _email,
                  decoration: const InputDecoration(
                    labelText:  'Correo electrónico *',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || v.isEmpty
                      ? 'Ingresa tu correo' : null,
                ),
                const SizedBox(height: 12),

                // Password
                TextFormField(
                  controller:  _password,
                  obscureText: !_verPass,
                  decoration: InputDecoration(
                    labelText:  'Contraseña * (mín. 6 caracteres)',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_verPass
                          ? Icons.visibility_off : Icons.visibility),
                      onPressed: () =>
                          setState(() => _verPass = !_verPass),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return 'Ingresa una contraseña';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Confirmar password
                TextFormField(
                  controller:  _confirm,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText:  'Confirmar contraseña *',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return 'Confirma tu contraseña';
                    if (v != _password.text)
                      return 'Las contraseñas no coinciden';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Selector de universidad
                _cargandoUnis
                    ? const Center(child: CircularProgressIndicator())
                    : _universidades.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    color: Colors.orange, size: 18),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'No hay universidades registradas. Puedes agregarlas desde el menú principal.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color:    Colors.orange),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : DropdownButtonFormField<Universidad>(
                            value:       _uniSeleccionada,
                            decoration: const InputDecoration(
                              labelText:  'Universidad (opcional)',
                              prefixIcon: Icon(
                                  Icons.account_balance_outlined),
                            ),
                            hint: const Text('Selecciona tu universidad'),
                            items: _universidades.map((u) =>
                                DropdownMenuItem(
                                  value: u,
                                  child: Text(u.nombre,
                                      overflow: TextOverflow.ellipsis),
                                )).toList(),
                            onChanged: (u) =>
                                setState(() => _uniSeleccionada = u),
                          ),

                const SizedBox(height: 8),

                // Error
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:        Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border:       Border.all(
                          color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Botón registrar
                ElevatedButton(
                  onPressed: _cargando ? null : _registrar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _cargando
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color:       Colors.white))
                      : const Text('Crear cuenta',
                          style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}