import 'dart:ui';
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
  final _formKey  = GlobalKey<FormState>();
  final _nombre   = TextEditingController();
  final _email    = TextEditingController();
  final _password = TextEditingController();
  final _confirm  = TextEditingController();

  bool   _cargando    = false;
  bool   _verPass     = false;
  bool   _verConfirm  = false;
  String? _error;

  // Universidad
  List<Universidad> _universidades  = [];
  Universidad?      _uniSeleccionada;
  bool              _cargandoUnis   = true;

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
        _universidades = unis;
        _cargandoUnis  = false;
      });
    } catch (_) {
      setState(() => _cargandoUnis = false);
    }
  }

  // ── Lógica de registro (igual que antes) ───────────────────────────────────
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

    // Enviar correo de verificación
    await AuthService().enviarVerificacionEmail();

    if (!mounted) return;

    // Mostrar sheet de verificación en lugar de ir directo al home
    await _mostrarSheetVerificacion();

  } on Exception catch (e) {
    setState(() => _error = _mensajeError(e.toString()));
  } finally {
    if (mounted) setState(() => _cargando = false);
  }
}

  Future<void> _mostrarSheetVerificacion() async {
    await showModalBottomSheet(
      context:            context,
      backgroundColor:    Colors.transparent,
      barrierColor:       Colors.black.withOpacity(0.6),
      isDismissible:      false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (_) => _SheetVerificacionEmail(
        email: _email.text.trim(),
        onVerificado: () {
          Navigator.pop(context);
          context.go('/');
        },
        onReenviar: () => AuthService().enviarVerificacionEmail(),
      ),
    );
  }

  String _mensajeError(String e) {
    if (e.contains('email-already-in-use')) return 'Ya existe una cuenta con ese correo.';
    if (e.contains('weak-password'))        return 'La contraseña debe tener al menos 6 caracteres.';
    if (e.contains('invalid-email'))        return 'El correo no es válido.';
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

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [

          // 1. Imagen de fondo (la misma que el login)
          Image.asset(
            'assets/images/login_bg.jpg',
            fit: BoxFit.cover,
          ),

          // 2. Capa oscura
          Container(color: Colors.black.withOpacity(0.40)),

          // 3. Blur
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(color: Colors.transparent),
          ),

          // 4. Contenido con animación al subir teclado
          AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: bottomInset),
            child: SafeArea(
              child: Column(
                children: [
                  const Spacer(),

                  // ── Tarjeta blanca inferior ───────────────────────────
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft:  Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    // usamos SingleChildScrollView para que el contenido
                    // sea scrolleable si el form es muy largo
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            // ── Encabezado ──────────────────────────────
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.person_add_rounded,
                                      color: AppTheme.primary,
                                      size: 34,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Únete a StudyManager',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1A2E),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Crea tu cuenta para empezar',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF8A8A9A),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 28),

                            const Text(
                              'Crear cuenta',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),

                            const SizedBox(height: 18),

                            // ── Nombre ──────────────────────────────────
                            TextFormField(
                              controller: _nombre,
                              style: const TextStyle(
                                  fontSize: 15, color: Color(0xFF1A1A2E)),
                              decoration: _inputDecoration(
                                hint: 'Nombre completo',
                                icon: Icons.person_outline_rounded,
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Ingresa tu nombre'
                                  : null,
                            ),

                            const SizedBox(height: 12),

                            // ── Email ────────────────────────────────────
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(
                                  fontSize: 15, color: Color(0xFF1A1A2E)),
                              decoration: _inputDecoration(
                                hint: 'Correo electrónico',
                                icon: Icons.mail_outline_rounded,
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Ingresa tu correo'
                                  : null,
                            ),

                            const SizedBox(height: 12),

                            // ── Contraseña ───────────────────────────────
                            TextFormField(
                              controller: _password,
                              obscureText: !_verPass,
                              style: const TextStyle(
                                  fontSize: 15, color: Color(0xFF1A1A2E)),
                              decoration: _inputDecoration(
                                hint: 'Contraseña (mín. 6 caracteres)',
                                icon: Icons.lock_outline_rounded,
                                suffix: IconButton(
                                  icon: Icon(
                                    _verPass
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF8A8A9A),
                                    size: 20,
                                  ),
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

                            // ── Confirmar contraseña ─────────────────────
                            TextFormField(
                              controller: _confirm,
                              obscureText: !_verConfirm,
                              style: const TextStyle(
                                  fontSize: 15, color: Color(0xFF1A1A2E)),
                              decoration: _inputDecoration(
                                hint: 'Confirmar contraseña',
                                icon: Icons.lock_outline_rounded,
                                suffix: IconButton(
                                  icon: Icon(
                                    _verConfirm
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF8A8A9A),
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      setState(() => _verConfirm = !_verConfirm),
                                ),
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

                            // ── Selector de universidad ──────────────────
                            if (_cargandoUnis)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              )
                            else if (_universidades.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
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
                                            color: Colors.orange),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              DropdownButtonFormField<Universidad>(
                                value: _uniSeleccionada,
                                decoration: _inputDecoration(
                                  hint: 'Selecciona tu universidad',
                                  icon: Icons.account_balance_outlined,
                                ),
                                hint: const Text(
                                  'Universidad (opcional)',
                                  style: TextStyle(
                                      color: Color(0xFFAAAAAA), fontSize: 15),
                                ),
                                isExpanded: true,
                                items: _universidades
                                    .map((u) => DropdownMenuItem(
                                          value: u,
                                          child: Text(u.nombre,
                                              overflow: TextOverflow.ellipsis),
                                        ))
                                    .toList(),
                                onChanged: (u) =>
                                    setState(() => _uniSeleccionada = u),
                              ),

                            // ── Mensaje de error ─────────────────────────
                            if (_error != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline,
                                        color: Colors.red, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(
                                            color: Colors.red, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // ── Botón crear cuenta ───────────────────────
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _cargando ? null : _registrar,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _cargando
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : const Text(
                                        'Crear cuenta',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ── ¿Ya tienes cuenta? ───────────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '¿Ya tienes cuenta? ',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF5A5A6A)),
                                ),
                                GestureDetector(
                                  onTap: () => context.pop(),
                                  child: Text(
                                    'Inicia sesión',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper: decoración reutilizable para los campos ───────────────────────
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 15),
      prefixIcon: Icon(icon, color: const Color(0xFF8A8A9A), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE8E8F0), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE8E8F0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}

class _SheetVerificacionEmail extends StatefulWidget {
  final String       email;
  final VoidCallback onVerificado;
  final VoidCallback onReenviar;

  const _SheetVerificacionEmail({
    required this.email,
    required this.onVerificado,
    required this.onReenviar,
  });

  @override
  State<_SheetVerificacionEmail> createState() =>
      _SheetVerificacionEmailState();
}

class _SheetVerificacionEmailState extends State<_SheetVerificacionEmail> {
  bool _verificando = false;
  bool _reenviando  = false;
  String? _error;

  Future<void> _verificar() async {
    setState(() { _verificando = true; _error = null; });
    final verificado = await AuthService().emailVerificado();
    if (!mounted) return;
    if (verificado) {
      widget.onVerificado();
    } else {
      setState(() {
        _verificando = false;
        _error = 'Aún no hemos detectado la verificación.\n'
                 'Revisa tu bandeja y vuelve a intentarlo.';
      });
    }
  }

  Future<void> _reenviar() async {
    setState(() { _reenviando = true; _error = null; });
    try {
      widget.onReenviar();
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('Correo reenviado'),
          backgroundColor: Colors.green,
        ),
      );
    } finally {
      if (mounted) setState(() => _reenviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      decoration: const BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pastilla
          Container(
            width:  40, height: 4,
            margin: const EdgeInsets.only(bottom: 28),
            decoration: BoxDecoration(
              color:        Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Ícono
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color:        AppTheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size:  36,
            ),
          ),
          const SizedBox(height: 24),

          // Título
          const Text(
            'Verifica tu correo',
            style: TextStyle(
              fontSize:   20,
              fontWeight: FontWeight.bold,
              color:      Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),

          // Descripción
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                color:    Colors.grey.shade500,
                height:   1.5,
              ),
              children: [
                const TextSpan(
                  text: 'Hemos enviado un enlace de verificación a ',
                ),
                TextSpan(
                  text: widget.email,
                  style: TextStyle(
                    color:      AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(
                  text: '. Ábrelo y luego pulsa el botón de abajo.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Error
          if (_error != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:        Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                          color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Botón ya verifiqué
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _verificando ? null : _verificar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation:       0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _verificando
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Ya verifiqué mi correo',
                      style: TextStyle(
                        fontSize:   15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Botón reenviar
          SizedBox(
            width: double.infinity, height: 50,
            child: OutlinedButton(
              onPressed: _reenviando ? null : _reenviar,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A1A2E),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _reenviando
                  ? SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    )
                  : const Text(
                      'Reenviar correo',
                      style: TextStyle(
                        fontSize:   15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}