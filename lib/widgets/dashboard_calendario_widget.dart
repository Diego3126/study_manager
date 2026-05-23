import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/tarea_model.dart';
import '../themes/app_theme.dart';

const List<Color> _materiaPalette = [
  Color(0xFF4C6EF5),
  Color(0xFF0CA678),
  Color(0xFFE67700),
  Color(0xFFAE3EC9),
  Color(0xFFD63939),
  Color(0xFF1098AD),
  Color(0xFF5C940D),
  Color(0xFFE67E22),
  Color(0xFF862E9C),
  Color(0xFF0B7285),
];

Color _colorParaMateria(String materia, Map<String, Color> cache) {
  return cache.putIfAbsent(materia, () {
    final idx = cache.length % _materiaPalette.length;
    return _materiaPalette[idx];
  });
}

class DashboardCalendario extends StatefulWidget {
  final List<Tarea> tareas;
  const DashboardCalendario({super.key, required this.tareas});

  @override
  State<DashboardCalendario> createState() => _DashboardCalendarioState();
}

class _DashboardCalendarioState extends State<DashboardCalendario> {
  late DateTime _mesActual;
  late DateTime _hoy;
  DateTime? _diaSeleccionado;
  final Map<String, Color> _colorCache = {};

  @override
  void initState() {
    super.initState();
    _hoy = DateTime.now();
    _mesActual = DateTime(_hoy.year, _hoy.month);
  }

  List<Tarea> _tareasDelDia(DateTime dia) {
    return widget.tareas.where((t) {
      final f = t.fechaEntrega;
      return f.year == dia.year && f.month == dia.month && f.day == dia.day;
    }).toList();
  }

  bool _esMismoMes(DateTime d) =>
      d.month == _mesActual.month && d.year == _mesActual.year;

  bool _esHoy(DateTime d) =>
      d.day == _hoy.day && d.month == _hoy.month && d.year == _hoy.year;

  bool _esSeleccionado(DateTime d) =>
      _diaSeleccionado != null &&
      d.day == _diaSeleccionado!.day &&
      d.month == _diaSeleccionado!.month &&
      d.year == _diaSeleccionado!.year;

  DateTime get _primerDiaCuadricula {
    final primerDelMes = DateTime(_mesActual.year, _mesActual.month, 1);
    final offset = (primerDelMes.weekday - 1) % 7;
    return primerDelMes.subtract(Duration(days: offset));
  }

  String get _nombreMes {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return '${meses[_mesActual.month - 1]} ${_mesActual.year}';
  }

  void _mesSiguiente() => setState(() {
        _mesActual = DateTime(_mesActual.year, _mesActual.month + 1);
        _diaSeleccionado = null;
      });

  void _mesAnterior() => setState(() {
        _mesActual = DateTime(_mesActual.year, _mesActual.month - 1);
        _diaSeleccionado = null;
      });

  void _mostrarSheet(BuildContext context, Tarea tarea) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TareaSheet(tarea: tarea, colorCache: _colorCache),
    );
  }

  void _mostrarListaTareas(
      BuildContext context, DateTime dia, List<Tarea> tareas) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ListaTareasSheet(
        dia: dia,
        tareas: tareas,
        colorCache: _colorCache,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ← leemos el tema una vez
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1D2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2D45) : Colors.transparent;
    final primary = AppTheme.primaryOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Calendario',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            children: [
              // ── Cabecera mes ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    _NavBtn(icon: Icons.chevron_left, onTap: _mesAnterior),
                    const Spacer(),
                    Text(
                      _nombreMes,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const Spacer(),
                    _NavBtn(icon: Icons.chevron_right, onTap: _mesSiguiente),
                  ],
                ),
              ),

              // ── Días de la semana ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: ['L', 'M', 'X', 'J', 'V', 'S', 'D']
                      .map((d) => Expanded(
                            child: Center(
                              child: Text(
                                d,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: d == 'D'
                                      ? AppTheme.danger
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 6),

              // ── Cuadrícula ───────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.only(left: 8, right: 8, bottom: 12),
                child: _buildCuadricula(context),
              ),

              // ── Leyenda ──────────────────────────────────────────────
              if (_colorCache.isNotEmpty) ...[
                Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFF2A2D45)
                        : Colors.grey.shade200),
                _LeyendaMaterias(colorCache: _colorCache),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCuadricula(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppTheme.primaryOf(context);
    final inicio = _primerDiaCuadricula;
    const totalDias = 42;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 0.72,
      ),
      itemCount: totalDias,
      itemBuilder: (context, i) {
        final dia = inicio.add(Duration(days: i));
        final tareas = _tareasDelDia(dia);
        final esMes = _esMismoMes(dia);
        final esHoy = _esHoy(dia);
        final esSel = _esSeleccionado(dia);

        return GestureDetector(
          onTap: esMes
              ? () {
                  setState(() => _diaSeleccionado = dia);
                  if (tareas.length == 1) {
                    _mostrarSheet(context, tareas.first);
                  } else if (tareas.length > 1) {
                    _mostrarListaTareas(context, dia, tareas);
                  }
                }
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: esHoy
                  ? primary.withOpacity(0.15)
                  : esSel
                      ? primary.withOpacity(0.08)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: esHoy
                  ? Border.all(color: primary, width: 1.5)
                  : esSel
                      ? Border.all(
                          color: primary.withOpacity(0.4), width: 1)
                      : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${dia.day}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        esHoy ? FontWeight.bold : FontWeight.normal,
                    color: esHoy
                        ? primary
                        : esMes
                            ? (isDark
                                ? const Color(0xFFF0F0FF)
                                : Colors.black87)
                            : (isDark
                                ? const Color(0xFF3A3D55)
                                : Colors.grey.shade300),
                  ),
                ),
                const SizedBox(height: 2),
                ...tareas.take(3).map((t) {
                  final color =
                      _colorParaMateria(t.materia, _colorCache);
                  return Container(
                    margin: const EdgeInsets.only(
                        bottom: 2, left: 2, right: 2),
                    height: 5,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
                if (tareas.length > 3)
                  Text(
                    '+${tareas.length - 3}',
                    style: TextStyle(
                      fontSize: 8,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Botón navegación mes ──────────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242840) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark ? const Color(0xFFF0F0FF) : Colors.black87,
        ),
      ),
    );
  }
}

// ── Leyenda de materias ───────────────────────────────────────────────────────
class _LeyendaMaterias extends StatelessWidget {
  final Map<String, Color> colorCache;
  const _LeyendaMaterias({required this.colorCache});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: 10,
        runSpacing: 6,
        children: colorCache.entries.map((e) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: e.value,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                e.key,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? const Color(0xFFB0B0CC)
                      : Colors.black87,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Sheet lista de tareas ─────────────────────────────────────────────────────
class _ListaTareasSheet extends StatelessWidget {
  final DateTime dia;
  final List<Tarea> tareas;
  final Map<String, Color> colorCache;

  const _ListaTareasSheet({
    required this.dia,
    required this.tareas,
    required this.colorCache,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? const Color(0xFF1A1D2E) : Colors.white;
    final textColor = isDark ? const Color(0xFFF0F0FF) : Colors.black87;

    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    final titulo =
        '${dia.day} de ${meses[dia.month - 1]}. de ${dia.year}';

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: sheetColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const _SheetHandle(),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 18, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Text(titulo,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: textColor)),
                  const Spacer(),
                  Text('${tareas.length} tareas',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Divider(
                height: 1,
                color: isDark
                    ? const Color(0xFF2A2D45)
                    : Colors.grey.shade200),
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.all(16),
                itemCount: tareas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final t = tareas[i];
                  final color =
                      _colorParaMateria(t.materia, colorCache);
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _TareaSheet(
                          tarea: t,
                          colorCache: colorCache,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(t.titulo,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: textColor)),
                                Text(t.materia,
                                    style: TextStyle(
                                        fontSize: 11, color: color)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: Colors.grey.shade500, size: 18),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sheet detalle tarea ───────────────────────────────────────────────────────
class _TareaSheet extends StatelessWidget {
  final Tarea tarea;
  final Map<String, Color> colorCache;
  const _TareaSheet({required this.tarea, required this.colorCache});

  String get _estadoTexto {
    if (tarea.completada) return 'Completada';
    if (tarea.fechaEntrega.isBefore(DateTime.now())) return 'Vencida';
    return 'Pendiente';
  }

  Color get _estadoColor {
    if (tarea.completada) return Colors.green;
    if (tarea.fechaEntrega.isBefore(DateTime.now()))
      return const Color(0xFFD63939);
    return const Color(0xFFE67700);
  }

  IconData get _estadoIcono {
    if (tarea.completada) return Icons.check_circle;
    if (tarea.fechaEntrega.isBefore(DateTime.now()))
      return Icons.warning_amber_rounded;
    return Icons.pending_actions;
  }

  String _formatearFecha(DateTime d) {
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${d.day} de ${meses[d.month - 1]}. de ${d.year}';
  }

  String _formatearHora() {
    if (tarea.horaEntrega == null) return 'Sin hora definida';
    final h = tarea.horaEntrega!;
    return '${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? const Color(0xFF1A1D2E) : Colors.white;
    final textColor = isDark ? const Color(0xFFF0F0FF) : const Color(0xFF1A1A2E);
    final subColor = isDark ? const Color(0xFFB0B0CC) : const Color(0xFF444466);
    final chipBg = isDark ? const Color(0xFF242840) : Colors.grey.shade50;
    final chipBorder = isDark ? const Color(0xFF2A2D45) : Colors.grey.shade200;
    final color = _colorParaMateria(tarea.materia, colorCache);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: sheetColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: controller,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 4),

                // Chip materia
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(tarea.materia,
                      style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 10),

                Text(tarea.titulo,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
                const SizedBox(height: 16),

                _InfoRow(
                  icono: _estadoIcono,
                  color: _estadoColor,
                  label: 'Estado',
                  valor: _estadoTexto,
                  valorColor: _estadoColor,
                  bold: true,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icono: Icons.event,
                  color: color,
                  label: 'Fecha de entrega',
                  valor: _formatearFecha(tarea.fechaEntrega),
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icono: Icons.access_time,
                  color: color,
                  label: 'Hora de entrega',
                  valor: _formatearHora(),
                  isDark: isDark,
                ),

                if (tarea.descripcion.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Descripción',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: textColor)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: chipBorder),
                    ),
                    child: Text(tarea.descripcion,
                        style: TextStyle(
                            fontSize: 13, color: subColor, height: 1.5)),
                  ),
                ],

                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ChipInfo(
                        label: 'Tipo',
                        valor: tarea.tipo,
                        icono: Icons.category_outlined,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ChipInfo(
                        label: 'Prioridad',
                        valor: tarea.prioridad,
                        icono: Icons.flag_outlined,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/tareas/${tarea.firestoreId}');
                    },
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Ver detalle completo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOf(context),
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Widgets helper ────────────────────────────────────────────────────────────
class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String label;
  final String valor;
  final Color? valorColor;
  final bool bold;
  final bool isDark;

  const _InfoRow({
    required this.icono,
    required this.color,
    required this.label,
    required this.valor,
    this.valorColor,
    this.bold = false,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 18, color: color),
        const SizedBox(width: 10),
        Text('$label: ',
            style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade500 : Colors.grey)),
        Expanded(
          child: Text(
            valor,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: valorColor ??
                  (isDark ? const Color(0xFFF0F0FF) : Colors.black87),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChipInfo extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icono;
  final bool isDark;

  const _ChipInfo({
    required this.label,
    required this.valor,
    required this.icono,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF242840) : Colors.grey.shade50;
    final border =
        isDark ? const Color(0xFF2A2D45) : Colors.grey.shade200;
    final textColor =
        isDark ? const Color(0xFFF0F0FF) : Colors.black87;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icono,
              size: 16,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: Colors.grey)),
              Text(valor,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textColor)),
            ],
          ),
        ],
      ),
    );
  }
}