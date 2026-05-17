import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  final _formKey     = GlobalKey<FormState>();
  final _nombre      = TextEditingController();
  final _email       = TextEditingController();
  final _telefono    = TextEditingController();
  final _carrera     = TextEditingController();
  final _semestre    = TextEditingController();
  final _universidad = TextEditingController();

  // Contraseña
  final _passActual   = TextEditingController();
  final _passNuevo    = TextEditingController();
  final _passConfirm  = TextEditingController();
  bool  _cambiarPass  = false;
  bool  _verPassActual = false;
  bool  _verPassNuevo  = false;

  // Estado
  bool     _cargando  = true;
  bool     _guardando = false;
  Usuario? _usuario;

  // Universidades
  List<Universidad> _universidades = [];
  bool              _cargandoUnis  = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);

    // Cargar perfil del usuario
    final u = await AuthService().getPerfil();
    if (!mounted) return;
    if (u != null) {
      _nombre.text      = u.nombre;
      _email.text       = u.email;
      _telefono.text    = u.telefono;
      _carrera.text     = u.carrera;
      _semestre.text    = u.semestre;
      _universidad.text = u.universidad;
    }

    // Cargar universidades
    setState(() => _cargandoUnis = true);
    final unis = await UniversidadService().getAll();
    if (!mounted) return;

    setState(() {
      _usuario       = u;
      _cargando      = false;
      _universidades = unis;
      _cargandoUnis  = false;
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final actualizado = _usuario!.copyWith(
        nombre:      _nombre.text.trim(),
        email:       _email.text.trim(),
        telefono:    _telefono.text.trim(),
        carrera:     _carrera.text.trim(),
        semestre:    _semestre.text.trim(),
        universidad: _universidad.text.trim(),
      );
      await AuthService().actualizarPerfil(actualizado);

      if (_cambiarPass && _passNuevo.text.isNotEmpty) {
        await AuthService().cambiarPassword(
          passwordActual: _passActual.text,
          passwordNuevo:  _passNuevo.text,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('Perfil actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
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

  String _mensajeError(String e) {
    if (e.contains('wrong-password') ||
        e.contains('invalid-credential'))
      return 'La contraseña actual es incorrecta.';
    if (e.contains('weak-password'))
      return 'La nueva contraseña debe tener al menos 6 caracteres.';
    if (e.contains('email-already-in-use'))
      return 'Ese correo ya está en uso.';
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
    _passActual.dispose();
    _passNuevo.dispose();
    _passConfirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar
                    Center(
                      child: CircleAvatar(
                        radius:          40,
                        backgroundColor: AppTheme.primary,
                        child: Text(
                          _nombre.text.isNotEmpty
                              ? _nombre.text[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                              fontSize:   34,
                              color:      Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Información personal ──────────────────────────
                    _Seccion(titulo: 'Información personal'),
                    TextFormField(
                      controller: _nombre,
                      decoration: const InputDecoration(
                        labelText:  'Nombre completo *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller:   _email,
                      decoration: const InputDecoration(
                        labelText:  'Correo electrónico *',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller:   _telefono,
                      decoration: const InputDecoration(
                        labelText:  'Teléfono',
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
                        labelText:  'Carrera',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller:   _semestre,
                      decoration: const InputDecoration(
                        labelText:  'Semestre',
                        prefixIcon: Icon(Icons.numbers_outlined),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),

                    // Selector de universidad
                    _cargandoUnis
                        ? const Center(child: CircularProgressIndicator())
                        : _universidades.isEmpty
                            ? TextFormField(
                                controller: _universidad,
                                decoration: const InputDecoration(
                                  labelText:  'Universidad',
                                  prefixIcon: Icon(
                                      Icons.account_balance_outlined),
                                  hintText:
                                      'No hay universidades registradas aún',
                                ),
                              )
                            : DropdownButtonFormField<String>(
                                value: _universidad.text.isEmpty
                                    ? null
                                    : _universidades.any((u) =>
                                            u.nombre == _universidad.text)
                                        ? _universidad.text
                                        : null,
                                decoration: const InputDecoration(
                                  labelText:  'Universidad',
                                  prefixIcon: Icon(
                                      Icons.account_balance_outlined),
                                ),
                                hint: const Text(
                                    'Selecciona tu universidad'),
                                items: _universidades
                                    .map((u) => DropdownMenuItem(
                                          value: u.nombre,
                                          child: Text(u.nombre,
                                              overflow:
                                                  TextOverflow.ellipsis),
                                        ))
                                    .toList(),
                                onChanged: (v) => setState(
                                    () => _universidad.text = v ?? ''),
                              ),
                    const SizedBox(height: 20),

                    // ── Seguridad ─────────────────────────────────────
                    _Seccion(titulo: 'Seguridad'),
                    SwitchListTile(
                      title:    const Text('Cambiar contraseña'),
                      subtitle: const Text(
                          'Activa para establecer una nueva'),
                      value:       _cambiarPass,
                      onChanged:   (v) =>
                          setState(() => _cambiarPass = v),
                      activeColor: AppTheme.primary,
                    ),

                    if (_cambiarPass) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller:  _passActual,
                        obscureText: !_verPassActual,
                        decoration: InputDecoration(
                          labelText:  'Contraseña actual *',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_verPassActual
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () => setState(() =>
                                _verPassActual = !_verPassActual),
                          ),
                        ),
                        validator: _cambiarPass
                            ? (v) => v == null || v.isEmpty
                                ? 'Ingresa tu contraseña actual'
                                : null
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller:  _passNuevo,
                        obscureText: !_verPassNuevo,
                        decoration: InputDecoration(
                          labelText:  'Nueva contraseña *',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_verPassNuevo
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () => setState(() =>
                                _verPassNuevo = !_verPassNuevo),
                          ),
                        ),
                        validator: _cambiarPass
                            ? (v) {
                                if (v == null || v.isEmpty)
                                  return 'Ingresa la nueva contraseña';
                                if (v.length < 6)
                                  return 'Mínimo 6 caracteres';
                                return null;
                              }
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller:  _passConfirm,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText:  'Confirmar nueva contraseña *',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: _cambiarPass
                            ? (v) {
                                if (v == null || v.isEmpty)
                                  return 'Confirma la contraseña';
                                if (v != _passNuevo.text)
                                  return 'Las contraseñas no coinciden';
                                return null;
                              }
                            : null,
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Botón guardar
                    ElevatedButton.icon(
                      onPressed: _guardando ? null : _guardar,
                      icon: _guardando
                          ? const SizedBox(
                              width:  18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:       Colors.white))
                          : const Icon(Icons.save_outlined),
                      label: Text(_guardando
                          ? 'Guardando...' : 'Guardar cambios'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
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
        style: const TextStyle(
          fontSize:   13,
          fontWeight: FontWeight.bold,
          color:      AppTheme.primary,
        ),
      ),
    );
  }
}