import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../isolates/estadisticas_isolate.dart';
import '../../services/tarea_service.dart';
import '../../themes/app_theme.dart';
import '../../widgets/estado_widget.dart';

class EstadisticasView extends StatefulWidget {
  const EstadisticasView({super.key});

  @override
  State<EstadisticasView> createState() => _EstadisticasViewState();
}

class _EstadisticasViewState extends State<EstadisticasView> {
  bool _cargando = true;
  String? _error;
  EstadisticasTareas? _stats;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final tareas = await TareaService().getAll();
      final stats  = await compute(calcularEstadisticas, tareas);
      if (!mounted) return;
      setState(() { _stats = stats; _cargando = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _cargando = false; });
    }
  }

  static const List<Color> _colores = [
    AppTheme.primary, AppTheme.accent, AppTheme.danger,
    AppTheme.warning, AppTheme.secondary, Color(0xFF9C27B0),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      body: EstadoWidget(
        cargando: false,
        error: _error,
        onReintentar: _cargar,
        hijo: Skeletonizer(
          enabled: _cargando,
          child: _cargando || _stats == null
              ? _buildSkeleton()
              : _buildContenido(),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(3, (_) => Container(
        height: 200,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
      )),
    );
  }

  Widget _buildContenido() {
    final s = _stats!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Resumen general
        Row(
          children: [
            Expanded(child: _StatCard(
                'Total', '${s.total}', Icons.assignment, AppTheme.primary)),
            const SizedBox(width: 8),
            Expanded(child: _StatCard(
                'Completadas', '${s.completadas}', Icons.check_circle, AppTheme.accent)),
            const SizedBox(width: 8),
            Expanded(child: _StatCard(
                'Vencidas', '${s.vencidas}', Icons.warning, AppTheme.danger)),
          ],
        ),
        const SizedBox(height: 16),

        // Porcentaje completado
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Progreso general',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value:           s.porcentajeCompletado / 100,
                    minHeight:       16,
                    backgroundColor: Colors.grey.shade200,
                    color:           AppTheme.accent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${s.porcentajeCompletado.toStringAsFixed(1)}% completado',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppTheme.accent),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // PieChart por tipo
        if (s.porTipo.isNotEmpty) ...[
          _GraficaCard(
            titulo: 'Distribución por tipo',
            child: SizedBox(
              height: 200,
              child: PieChart(PieChartData(
                sections: _buildPieSections(s.porTipo),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              )),
            ),
          ),
          _Leyenda(data: s.porTipo, colores: _colores),
          const SizedBox(height: 16),
        ],

        // BarChart por materia
        if (s.porMateria.isNotEmpty) ...[
          _GraficaCard(
            titulo: 'Tareas por materia',
            child: SizedBox(
              height: 200,
              child: BarChart(BarChartData(
                maxY: s.porMateria.values.fold(0, (a, b) => a > b ? a : b)
                    .toDouble() * 1.3,
                barGroups: _buildBarGroups(s.porMateria),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles:   true,
                      reservedSize: 30,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        final keys = s.porMateria.keys.toList();
                        if (idx < 0 || idx >= keys.length) {
                          return const SizedBox();
                        }
                        final label = keys[idx];
                        final short = label.length > 6
                            ? '${label.substring(0, 5)}.'
                            : label;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(short,
                              style: const TextStyle(fontSize: 9)),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: true),
              )),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections(Map<String, int> data) {
    final total   = data.values.fold(0, (a, b) => a + b);
    final entries = data.entries.toList();
    return List.generate(entries.length, (i) {
      final pct = total > 0
          ? (entries[i].value / total * 100).toStringAsFixed(1)
          : '0';
      return PieChartSectionData(
        value:     entries[i].value.toDouble(),
        color:     _colores[i % _colores.length],
        title:     '$pct%',
        titleStyle: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        radius:    70,
      );
    });
  }

  List<BarChartGroupData> _buildBarGroups(Map<String, int> data) {
    final entries = data.entries.toList();
    return List.generate(entries.length, (i) => BarChartGroupData(
      x: i,
      barRods: [
        BarChartRodData(
          toY:   entries[i].value.toDouble(),
          color: _colores[i % _colores.length],
          width: 18,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    ));
  }
}

class _StatCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  const _StatCard(this.titulo, this.valor, this.icono, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icono, color: color, size: 24),
            const SizedBox(height: 4),
            Text(valor,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(titulo,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _GraficaCard extends StatelessWidget {
  final String titulo;
  final Widget child;
  const _GraficaCard({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  final Map<String, int> data;
  final List<Color> colores;
  const _Leyenda({required this.data, required this.colores});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: List.generate(entries.length, (i) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, color: colores[i % colores.length]),
          const SizedBox(width: 4),
          Text('${entries[i].key} (${entries[i].value})',
              style: const TextStyle(fontSize: 11)),
        ],
      )),
    );
  }
}