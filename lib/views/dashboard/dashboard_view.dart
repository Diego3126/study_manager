import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../models/tarea_model.dart';
import '../../models/usuario_model.dart';
import '../../services/tarea_service.dart';
import '../../services/auth_service.dart';
import '../../themes/app_theme.dart';
import '../../widgets/tarea_card.dart';
import '../../widgets/dashboard_calendario_widget.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  bool _cargando = true;
  List<Tarea> _tareasSemana = []; // ← CAMBIADO: antes _tareasHoy
  List<Tarea> _todasLasTareas = [];
  int _totalPendientes = 0;
  int _totalCompletadas = 0;
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
      final todas = await TareaService().getAll();
      final ahora = DateTime.now();
      final en7Dias = ahora.add(const Duration(days: 7));

      // ← usa fechaHoraEntrega en todos los filtros
      final semana =
          todas
              .where(
                (t) =>
                    !t.completada &&
                    t.fechaHoraEntrega.isAfter(ahora) &&
                    t.fechaHoraEntrega.isBefore(en7Dias),
              )
              .toList()
            ..sort((a, b) => a.fechaHoraEntrega.compareTo(b.fechaHoraEntrega));

      final pendientes = todas.where((t) => !t.completada).length;
      final completadas = todas.where((t) => t.completada).length;
      final vencidas = todas
          .where((t) => !t.completada && t.fechaHoraEntrega.isBefore(ahora))
          .length;

      if (!mounted) return;
      setState(() {
        _usuario = usuario;
        _tareasSemana = semana;
        _todasLasTareas = todas;
        _totalPendientes = pendientes;
        _totalCompletadas = completadas;
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
            // ── Header de perfil ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: _DashboardHeader(
                usuario: _usuario,
                cargando: _cargando,
                onPerfilTap: () => context.push('/perfil'),
              ),
            ),

            // ── Contenido ─────────────────────────────────────────────────
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

                  // ── NUEVO: Tarjeta resumen general ─────────────────────
                  Skeletonizer(
                    enabled: _cargando,
                    child: _ResumenGeneralCard(
                      totalPendientes: _totalPendientes,
                      totalCompletadas: _totalCompletadas,
                      totalVencidas: _totalVencidas,
                      onVerTareas: () => context.go('/tareas'),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Esta semana ────────────────────────────────────────
                  const Text(
                    'Lo que hay para esta semana',
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
                        : _tareasSemana.isEmpty
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
                                        '¡Sin tareas para esta semana!',
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
                            children: _tareasSemana
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

                  // ── Calendario ────────────────────────────────────────
                  if (_cargando)
                    _CalendarioSkeleton()
                  else
                    DashboardCalendario(tareas: _todasLasTareas),

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

// ─────────────────────────────────────────────────────────────────────────────
// NUEVO: Tarjeta de resumen general
// ─────────────────────────────────────────────────────────────────────────────
class _ResumenGeneralCard extends StatelessWidget {
  final int totalPendientes;
  final int totalCompletadas;
  final int totalVencidas;
  final VoidCallback onVerTareas;

  const _ResumenGeneralCard({
    required this.totalPendientes,
    required this.totalCompletadas,
    required this.totalVencidas,
    required this.onVerTareas,
  });

  @override
  Widget build(BuildContext context) {
    final total = totalPendientes + totalCompletadas;
    final progreso = total > 0 ? totalCompletadas / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Resumen general',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Fila de stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Total',
                valor: '$total',
                color: AppTheme.primary,
                icono: Icons.assignment_outlined,
              ),
              _StatItem(
                label: 'Completadas',
                valor: '$totalCompletadas',
                color: Colors.green,
                icono: Icons.check_circle_outline,
              ),
              _StatItem(
                label: 'Pendientes',
                valor: '$totalPendientes',
                color: AppTheme.warning,
                icono: Icons.pending_actions,
              ),
              _StatItem(
                label: 'Vencidas',
                valor: '$totalVencidas',
                color: AppTheme.danger,
                icono: Icons.warning_amber_outlined,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Barra de progreso
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progreso general',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '${(progreso * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progreso,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Botón ver tareas
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onVerTareas,
              icon: const Icon(Icons.list_alt_rounded, size: 18),
              label: const Text('Ver todas las tareas'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Ítem individual del resumen
class _StatItem extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;
  final IconData icono;

  const _StatItem({
    required this.label,
    required this.valor,
    required this.color,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icono, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton del calendario
// ─────────────────────────────────────────────────────────────────────────────
class _CalendarioSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 16,
          width: 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 320,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
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
