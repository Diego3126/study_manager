import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../models/tarea_model.dart';
import '../../models/usuario_model.dart';
import '../../services/tarea_service.dart';
import '../../services/auth_service.dart';
import '../../themes/app_theme.dart';
import '../../widgets/tarea_card.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  bool _cargando = true;
  List<Tarea> _tareasHoy = [];
  int _totalPendientes = 0;
  int _totalVencidas = 0;
  Usuario? _usuario;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final usuario = await AuthService().getPerfil();
      final hoy = await TareaService().getHoy();
      final todas = await TareaService().getAll();
      final ahora = DateTime.now();
      final pendientes = todas.where((t) => !t.completada).length;
      final vencidas = todas
          .where((t) => !t.completada && t.fechaEntrega.isBefore(ahora))
          .length;
      if (!mounted) return;
      setState(() {
        _usuario = usuario;
        _tareasHoy = hoy;
        _totalPendientes = pendientes;
        _totalVencidas = vencidas;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  String get _saludo {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Buenos días';
    if (hora < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header de perfil ──────────────────────────────────
            SliverToBoxAdapter(
              child: _DashboardHeader(
                usuario: _usuario,
                cargando: _cargando,
                onPerfilTap: () => context.push('/perfil'),
              ),
            ),

            // ── Contenido ─────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Saludo
                  Text(
                    _saludo,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '¿Qué pendientes tendrás para hoy?',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 20),

                  // Tarjetas resumen
                  Skeletonizer(
                    enabled: _cargando,
                    child: Row(
                      children: [
                        Expanded(
                          child: _ResumenCard(
                            titulo: 'Pendientes',
                            valor: '$_totalPendientes',
                            icono: Icons.pending_actions,
                            color: AppTheme.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ResumenCard(
                            titulo: 'Vencidas',
                            valor: '$_totalVencidas',
                            icono: Icons.warning_amber,
                            color: AppTheme.danger,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ResumenCard(
                            titulo: 'Hoy',
                            valor: '${_tareasHoy.length}',
                            icono: Icons.today,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tareas de hoy
                  const Text(
                    'Para hoy',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  Skeletonizer(
                    enabled: _cargando,
                    child: _cargando
                        ? Column(
                            children: List.generate(
                              3,
                              (_) => Container(
                                height: 80,
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          )
                        : _tareasHoy.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 36,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '¡Sin tareas para hoy!',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(
                                        'Aprovecha para adelantar trabajo',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: _tareasHoy
                                .map(
                                  (t) => TareaCard(
                                    tarea: t,
                                    onTap: () async {
                                      await context.push(
                                        '/tareas/${t.firestoreId}',
                                      );
                                      _cargar();
                                    },
                                    onCompletada: (val) async {
                                      await TareaService().marcarCompletada(
                                        t.firestoreId!,
                                        val ?? false,
                                      );
                                      _cargar();
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  final Usuario? usuario;
  final bool cargando;
  final VoidCallback onPerfilTap;

  const _DashboardHeader({
    required this.usuario,
    required this.cargando,
    required this.onPerfilTap,
  });

  @override
  Widget build(BuildContext context) {
    final foto = usuario?.fotoPerfil;
    final tieneFoto = foto != null && foto.isNotEmpty;
    final nombre = usuario?.nombre ?? '';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 24,
        left: 20,
        right: 20,
      ),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: onPerfilTap,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withOpacity(0.25),
                backgroundImage: tieneFoto
                    ? NetworkImage(foto!) as ImageProvider
                    : null,
                child: tieneFoto
                    ? null
                    : Text(
                        nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Nombre y rol
          Expanded(
            child: cargando
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 12,
                        width: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre.isNotEmpty ? nombre : 'Bienvenido',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Estudiante',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          // Nombre de la app
          const Text(
            'StudyManager',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── ResumenCard ───────────────────────────────────────────────────────────────
class _ResumenCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  const _ResumenCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icono, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              valor,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              titulo,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
