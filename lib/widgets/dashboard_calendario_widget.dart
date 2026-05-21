
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/tarea_model.dart';
import '../themes/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Paleta de colores por materia  (se asigna dinámicamente)
// ─────────────────────────────────────────────────────────────────────────────
const List<Color> _materiaPalette = [
  Color(0xFF4C6EF5), // índigo
  Color(0xFF0CA678), // esmeralda
  Color(0xFFE67700), // naranja
  Color(0xFFAE3EC9), // púrpura
  Color(0xFFD63939), // rojo
  Color(0xFF1098AD), // cian
  Color(0xFF5C940D), // verde oliva
  Color(0xFFE67E22), // ámbar
  Color(0xFF862E9C), // violeta
  Color(0xFF0B7285), // teal oscuro
];

Color _colorParaMateria(String materia, Map<String, Color> cache) {
  return cache.putIfAbsent(materia, () {
    final idx = cache.length % _materiaPalette.length;
    return _materiaPalette[idx];
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget principal
// ─────────────────────────────────────────────────────────────────────────────
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

  // ── helpers ──────────────────────────────────────────────────────────────

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

  // primer día de la cuadrícula (lunes anterior al 1 del mes)
  DateTime get _primerDiaCuadricula {
    final primerDelMes = DateTime(_mesActual.year, _mesActual.month, 1);
    // weekday: 1=lun … 7=dom
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

  // ── navegación de mes ─────────────────────────────────────────────────────

  void _mesSiguiente() => setState(() {
        _mesActual = DateTime(_mesActual.year, _mesActual.month + 1);
        _diaSeleccionado = null;
      });

  void _mesAnterior() => setState(() {
        _mesActual = DateTime(_mesActual.year, _mesActual.month - 1);
        _diaSeleccionado = null;
      });

  // ── bottom sheet ──────────────────────────────────────────────────────────

  void _mostrarSheet(BuildContext context, Tarea tarea) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TareaSheet(tarea: tarea, colorCache: _colorCache),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de sección
        const Text(
          'Calendario',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Cabecera de mes ──────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    _NavBtn(
                        icon: Icons.chevron_left, onTap: _mesAnterior),
                    const Spacer(),
                    Text(
                      _nombreMes,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    _NavBtn(
                        icon: Icons.chevron_right, onTap: _mesSiguiente),
                  ],
                ),
              ),

              // ── Días de la semana ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: ['L', 'M', 'X', 'J', 'V', 'S', 'D']
                      .map(
                        (d) => Expanded(
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
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 6),

              // ── Cuadrícula ────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.only(left: 8, right: 8, bottom: 12),
                child: _buildCuadricula(context),
              ),

              // ── Leyenda de materias ───────────────────────────────────
              if (_colorCache.isNotEmpty) ...[
                const Divider(height: 1),
                _LeyendaMaterias(colorCache: _colorCache),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCuadricula(BuildContext context) {
    final inicio = _primerDiaCuadricula;
    // Siempre mostramos 6 semanas para que el calendario no salte de altura
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
                  ? AppTheme.primary.withOpacity(0.12)
                  : esSel
                      ? AppTheme.primary.withOpacity(0.08)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: esHoy
                  ? Border.all(color: AppTheme.primary, width: 1.5)
                  : esSel
                      ? Border.all(
                          color: AppTheme.primary.withOpacity(0.4),
                          width: 1)
                      : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                // Número del día
                Text(
                  '${dia.day}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        esHoy ? FontWeight.bold : FontWeight.normal,
                    color: esHoy
                        ? AppTheme.primary
                        : esMes
                            ? Colors.black87
                            : Colors.grey.shade300,
                  ),
                ),
                const SizedBox(height: 2),
                // Puntos / chips de tareas
                ...tareas.take(3).map((t) {
                  final color =
                      _colorParaMateria(t.materia, _colorCache);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 2, left: 2, right: 2),
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
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Botón de navegación del mes
// ─────────────────────────────────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: Colors.black87),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Leyenda de materias
// ─────────────────────────────────────────────────────────────────────────────
class _LeyendaMaterias extends StatelessWidget {
  final Map<String, Color> colorCache;

  const _LeyendaMaterias({required this.colorCache});

  @override
  Widget build(BuildContext context) {
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
                style:
                    const TextStyle(fontSize: 11, color: Colors.black87),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet: lista de tareas de un día (cuando hay más de 1)
// ─────────────────────────────────────────────────────────────────────────────
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const _SheetHandle(),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    titulo,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const Spacer(),
                  Text(
                    '${tareas.length} tareas',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
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
                        border: Border.all(
                            color: color.withOpacity(0.3)),
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
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                Text(t.materia,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: color)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: Colors.grey, size: 18),
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

// ─────────────────────────────────────────────────────────────────────────────
// Sheet: detalle de una tarea
// ─────────────────────────────────────────────────────────────────────────────
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
    final hStr = h.hour.toString().padLeft(2, '0');
    final mStr = h.minute.toString().padLeft(2, '0');
    return '$hStr:$mStr';
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorParaMateria(tarea.materia, colorCache);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: controller,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                const _SheetHandle(),
                const SizedBox(height: 4),

                // Chip de materia
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(
                    tarea.materia,
                    style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 10),

                // Título
                Text(
                  tarea.titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Estado
                _InfoRow(
                  icono: _estadoIcono,
                  color: _estadoColor,
                  label: 'Estado',
                  valor: _estadoTexto,
                  valorColor: _estadoColor,
                  bold: true,
                ),
                const SizedBox(height: 10),

                // Fecha de entrega
                _InfoRow(
                  icono: Icons.event,
                  color: color,
                  label: 'Fecha de entrega',
                  valor: _formatearFecha(tarea.fechaEntrega),
                ),
                const SizedBox(height: 10),

                // Hora de entrega
                _InfoRow(
                  icono: Icons.access_time,
                  color: color,
                  label: 'Hora de entrega',
                  valor: _formatearHora(),
                ),

                // Descripción
                if (tarea.descripcion.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Descripción',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      tarea.descripcion,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF444466),
                          height: 1.5),
                    ),
                  ),
                ],

                // Tipo y prioridad
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ChipInfo(
                        label: 'Tipo',
                        valor: tarea.tipo,
                        icono: Icons.category_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ChipInfo(
                        label: 'Prioridad',
                        valor: tarea.prioridad,
                        icono: Icons.flag_outlined,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Botón ver detalle completo
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
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Helpers de UI reutilizables
// ─────────────────────────────────────────────────────────────────────────────

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

  const _InfoRow({
    required this.icono,
    required this.color,
    required this.label,
    required this.valor,
    this.valorColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style:
              const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        Expanded(
          child: Text(
            valor,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  bold ? FontWeight.bold : FontWeight.w500,
              color: valorColor ?? Colors.black87,
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

  const _ChipInfo({
    required this.label,
    required this.valor,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icono, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: Colors.grey)),
              Text(valor,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}