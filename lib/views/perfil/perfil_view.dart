import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/usuario_model.dart';
import '../../services/auth_service.dart';
import '../../themes/app_theme.dart';

class PerfilView extends StatefulWidget {
  const PerfilView({super.key});

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  bool     _cargando = true;
  Usuario? _usuario;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final u = await AuthService().getPerfil();
    if (!mounted) return;
    setState(() {
      _usuario  = u;
      _cargando = false;
    });
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await AuthService().logout();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          if (_usuario != null)
            IconButton(
              icon:    const Icon(Icons.edit_outlined),
              tooltip: 'Editar perfil',
              onPressed: () async {
                await context.push('/perfil/editar');
                _cargar();
              },
            ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _usuario == null
              ? const Center(child: Text('No se pudo cargar el perfil'))
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius:          48,
                          backgroundColor: AppTheme.primary,
                          child: Text(
                            _usuario!.nombre.isNotEmpty
                                ? _usuario!.nombre[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                                fontSize:   42,
                                color:      Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _usuario!.nombre,
                          style: const TextStyle(
                              fontSize:   22,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _usuario!.email,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),

                        // Tarjeta de información
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Column(
                              children: [
                                _InfoTile(
                                  icono: Icons.person_outline,
                                  label: 'Nombre',
                                  valor: _usuario!.nombre,
                                ),
                                _InfoTile(
                                  icono: Icons.email_outlined,
                                  label: 'Correo',
                                  valor: _usuario!.email,
                                ),
                                _InfoTile(
                                  icono: Icons.lock_outline,
                                  label: 'Contraseña',
                                  valor: '••••••••',
                                ),
                                _InfoTile(
                                  icono: Icons.phone_outlined,
                                  label: 'Teléfono',
                                  valor: _usuario!.telefono.isEmpty
                                      ? 'No registrado'
                                      : _usuario!.telefono,
                                ),
                                _InfoTile(
                                  icono: Icons.school_outlined,
                                  label: 'Carrera',
                                  valor: _usuario!.carrera.isEmpty
                                      ? 'No registrada'
                                      : _usuario!.carrera,
                                ),
                                _InfoTile(
                                  icono: Icons.numbers_outlined,
                                  label: 'Semestre',
                                  valor: _usuario!.semestre.isEmpty
                                      ? 'No registrado'
                                      : _usuario!.semestre,
                                ),
                                _InfoTile(
                                  icono:    Icons.account_balance_outlined,
                                  label:    'Universidad',
                                  valor:    _usuario!.universidad.isEmpty
                                      ? 'No registrada'
                                      : _usuario!.universidad,
                                  esUltimo: true,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Botón cerrar sesión
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _cerrarSesion,
                            icon:  const Icon(Icons.logout,
                                color: Colors.red),
                            label: const Text('Cerrar sesión',
                                style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              side:    const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                            ),
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

class _InfoTile extends StatelessWidget {
  final IconData icono;
  final String   label;
  final String   valor;
  final bool     esUltimo;

  const _InfoTile({
    required this.icono,
    required this.label,
    required this.valor,
    this.esUltimo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icono, color: AppTheme.primary),
          title:   Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Colors.grey)),
          subtitle: Text(valor,
              style: const TextStyle(
                  fontSize: 15, color: Colors.black87)),
        ),
        if (!esUltimo)
          const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}