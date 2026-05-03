import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../models/tarea_model.dart';
import '../../services/tarea_service.dart';
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

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final hoy       = await TareaService().getHoy();
      final todas     = await TareaService().getAll();
      final ahora     = DateTime.now();
      final pendientes = todas.where((t) => !t.completada).length;
      final vencidas   = todas.where((t) =>
          !t.completada && t.fechaEntrega.isBefore(ahora)).length;
      if (!mounted) return;
      setState(() {
        _tareasHoy      = hoy;
        _totalPendientes = pendientes;
        _totalVencidas   = vencidas;
        _cargando        = false;
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
      appBar: AppBar(
        title: const Text('StudyManager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Estadísticas',
            onPressed: () => context.push('/estadisticas'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saludo
              Text(_saludo,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const Text('¿Qué tienes para hoy?',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),

              // Tarjetas resumen
              Skeletonizer(
                enabled: _cargando,
                child: Row(
                  children: [
                    Expanded(
                      child: _ResumenCard(
                        titulo: 'Pendientes',
                        valor:  '$_totalPendientes',
                        icono:  Icons.pending_actions,
                        color:  AppTheme.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ResumenCard(
                        titulo: 'Vencidas',
                        valor:  '$_totalVencidas',
                        icono:  Icons.warning_amber,
                        color:  AppTheme.danger,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ResumenCard(
                        titulo: 'Hoy',
                        valor:  '${_tareasHoy.length}',
                        icono:  Icons.today,
                        color:  AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Accesos rápidos
              const Text('Accesos rápidos',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _AccesoCard(
                      titulo:  'Mis Tareas',
                      icono:   Icons.assignment,
                      color:   AppTheme.primary,
                      onTap:   () async {
                        await context.push('/tareas');
                        _cargar();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AccesoCard(
                      titulo:  'Modo Enfoque',
                      icono:   Icons.timer,
                      color:   AppTheme.secondary,
                      onTap:   () => context.push('/enfoque'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Tareas de hoy
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Para hoy',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () async {
                      await context.push('/tareas');
                      _cargar();
                    },
                    child: const Text('Ver todas'),
                  ),
                ],
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
                              color:  Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.green.shade200),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.green, size: 36),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('¡Sin tareas para hoy!',
                                          style: TextStyle(
                                              fontWeight:
                                                  FontWeight.bold,
                                              color: Colors.green)),
                                      Text(
                                          'Aprovecha para adelantar trabajo',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: _tareasHoy.map((t) => TareaCard(
                              tarea: t,
                              onTap: () async {
                                await context.push('/tareas/${t.id}');
                                _cargar();
                              },
                              onCompletada: (val) async {
                                await TareaService()
                                    .marcarCompletada(t.id!, val ?? false);
                                _cargar();
                              },
                            )).toList(),
                          ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/tareas/nueva');
          _cargar();
        },
        icon:  const Icon(Icons.add),
        label: const Text('Nueva tarea'),
      ),
    );
  }
}

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
            Text(valor,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(titulo,
                style: const TextStyle(
                    fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _AccesoCard extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  const _AccesoCard({
    required this.titulo,
    required this.icono,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                radius: 24,
                child: Icon(icono, color: color, size: 26),
              ),
              const SizedBox(height: 8),
              Text(titulo,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}