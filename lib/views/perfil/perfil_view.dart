import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../themes/app_theme.dart';

class PerfilView extends StatefulWidget {
  const PerfilView({super.key});

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  bool _cargando = true;
  Map<String, String?> _datos = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final datos = await AuthService().getDatosLocales();
    if (!mounted) return;
    setState(() {
      _datos    = datos;
      _cargando = false;
    });
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
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

  String _truncarToken(String? token) {
    if (token == null || token.isEmpty) return 'Sin token';
    if (token.length <= 40) return token;
    return '${token.substring(0, 20)}...${token.substring(token.length - 20)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargar,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar y nombre
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppTheme.primary,
                          child: Text(
                            (_datos['nombre'] ?? 'U')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                                fontSize: 36,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _datos['nombre'] ?? 'Usuario',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _datos['email'] ?? '',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Estado de sesión
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _datos['token'] != null
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _datos['token'] != null
                            ? Colors.green.shade300
                            : Colors.red.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _datos['token'] != null
                              ? Icons.verified_user
                              : Icons.no_accounts,
                          color: _datos['token'] != null
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _datos['token'] != null
                              ? 'Sesión activa — Token presente'
                              : 'Sin token — Sesión no iniciada',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _datos['token'] != null
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // shared_preferences
                  _SeccionCard(
                    titulo: '📦 shared_preferences (no sensible)',
                    color: AppTheme.primary,
                    campos: [
                      _Campo('Nombre',   _datos['nombre'] ?? 'No guardado'),
                      _Campo('Email',    _datos['email']  ?? 'No guardado'),
                      _Campo('UID',      _datos['uid']    ?? 'No guardado'),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // flutter_secure_storage
                  _SeccionCard(
                    titulo: '🔐 flutter_secure_storage (sensible)',
                    color: AppTheme.secondary,
                    campos: [
                      _Campo('UID (seguro)',   _datos['uid_secure'] ?? 'No guardado'),
                      _Campo('Access Token',  _truncarToken(_datos['token'])),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Token completo
                  if (_datos['token'] != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🔑 JWT completo (Firebase ID Token)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1e1e2e),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _datos['token'] ?? '',
                                style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 9,
                                    color: Color(0xFFcdd6f4)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Botón cerrar sesión
                  ElevatedButton.icon(
                    onPressed: _cerrarSesion,
                    icon:  const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SeccionCard extends StatelessWidget {
  final String titulo;
  final Color color;
  final List<_Campo> campos;

  const _SeccionCard({
    required this.titulo,
    required this.color,
    required this.campos,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12)),
            ),
            child: Text(titulo,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 13)),
          ),
          ...campos.map((c) => Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.label,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(c.valor,
                    style: const TextStyle(fontSize: 13)),
                const Divider(height: 16),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _Campo {
  final String label;
  final String valor;
  const _Campo(this.label, this.valor);
}