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
  final _formKey    = GlobalKey<FormState>();
  final _passActual = TextEditingController();

  bool _verActual = false;
  bool _guardando = false;

  @override
  void dispose() {
    _passActual.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ Capturar tema antes del builder
    final primary      = AppTheme.primaryOf(context);
    final onSurface    = Theme.of(context).colorScheme.onSurface;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final dividerColor = Theme.of(context).dividerColor;

    final confirmo = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 28),
              decoration: BoxDecoration(
                color: dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.bolt_rounded,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 24),
            Text(
              'Cambiar Contraseña',
              style: TextStyle(
                fontSize:   20,
                fontWeight: FontWeight.bold,
                color:      onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '¿Estás seguro? Te enviaremos un correo con un enlace '
              'para establecer tu nueva contraseña. El cambio solo '
              'se aplicará cuando hagas clic en ese enlace.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color:    onSurface.withOpacity(0.55),
                height:   1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text(
                  'Sí, enviar correo',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: onSurface,
                  side: BorderSide(color: dividerColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500),
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
    setState(() => _guardando = true);
    try {
      await AuthService().verificarPassword(_passActual.text);

      if (!mounted) return;

      final email = AuthService().currentUser?.email ?? '';
      await AuthService().enviarResetPassword(email);

      if (!mounted) return;
      await _mostrarSheetExito(email);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:         Text(_mensajeError(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _mostrarSheetExito(String email) async {
    // ✅ Capturar tema antes del builder
    final primary      = AppTheme.primaryOf(context);
    final onSurface    = Theme.of(context).colorScheme.onSurface;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final dividerColor = Theme.of(context).dividerColor;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      isDismissible: false,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 28),
              decoration: BoxDecoration(
                color: dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: Colors.green, // semántico, se mantiene
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.mark_email_read_outlined,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 24),
            Text(
              '¡Correo enviado!',
              style: TextStyle(
                fontSize:   20,
                fontWeight: FontWeight.bold,
                color:      onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Hemos enviado un enlace a $email para que '
              'establezcas tu nueva contraseña. El cambio se '
              'aplicará cuando hagas clic en el enlace.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color:    onSurface.withOpacity(0.55),
                height:   1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text(
                  'Entendido, gracias!',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
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
    return 'Error al procesar. Intenta de nuevo.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.primaryOf(context),
              borderRadius: const BorderRadius.only(
                bottomLeft:  Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            padding: EdgeInsets.only(
              top:    MediaQuery.of(context).padding.top + 8,
              bottom: 20,
              left:   4,
              right:  16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                const Text(
                  'Cambiar contraseña',
                  style: TextStyle(
                    color:      Colors.white,
                    fontSize:   18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // ── Formulario ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verificar identidad',
                      style: TextStyle(
                        fontSize:   16,
                        fontWeight: FontWeight.bold,
                        color:      Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ingresa tu contraseña actual para confirmar '
                      'tu identidad. Te enviaremos un correo para '
                      'establecer la nueva contraseña.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface
                            .withOpacity(0.55),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),

                    _CampoLabel('Contraseña Actual'),
                    const SizedBox(height: 8),
                    _CampoPassword(
                      controller: _passActual,
                      hint:       'Mi contraseña actual',
                      ver:        _verActual,
                      onToggle:   () =>
                          setState(() => _verActual = !_verActual),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Ingresa tu contraseña actual' : null,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Botón fijo ────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              20, 12, 20,
              MediaQuery.of(context).padding.bottom + 20,
            ),
            child: SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _guardando ? null : _confirmar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOf(context),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: _guardando
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Continuar',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
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
      style: TextStyle(
        fontSize:   13,
        fontWeight: FontWeight.w500,
        color:      Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _CampoPassword extends StatelessWidget {
  final TextEditingController      controller;
  final String                     hint;
  final bool                       ver;
  final VoidCallback               onToggle;
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
    final primary = AppTheme.primaryOf(context);
    final isDark  = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller:  controller,
      obscureText: !ver,
      validator:   validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText:  hint,
        hintStyle: TextStyle(
          color:    Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
          fontSize: 14,
        ),
        filled:    true,
        fillColor: isDark ? const Color(0xFF242840) : Colors.white,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color:        primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.lock_outline_rounded,
                size: 18, color: primary),
          ),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            ver
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size:  20,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: primary.withOpacity(0.5), width: 1.5),
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
            horizontal: 16, vertical: 14),
      ),
    );
  }
}