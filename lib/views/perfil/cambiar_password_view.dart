import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../themes/app_theme.dart';

class CambiarPasswordView extends StatefulWidget {
  const CambiarPasswordView({super.key});

  @override
  State<CambiarPasswordView> createState() => _CambiarPasswordViewState();
}

class _CambiarPasswordViewState extends State<CambiarPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _passActual = TextEditingController();
  final _passNuevo = TextEditingController();
  final _passConfirm = TextEditingController();

  bool _verActual = false;
  bool _verNuevo = false;
  bool _verConfirm = false;
  bool _guardando = false;

  @override
  void dispose() {
    _passActual.dispose();
    _passNuevo.dispose();
    _passConfirm.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final confirmo = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pastilla
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 28),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Ícono
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),

            // Título
            const Text(
              'Actualizar Contraseña',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),

            // Descripción
            Text(
              '¿Estás seguro de que quieres actualizar tu contraseña? '
              'Para garantizar la seguridad de tu cuenta, enviaremos un '
              'código de verificación a tu correo electrónico.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // Botón confirmar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Sí, Actualizar Contraseña',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Botón cancelar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A1A2E),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'No, dejame revisar de nuevo',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmo == true) _guardar();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await AuthService().cambiarPassword(
        passwordActual: _passActual.text,
        passwordNuevo: _passNuevo.text,
      );
      if (!mounted) return;
      await _mostrarSheetExito();
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mensajeError(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _mostrarSheetExito() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      isDismissible: false,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 28),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Ícono
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Password Updated!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),

            Text(
              'Tu contraseña ha sido actualizada correctamente. '
              'Ya puedes acceder a tu cuenta con la nueva contraseña.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // cierra sheet
                  context.pop(); // vuelve al perfil
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Yes, Update Password',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _mensajeError(String e) {
    if (e.contains('wrong-password') || e.contains('invalid-credential'))
      return 'La contraseña actual es incorrecta.';
    if (e.contains('weak-password'))
      return 'La nueva contraseña debe tener al menos 6 caracteres.';
    return 'Error al actualizar. Intenta de nuevo.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: Column(
        children: [
          // ── Header azul ───────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 20,
              left: 4,
              right: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => context.pop(),
                ),
                const Text(
                  'Cambiar contraseña',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Espacio para equilibrar el Row
                const SizedBox(width: 48),
              ],
            ),
          ),

          // ── Formulario (scrolleable) ───────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Formulario para cambiar contraseña',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'LLena los campos para actualizar tu contraseña.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 28),

                    _CampoLabel('Contraseña Actual'),
                    const SizedBox(height: 8),
                    _CampoPassword(
                      controller: _passActual,
                      hint: 'Mi contraseña actual',
                      ver: _verActual,
                      onToggle: () => setState(() => _verActual = !_verActual),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Ingresa tu contraseña actual'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    _CampoLabel('Nueva Contraseña'),
                    const SizedBox(height: 8),
                    _CampoPassword(
                      controller: _passNuevo,
                      hint: 'Mi nueva contraseña',
                      ver: _verNuevo,
                      onToggle: () => setState(() => _verNuevo = !_verNuevo),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Ingresa la nueva contraseña';
                        if (v.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    _CampoLabel('Confirmar Nueva Contraseña'),
                    const SizedBox(height: 8),
                    _CampoPassword(
                      controller: _passConfirm,
                      hint: 'Confirma tu nueva contraseña',
                      ver: _verConfirm,
                      onToggle: () =>
                          setState(() => _verConfirm = !_verConfirm),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Confirma la contraseña';
                        if (v != _passNuevo.text)
                          return 'Las contraseñas no coinciden';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Botón fijo en la parte inferior ───────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(context).padding.bottom + 20,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _guardando ? null : _confirmar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Actualizar contraseña',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _CampoLabel extends StatelessWidget {
  final String text;
  const _CampoLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1A1A2E),
      ),
    );
  }
}

class _CampoPassword extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool ver;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _CampoPassword({
    required this.controller,
    required this.hint,
    required this.ver,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !ver,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        // Ícono de candado con fondo suave (igual al diseño)
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: AppTheme.primary,
            ),
          ),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            ver ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: Colors.grey.shade400,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.primary.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
