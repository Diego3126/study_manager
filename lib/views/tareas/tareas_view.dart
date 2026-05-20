import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../models/tarea_model.dart';
import '../../services/tarea_service.dart';
import '../../themes/app_theme.dart';
import '../../widgets/tarea_card.dart';

class TareasView extends StatefulWidget {
  const TareasView({super.key});

  @override
  State<TareasView> createState() => _TareasViewState();
}

class _TareasViewState extends State<TareasView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _cargando = true;
  String? _error;
  List<Tarea> _todas = [];
  List<Tarea> _pendientes = [];
  List<Tarea> _completadas = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final todas = await TareaService().getAll();
      if (!mounted) return;
      setState(() {
        _todas = todas;
        _pendientes = todas.where((t) => !t.completada).toList();
        _completadas = todas.where((t) => t.completada).toList();
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  // ── Frase motivacional ────────────────────────────────────────────────────
  Map<String, String> get _motivacion {
    if (_todas.isEmpty) {
      return {
        'titulo': '¡Todo despejado!',
        'subtitulo':
            'No tienes tareas registradas. ¡Buen momento para adelantar!',
        'emoji': '🎯',
      };
    }
    if (_pendientes.isEmpty) {
      return {
        'titulo': '¡Lo lograste! 🎉',
        'subtitulo': 'Completaste todas tus tareas. ¡Eres increíble!',
        'emoji': '🏆',
      };
    }
    if (_pendientes.length == 1) {
      return {
        'titulo': '¡Casi terminas!',
        'subtitulo': 'Solo te queda 1 tarea. ¡Tú puedes con esto!',
        'emoji': '💪',
      };
    }
    if (_pendientes.length <= 3) {
      return {
        'titulo': '¡Vas muy bien!',
        'subtitulo':
            'Tienes ${_pendientes.length} tareas pendientes. ¡Sigue así!',
        'emoji': '🚀',
      };
    }
    return {
      'titulo': '¡A enfocarse!',
      'subtitulo':
          'Tienes ${_pendientes.length} tareas por entregar. ¡Paso a paso!',
      'emoji': '📚',
    };
  }

  Widget _buildLista(List<Tarea> tareas) {
    if (tareas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'No hay tareas aquí',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        itemCount: tareas.length,
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemBuilder: (context, i) => TareaCard(
          tarea: tareas[i],
          onTap: () async {
            await context.push('/tareas/${tareas[i].firestoreId}');
            _cargar();
          },
          onCompletada: (val) async {
            await TareaService().marcarCompletada(
              tareas[i].firestoreId!,
              val ?? false,
            );
            _cargar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mot = _motivacion;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  const Text(
                    'Mis Tareas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Organiza tu progreso académico',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Tarjeta resumen ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resumen de tareas',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Contadores
                        Skeletonizer(
                          enabled: _cargando,
                          child: Row(
                            children: [
                              _ContadorChip(
                                label: 'Total',
                                valor: _todas.length,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 10),
                              _ContadorChip(
                                label: 'Pendientes',
                                valor: _pendientes.length,
                                color: AppTheme.warning,
                              ),
                              const SizedBox(width: 10),
                              _ContadorChip(
                                label: 'Hechas',
                                valor: _completadas.length,
                                color: AppTheme.accent,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Tarjeta motivacional ─────────────────────────────
                  Skeletonizer(
                    enabled: _cargando,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(
                            mot['emoji']!,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mot['titulo']!,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  mot['subtitulo']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Barra de progreso circular
                          if (_todas.isNotEmpty)
                            _ProgressRing(
                              completadas: _completadas.length,
                              total: _todas.length,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── TabBar ───────────────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                tabs: [
                  Tab(text: 'Todas (${_todas.length})'),
                  Tab(text: 'Pendientes (${_pendientes.length})'),
                  Tab(text: 'Hechas (${_completadas.length})'),
                ],
              ),
            ),
          ),
        ],
        body: _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _cargar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
            : Skeletonizer(
                enabled: _cargando,
                child: _cargando
                    ? ListView.builder(
                        itemCount: 5,
                        itemBuilder: (_, __) => Container(
                          height: 80,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildLista(_todas),
                          _buildLista(_pendientes),
                          _buildLista(_completadas),
                        ],
                      ),
              ),
      ),
      floatingActionButton: null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: ElevatedButton.icon(
            onPressed: () async {
              await context.push('/tareas/nueva');
              _cargar();
            },
            icon: const Icon(Icons.add),
            label: const Text('Nueva tarea'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 2,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Chip contador ─────────────────────────────────────────────────────────────
class _ContadorChip extends StatelessWidget {
  final String label;
  final int valor;
  final Color color;

  const _ContadorChip({
    required this.label,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$valor',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Anillo de progreso ────────────────────────────────────────────────────────
class _ProgressRing extends StatelessWidget {
  final int completadas;
  final int total;

  const _ProgressRing({required this.completadas, required this.total});

  @override
  Widget build(BuildContext context) {
    final porcentaje = total == 0 ? 0.0 : completadas / total;

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: porcentaje,
            strokeWidth: 4,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
          ),
          Text(
            '${(porcentaje * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Delegate para TabBar sticky ───────────────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: const Color(0xFFF4F6FA), child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
