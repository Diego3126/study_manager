import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:study_manager/models/tarea_model.dart';
import '../../isolates/estadisticas_isolate.dart';
import '../../services/tarea_service.dart';
import '../../themes/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EstadisticasView extends StatefulWidget {
  const EstadisticasView({super.key});

  @override
  State<EstadisticasView> createState() => _EstadisticasViewState();
}

class _EstadisticasViewState extends State<EstadisticasView> {
  bool _cargando = true;
  String? _error;
  EstadisticasTareas? _stats;
  bool _verEnfoque = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      final resultados = await Future.wait([
        TareaService().getAll(),
        if (uid != null)
          FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uid)
              .collection('sesiones_pomodoro')
              .get()
              .then((snap) => snap.docs.map((d) => d.data()).toList())
        else
          Future.value(<Map<String, dynamic>>[]),
      ]);

      final tareas = resultados[0] as List<Tarea>;
      final sesiones = resultados[1] as List<Map<String, dynamic>>;

      final stats = await compute(calcularEstadisticas, [tareas, sesiones]);

      if (!mounted) return;
      setState(() {
        _stats = stats;
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

  static const List<Color> _colores = [
    AppTheme.primary,
    AppTheme.accent,
    AppTheme.danger,
    AppTheme.warning,
    AppTheme.secondary,
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFF5722),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Sin backgroundColor hardcodeado — usa scaffoldBackgroundColor del tema
      body: _error != null
          ? _buildError()
          : Skeletonizer(
              enabled: _cargando,
              child: _cargando || _stats == null
                  ? _buildSkeleton()
                  : _buildContenido(),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    // ✅ onSurface con opacidad en lugar de Colors.grey.shade200 fijo
    final skeletonColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.08);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: skeletonColor,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          4,
          (_) => Container(
            height: 160,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContenido() {
    final s = _stats!;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(s)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 20),
              _buildToggle(),
              const SizedBox(height: 20),
              if (!_verEnfoque) ...[
                _buildResumenRapido(s),
                const SizedBox(height: 20),
                _buildProgresoGeneral(s),
                const SizedBox(height: 20),
                _buildActividadSemanal(s),
                const SizedBox(height: 20),
                if (s.porTipo.isNotEmpty) ...[
                  _buildDistribucionTipo(s),
                  const SizedBox(height: 20),
                ],
                if (s.porMateria.isNotEmpty) ...[
                  _buildTareasPorMateria(s),
                  const SizedBox(height: 20),
                ],
                if (s.porPrioridad.isNotEmpty) ...[
                  _buildDistribucionPrioridad(s),
                  const SizedBox(height: 20),
                ],
              ] else ...[
                _buildEstadisticasEnfoque(s),
                const SizedBox(height: 20),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(EstadisticasTareas s) {
    // ✅ primaryOf(context) en lugar de AppTheme.primary fijo
    final primaryColor = AppTheme.primaryOf(context);
    return Container(
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 28,
        left: 20,
        right: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estadísticas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tu rendimiento académico',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildHighlight(
                icono: Icons.local_fire_department_rounded,
                valor: '${s.rachaDias}',
                label: 'Racha días',
                color: AppTheme.warning,
              ),
              const SizedBox(width: 10),
              _buildHighlight(
                icono: Icons.emoji_events_rounded,
                valor: '${s.completadas}',
                label: 'Completadas',
                color: AppTheme.accent,
              ),
              const SizedBox(width: 10),
              _buildHighlight(
                icono: Icons.book_rounded,
                valor: s.materiaMasCargada.isNotEmpty
                    ? (s.materiaMasCargada.length > 8
                          ? '${s.materiaMasCargada.substring(0, 7)}.'
                          : s.materiaMasCargada)
                    : '—',
                label: 'Más cargada',
                color: const Color(0xFF00BCD4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlight({
    required IconData icono,
    required String valor,
    required String label,
    required Color color,
  }) {
    // El header siempre tiene fondo primario (oscuro o claro),
    // así que estos overlays blancos semi-transparentes son correctos en ambos modos
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icono, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              valor,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Resumen rápido (4 tarjetas) ───────────────────────────────────────────
  Widget _buildResumenRapido(EstadisticasTareas s) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        _ResumenTile(
          titulo: 'Total',
          valor: '${s.total}',
          icono: Icons.assignment_outlined,
          color: AppTheme.primary,
        ),
        _ResumenTile(
          titulo: 'Completadas',
          valor: '${s.completadas}',
          icono: Icons.check_circle_outline_rounded,
          color: AppTheme.accent,
        ),
        _ResumenTile(
          titulo: 'Pendientes',
          valor: '${s.pendientes}',
          icono: Icons.pending_actions_rounded,
          color: AppTheme.warning,
        ),
        _ResumenTile(
          titulo: 'Vencidas',
          valor: '${s.vencidas}',
          icono: Icons.warning_amber_rounded,
          color: AppTheme.danger,
        ),
      ],
    );
  }

  // ── Progreso general ──────────────────────────────────────────────────────
  Widget _buildProgresoGeneral(EstadisticasTareas s) {
    final colorScheme = Theme.of(context).colorScheme;
    final pct = s.porcentajeCompletado;
    return _SeccionCard(
      titulo: 'Progreso general',
      icono: Icons.bar_chart_rounded,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${pct.toStringAsFixed(1)}% completado',
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                '${s.completadas} de ${s.total}',
                // ✅ onSurface con opacidad en lugar de Colors.grey fijo
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 12,
              // ✅ onSurface con opacidad en lugar de Colors.grey.shade200 fijo
              backgroundColor: colorScheme.onSurface.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniStat(
                label: 'Tasa éxito',
                valor: '${pct.toStringAsFixed(0)}%',
                color: AppTheme.accent,
              ),
              _MiniStat(
                label: 'Pendientes',
                valor: '${s.pendientes}',
                color: AppTheme.warning,
              ),
              _MiniStat(
                label: 'Vencidas',
                valor: '${s.vencidas}',
                color: AppTheme.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Actividad últimos 7 días ──────────────────────────────────────────────
  Widget _buildActividadSemanal(EstadisticasTareas s) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = AppTheme.primaryOf(context);
    final entries = s.completadasPorDia.entries.toList();
    final maxVal = entries.fold(0, (a, b) => a > b.value ? a : b.value);
    // ✅ Colores de grilla y etiquetas desde el tema
    final gridColor = colorScheme.onSurface.withOpacity(0.07);
    final labelColor = colorScheme.onSurface.withOpacity(0.45);
    final emptyBarColor = colorScheme.onSurface.withOpacity(0.08);

    return _SeccionCard(
      titulo: 'Actividad esta semana',
      icono: Icons.calendar_month_rounded,
      child: SizedBox(
        height: 160,
        child: BarChart(
          BarChartData(
            maxY: (maxVal < 1 ? 3 : maxVal + 1).toDouble(),
            barGroups: List.generate(entries.length, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: entries[i].value.toDouble(),
                    color: entries[i].value > 0 ? primaryColor : emptyBarColor,
                    width: 22,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              );
            }),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= entries.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        entries[i].key,
                        style: TextStyle(fontSize: 10, color: labelColor),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (v, _) => Text(
                    v.toInt().toString(),
                    style: TextStyle(fontSize: 10, color: labelColor),
                  ),
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: gridColor, strokeWidth: 1),
            ),
          ),
        ),
      ),
    );
  }

  // ── Distribución por tipo (PieChart) ──────────────────────────────────────
  Widget _buildDistribucionTipo(EstadisticasTareas s) {
    final colorScheme = Theme.of(context).colorScheme;
    final entries = s.porTipo.entries.toList();
    final total = entries.fold(0, (a, b) => a + b.value);

    return _SeccionCard(
      titulo: 'Distribución por tipo',
      icono: Icons.donut_large_rounded,
      child: Row(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: PieChart(
              PieChartData(
                sections: List.generate(entries.length, (i) {
                  final pct = total > 0
                      ? (entries[i].value / total * 100)
                      : 0.0;
                  return PieChartSectionData(
                    value: entries[i].value.toDouble(),
                    color: _colores[i % _colores.length],
                    title: '${pct.toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    radius: 52,
                  );
                }),
                sectionsSpace: 3,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(entries.length, (i) {
                final pct = total > 0
                    ? (entries[i].value / total * 100).toStringAsFixed(0)
                    : '0';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _colores[i % _colores.length],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entries[i].key,
                          style: TextStyle(
                            fontSize: 12,
                            // ✅ onSurface del tema en lugar de Color(0xFF1A1A2E) fijo
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _colores[i % _colores.length],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tareas por materia (barras horizontales) ──────────────────────────────
  Widget _buildTareasPorMateria(EstadisticasTareas s) {
    final colorScheme = Theme.of(context).colorScheme;
    final entries = s.porMateria.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = entries.first.value;

    return _SeccionCard(
      titulo: 'Tareas por materia',
      icono: Icons.book_outlined,
      child: Column(
        children: List.generate(entries.length, (i) {
          final e = entries[i];
          final ratio = maxVal > 0 ? e.value / maxVal : 0.0;
          final color = _colores[i % _colores.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        e.key,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          // ✅ onSurface del tema en lugar de Color(0xFF1A1A2E) fijo
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${e.value} tarea${e.value != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor: color.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Distribución por prioridad ────────────────────────────────────────────
  Widget _buildDistribucionPrioridad(EstadisticasTareas s) {
    final orden = ['Alta', 'Media', 'Baja'];
    final coloresPrioridad = {
      'Alta': AppTheme.danger,
      'Media': AppTheme.warning,
      'Baja': AppTheme.accent,
    };

    final entries = orden
        .where((p) => s.porPrioridad.containsKey(p))
        .map((p) => MapEntry(p, s.porPrioridad[p]!))
        .toList();

    if (entries.isEmpty) return const SizedBox();

    final total = entries.fold(0, (a, b) => a + b.value);

    return _SeccionCard(
      titulo: 'Distribución por prioridad',
      icono: Icons.flag_rounded,
      child: Column(
        children: entries.map((e) {
          final color = coloresPrioridad[e.key] ?? AppTheme.primary;
          final pct = total > 0 ? e.value / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    e.key,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 10,
                      backgroundColor: color.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 32,
                  child: Text(
                    '${e.value}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Estadísticas de enfoque ───────────────────────────────────────────────
  Widget _buildEstadisticasEnfoque(EstadisticasTareas s) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = AppTheme.primaryOf(context);
    final entries = s.pomodorosPorDia.entries.toList();
    final maxVal = entries.fold(0, (a, b) => a > b.value ? a : b.value);
    final gridColor = colorScheme.onSurface.withOpacity(0.07);
    final labelColor = colorScheme.onSurface.withOpacity(0.45);
    final emptyBarColor = colorScheme.onSurface.withOpacity(0.08);

    return Column(
      children: [
        _SeccionCard(
          titulo: 'Modo Enfoque — resumen',
          icono: Icons.timer_outlined,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniStat(
                    label: 'Pomodoros',
                    valor: '${s.pomodorosCompletados}',
                    color: AppTheme.primary,
                  ),
                  _MiniStat(
                    label: 'Desc. cortos',
                    valor: '${s.descansosCortos}',
                    color: AppTheme.accent,
                  ),
                  _MiniStat(
                    label: 'Desc. largos',
                    valor: '${s.descansosLargos}',
                    color: AppTheme.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Productividad promedio
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Productividad promedio',
                          style: TextStyle(
                            fontSize: 12,
                            // ✅ onSurface con opacidad en lugar de Colors.grey fijo
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: s.productividadPromedio / 100,
                            minHeight: 10,
                            // ✅ onSurface con opacidad en lugar de Colors.grey.shade200
                            backgroundColor:
                                colorScheme.onSurface.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              s.productividadPromedio >= 75
                                  ? AppTheme.accent
                                  : s.productividadPromedio >= 50
                                  ? AppTheme.warning
                                  : AppTheme.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${s.productividadPromedio.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: s.productividadPromedio >= 75
                          ? AppTheme.accent
                          : s.productividadPromedio >= 50
                          ? AppTheme.warning
                          : AppTheme.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tareas finalizadas en sesiones
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  // ✅ primaryOf(context) en lugar de AppTheme.primary fijo
                  color: primaryColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tareas finalizadas en sesiones',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          Text(
                            '${s.tareasFinalizadasEnfoque} tarea${s.tareasFinalizadasEnfoque != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Tiempo enfocado',
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        Text(
                          _formatMinutos(s.pomodorosCompletados * 25),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (s.pomodorosCompletados > 0)
          _SeccionCard(
            titulo: 'Pomodoros esta semana',
            icono: Icons.local_fire_department_rounded,
            child: SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  maxY: (maxVal < 1 ? 3 : maxVal + 1).toDouble(),
                  barGroups: List.generate(entries.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: entries[i].value.toDouble(),
                          color: entries[i].value > 0
                              ? AppTheme.warning
                              : emptyBarColor,
                          width: 22,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= entries.length) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              entries[i].key,
                              style: TextStyle(fontSize: 10, color: labelColor),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (v, _) => Text(
                          v.toInt().toString(),
                          style: TextStyle(fontSize: 10, color: labelColor),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: gridColor, strokeWidth: 1),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatMinutos(int minutos) {
    if (minutos < 60) return '${minutos}min';
    final h = minutos ~/ 60;
    final m = minutos % 60;
    return m > 0 ? '${h}h ${m}min' : '${h}h';
  }

  Widget _buildToggle() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        // ✅ onSurface con opacidad en lugar de Colors.grey.shade100 fijo
        color: colorScheme.onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ToggleBtn(
            label: 'Tareas',
            icono: Icons.assignment_outlined,
            activo: !_verEnfoque,
            onTap: () => setState(() => _verEnfoque = false),
          ),
          _ToggleBtn(
            label: 'Modo Enfoque',
            icono: Icons.timer_outlined,
            activo: _verEnfoque,
            onTap: () => setState(() => _verEnfoque = true),
          ),
        ],
      ),
    );
  }
}

// ── Sección Card reutilizable ─────────────────────────────────────────────────
class _SeccionCard extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Widget child;

  const _SeccionCard({
    required this.titulo,
    required this.icono,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme  = Theme.of(context).colorScheme;
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppTheme.primaryOf(context);

    return Container(
      decoration: BoxDecoration(
        // ✅ surface del tema en lugar de Colors.white fijo
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        // ✅ Sombra solo en claro; borde en oscuro
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
        border: isDark
            ? Border.all(color: const Color(0xFF2A2D45))
            : null,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, color: primaryColor, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  // ✅ onSurface del tema en lugar de Color(0xFF1A1A2E) fijo
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ── Tile del resumen rápido ───────────────────────────────────────────────────
class _ResumenTile extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  const _ResumenTile({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        // ✅ surface del tema en lugar de Colors.white fijo
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        // ✅ Sombra solo en claro; borde en oscuro
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
        border: isDark
            ? Border.all(color: const Color(0xFF2A2D45))
            : null,
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                valor,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 11,
                  // ✅ onSurface con opacidad en lugar de Colors.grey fijo
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Mini stat ─────────────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          valor,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            // ✅ onSurface con opacidad en lugar de Colors.grey fijo
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final IconData icono;
  final bool activo;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.icono,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme  = Theme.of(context).colorScheme;
    final primaryColor = AppTheme.primaryOf(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            // ✅ surface del tema (claro: blanco, oscuro: surface oscuro)
            color: activo ? colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: activo
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icono,
                size: 16,
                // ✅ primaryOf(context) activo / onSurface inactivo
                color: activo
                    ? primaryColor
                    : colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: activo
                      ? primaryColor
                      : colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}