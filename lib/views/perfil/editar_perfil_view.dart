import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/universidad_model.dart';
import '../../models/usuario_model.dart';
import '../../services/auth_service.dart';
import '../../services/universidad_service.dart';
import '../../themes/app_theme.dart';

class EditarPerfilView extends StatefulWidget {
  const EditarPerfilView({super.key});

  @override
  State<EditarPerfilView> createState() => _EditarPerfilViewState();
}

class _EditarPerfilViewState extends State<EditarPerfilView> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _telefono = TextEditingController();
  final _carrera = TextEditingController();
  final _semestre = TextEditingController();
  final _universidad = TextEditingController();

  bool _cargando = true;
  bool _guardando = false;
  String? _errorEmail;
  Usuario? _usuario;

  // ── Foto: solo bytes en memoria hasta que el usuario guarde ──────────────
  // _fotoBytes     → preview local (nueva foto seleccionada, aún no subida)
  // _fotoUrlActual → URL de Cloudinary ya guardada (la del perfil vigente)
  Uint8List? _fotoBytes;
  String? _fotoUrlActual;
  bool _fotoModificada = false; // true si el usuario cambió la foto

  List<Universidad> _universidades = [];
  bool _cargandoUnis = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final u = await AuthService().getPerfil();
    if (!mounted) return;
    if (u != null) {
      _nombre.text = u.nombre;
      _email.text = u.email;
      _telefono.text = u.telefono;
      _carrera.text = u.carrera;
      _semestre.text = u.semestre;
      _universidad.text = u.universidad;
      _fotoUrlActual = u.fotoPerfil;
    }
    setState(() => _cargandoUnis = true);
    final unis = await UniversidadService().getAll();
    if (!mounted) return;
    setState(() {
      _usuario = u;
      _cargando = false;
      _universidades = unis;
      _cargandoUnis = false;
    });
  }

  // ── Seleccionar foto — solo preview local, NO sube aún ───────────────────
  Future<void> _seleccionarFoto() async {
    final fuente = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (fuente == null) return;

    final picked = await ImagePicker().pickImage(
      source: fuente,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La imagen supera el límite de 5 MB'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Solo guardamos en memoria — no se sube nada hasta _guardar()
    setState(() {
      _fotoBytes = bytes;
      _fotoModificada = true;
    });
  }

  // ── Descartar foto nueva (volver a la original) ───────────────────────────
  void _descartarFoto() {
    setState(() {
      _fotoBytes = null;
      _fotoModificada = false;
    });
  }

  // ── Pedir contraseña para cambio de email ────────────────────────────────
  Future<String?> _pedirPassword() async {
    final controller = TextEditingController();
    bool oculta = true;

    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Confirmar cambio de correo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Para cambiar tu correo electrónico necesitamos verificar tu identidad. Ingresa tu contraseña actual.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: oculta,
                decoration: InputDecoration(
                  labelText: 'Contraseña actual',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      oculta
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setS(() => oculta = !oculta),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOf(context),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Guardar — aquí sí se sube la foto si fue modificada ──────────────────
  Future<void> _guardar() async {
    setState(() => _errorEmail = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    try {
      final emailNuevo = _email.text.trim();
      final emailCambio = emailNuevo != _usuario!.email;

      if (emailCambio) {
        final enUso = await AuthService().emailEnUso(emailNuevo);
        if (enUso) {
          setState(() {
            _errorEmail = 'Ya existe una cuenta con ese correo.';
            _guardando = false;
          });
          return;
        }

        final password = await _pedirPassword();
        if (password == null || password.isEmpty) {
          setState(() => _guardando = false);
          return;
        }

        await AuthService().cambiarEmail(
          emailNuevo: emailNuevo,
          passwordActual: password,
        );

        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Verifica tu nuevo correo'),
            content: Text(
              'Enviamos un enlace de verificación a $emailNuevo. '
              'El cambio se aplicará cuando hagas clic en el enlace.',
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }

      // ✅ Subir foto SOLO si fue modificada y al momento de guardar
      String? nuevaFotoUrl = _fotoUrlActual;
      if (_fotoModificada && _fotoBytes != null) {
        nuevaFotoUrl = await AuthService().subirFotoPerfil(_fotoBytes!);
      }

      final actualizado = _usuario!.copyWith(
        nombre: _nombre.text.trim(),
        email: emailCambio ? _usuario!.email : emailNuevo,
        telefono: _telefono.text.trim(),
        carrera: _carrera.text.trim(),
        semestre: _semestre.text.trim(),
        universidad: _universidad.text.trim(),
        fotoPerfil: nuevaFotoUrl,
      );
      await AuthService().actualizarPerfil(actualizado);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            emailCambio
                ? 'Perfil guardado. Verifica tu nuevo correo para aplicar el cambio.'
                : 'Perfil actualizado correctamente.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('email-already-in-use') ||
          msg.contains('credential-already-in-use')) {
        setState(() => _errorEmail = 'Ya existe una cuenta con ese correo.');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_mensajeError(msg)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  String _mensajeError(String e) {
    if (e.contains('wrong-password') || e.contains('invalid-credential'))
      return 'Contraseña incorrecta.';
    if (e.contains('requires-recent-login'))
      return 'Sesión expirada. Cierra sesión y vuelve a entrar.';
    if (e.contains('invalid-email'))
      return 'El formato del correo no es válido.';
    return 'Error al actualizar. Intenta de nuevo.';
  }

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _telefono.dispose();
    _carrera.dispose();
    _semestre.dispose();
    _universidad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tieneFotoRed = _fotoUrlActual != null && _fotoUrlActual!.isNotEmpty;

    return Scaffold(
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: CustomScrollView(
                slivers: [
                  // ── Header ──────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOf(context),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 16,
                        bottom: 28,
                        left: 20,
                        right: 20,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () => context.pop(),
                          ),
                          const Expanded(
                            child: Text(
                              'Editar Perfil',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),

                  // ── Contenido ────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Avatar con preview local ──────────────────────
                          Center(
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: _seleccionarFoto,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 44,
                                        backgroundColor: AppTheme.primaryOf(
                                          context,
                                        ),
                                        backgroundImage: _fotoBytes != null
                                            ? MemoryImage(_fotoBytes!)
                                            : tieneFotoRed
                                            ? NetworkImage(_fotoUrlActual!)
                                                  as ImageProvider
                                            : null,
                                        child:
                                            (_fotoBytes == null &&
                                                !tieneFotoRed)
                                            ? Text(
                                                _nombre.text.isNotEmpty
                                                    ? _nombre.text[0]
                                                          .toUpperCase()
                                                    : 'U',
                                                style: const TextStyle(
                                                  fontSize: 34,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : null,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.surface,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.camera_alt_rounded,
                                            size: 16,
                                            color: AppTheme.primaryOf(context),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Si hay foto nueva en preview, mostrar opción de descartarla
                                if (_fotoModificada)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 13,
                                        color: AppTheme.primaryOf(context),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Nueva foto (preview)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.primaryOf(context),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: _descartarFoto,
                                        child: Text(
                                          'Descartar',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.danger,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Text(
                                    'Toca para cambiar foto',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Información personal ──────────────────────────
                          _Seccion(titulo: 'Información personal'),
                          TextFormField(
                            controller: _nombre,
                            decoration: const InputDecoration(
                              labelText: 'Nombre completo *',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Campo requerido'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _email,
                            decoration: InputDecoration(
                              labelText: 'Correo electrónico *',
                              prefixIcon: const Icon(Icons.email_outlined),
                              errorText: _errorEmail,
                              errorStyle: const TextStyle(fontSize: 13),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (_) {
                              if (_errorEmail != null) {
                                setState(() => _errorEmail = null);
                              }
                            },
                            validator: (v) => v == null || v.isEmpty
                                ? 'Campo requerido'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _telefono,
                            decoration: const InputDecoration(
                              labelText: 'Teléfono',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 20),

                          // ── Información académica ─────────────────────────
                          _Seccion(titulo: 'Información académica'),
                          TextFormField(
                            controller: _carrera,
                            decoration: const InputDecoration(
                              labelText: 'Carrera',
                              prefixIcon: Icon(Icons.school_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _semestre,
                            decoration: const InputDecoration(
                              labelText: 'Semestre',
                              prefixIcon: Icon(Icons.numbers_outlined),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          _cargandoUnis
                              ? const Center(child: CircularProgressIndicator())
                              : _universidades.isEmpty
                              ? TextFormField(
                                  controller: _universidad,
                                  decoration: const InputDecoration(
                                    labelText: 'Universidad',
                                    prefixIcon: Icon(
                                      Icons.account_balance_outlined,
                                    ),
                                    hintText:
                                        'No hay universidades registradas aún',
                                  ),
                                )
                              : DropdownButtonFormField<String>(
                                  value: _universidad.text.isEmpty
                                      ? null
                                      : _universidades.any(
                                          (u) => u.nombre == _universidad.text,
                                        )
                                      ? _universidad.text
                                      : null,
                                  decoration: const InputDecoration(
                                    labelText: 'Universidad',
                                    prefixIcon: Icon(
                                      Icons.account_balance_outlined,
                                    ),
                                  ),
                                  hint: const Text('Selecciona tu universidad'),
                                  items: _universidades
                                      .map(
                                        (u) => DropdownMenuItem(
                                          value: u.nombre,
                                          child: Text(
                                            u.nombre,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setState(
                                    () => _universidad.text = v ?? '',
                                  ),
                                ),
                          const SizedBox(height: 28),

                          // ── Botones guardar / cancelar ────────────────────
                          ElevatedButton.icon(
                            onPressed: _guardando ? null : _guardar,
                            icon: _guardando
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              _guardando ? 'Guardando...' : 'Guardar cambios',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryOf(context),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // ✅ Botón cancelar — descarta todo y regresa
                          OutlinedButton.icon(
                            onPressed: _guardando ? null : () => context.pop(),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Cancelar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onSurface,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              side: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Seccion extends StatelessWidget {
  final String titulo;
  const _Seccion({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        titulo,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryOf(context),
        ),
      ),
    );
  }
}
