import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/tarea_model.dart';
import '../../services/tarea_service.dart';
import '../../themes/app_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MODELO DE SESIÓN KANBAN
// ══════════════════════════════════════════════════════════════════════════════
enum KanbanEstado { porHacer, enProgreso, finalizado }

class KanbanTarea {
  final Tarea tarea;
  KanbanEstado estado;

  KanbanTarea({required this.tarea, this.estado = KanbanEstado.porHacer});
}

// ══════════════════════════════════════════════════════════════════════════════
// VISTA PRINCIPAL
// ══════════════════════════════════════════════════════════════════════════════
class EnfoqueView extends StatefulWidget {
  const EnfoqueView({super.key});

  @override
  State<EnfoqueView> createState() => _EnfoqueViewState();
}

class _EnfoqueViewState extends State<EnfoqueView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Kanban
  List<KanbanTarea> _kanbanTareas = [];
  bool _cargandoTareas = true;
  bool _sesionIniciada = false;

  // Timer Pomodoro
  static const Map<String, int> _modos = {
    'Enfoque': 25 * 60,
    'Descanso corto': 5 * 60,
    'Descanso largo': 15 * 60,
  };
  String _modoActual = 'Enfoque';
  int _segundos = 25 * 60;
  bool _corriendo = false;
  int _sesiones = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarTareas();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // ── Cargar tareas pendientes ────────────────────────────────────────────────
  Future<void> _cargarTareas() async {
    setState(() => _cargandoTareas = true);
    try {
      final todas = await TareaService().getAll();
      final pendientes = todas.where((t) => !t.completada).toList();
      setState(() {
        _kanbanTareas = pendientes.map((t) => KanbanTarea(tarea: t)).toList();
        _cargandoTareas = false;
      });
    } catch (_) {
      setState(() => _cargandoTareas = false);
    }
  }

  // ── Mover tarea entre columnas ─────────────────────────────────────────────
  void _moverTarea(KanbanTarea kt, KanbanEstado nuevoEstado) {
    setState(() => kt.estado = nuevoEstado);
  }

  // ── Getters por columna ────────────────────────────────────────────────────
  List<KanbanTarea> get _porHacer =>
      _kanbanTareas.where((k) => k.estado == KanbanEstado.porHacer).toList();
  List<KanbanTarea> get _enProgreso =>
      _kanbanTareas.where((k) => k.estado == KanbanEstado.enProgreso).toList();
  List<KanbanTarea> get _finalizado =>
      _kanbanTareas.where((k) => k.estado == KanbanEstado.finalizado).toList();

  // ── Timer ──────────────────────────────────────────────────────────────────
  void _iniciar() {
    if (!_sesionIniciada) setState(() => _sesionIniciada = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_segundos == 0) {
        _timer?.cancel();
        setState(() => _corriendo = false);
        if (_modoActual == 'Enfoque') {
          setState(() => _sesiones++);
          _mostrarResultados();
        } else {
          _mostrarSnack('¡Descanso terminado! A enfocarse 💪');
        }
      } else {
        setState(() => _segundos--);
      }
    });
    setState(() => _corriendo = true);
  }

  void _pausar() {
    _timer?.cancel();
    setState(() => _corriendo = false);
  }

  void _reiniciar() {
    _timer?.cancel();
    setState(() {
      _segundos = _modos[_modoActual]!;
      _corriendo = false;
    });
  }

  void _cambiarModo(String modo) {
    _timer?.cancel();
    setState(() {
      _modoActual = modo;
      _segundos = _modos[modo]!;
      _corriendo = false;
    });
  }

  void _mostrarSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.accent),
    );
  }

  // ── Mostrar resultados del Pomodoro ───────────────────────────────────────
  void _mostrarResultados() {
    final enProgreso = _enProgreso.length;
    final finalizado = _finalizado.length;
    final total = enProgreso + finalizado;
    final pct = total == 0 ? 0 : (finalizado / total * 100).round();

    String mensaje;
    Color colorMensaje;
    String emoji;

    if (pct >= 80) {
      mensaje =
          '¡Excelente sesión! Completaste la mayoría de tus tareas. ¡Sigue así!';
      colorMensaje = Colors.green;
      emoji = '🏆';
    } else if (pct >= 50) {
      mensaje =
          '¡Buen trabajo! Completaste más de la mitad. En el siguiente Pomodoro puedes mejorar.';
      colorMensaje = Colors.orange;
      emoji = '💪';
    } else if (finalizado > 0) {
      mensaje =
          'Completaste algunas tareas. Intenta enfocarte en menos tareas en la próxima sesión.';
      colorMensaje = Colors.orange;
      emoji = '📝';
    } else {
      mensaje =
          'Esta vez fue difícil. Recuerda poner menos tareas en "En progreso" para la próxima sesión.';
      colorMensaje = Colors.red;
      emoji = '💡';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('$emoji Resultados del Pomodoro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gráfica simple de productividad
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ResultadoItem(
                  label: 'En progreso',
                  valor: '$enProgreso',
                  color: Colors.orange,
                  icono: Icons.pending_actions,
                ),
                _ResultadoItem(
                  label: 'Finalizado',
                  valor: '$finalizado',
                  color: Colors.green,
                  icono: Icons.check_circle,
                ),
                _ResultadoItem(
                  label: 'Productividad',
                  valor: '$pct%',
                  color: colorMensaje,
                  icono: Icons.bar_chart,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                color: colorMensaje,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorMensaje.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorMensaje.withOpacity(0.3)),
              ),
              child: Text(
                mensaje,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorMensaje, fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _guardarSesion(finalizado, enProgreso, pct);
            },
            child: const Text('Nueva sesión'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _guardarSesion(finalizado, enProgreso, pct);
              _resetKanban();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }

  // ── Guardar sesión en Firestore ────────────────────────────────────────────
  Future<void> _guardarSesion(
    int finalizadas,
    int enProgreso,
    int productividad,
  ) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('sesiones_pomodoro')
          .add({
            'fecha': DateTime.now().toIso8601String(),
            'finalizadas': finalizadas,
            'enProgreso': enProgreso,
            'productividad': productividad,
            'sesiones': _sesiones,
          });
    } catch (_) {}
  }

  // ── Reset Kanban ───────────────────────────────────────────────────────────
  void _resetKanban() {
    setState(() {
      for (final kt in _kanbanTareas) {
        kt.estado = KanbanEstado.porHacer;
      }
      _sesionIniciada = false;
      _sesiones = 0;
      _segundos = _modos[_modoActual]!;
      _corriendo = false;
    });
    _timer?.cancel();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String get _tiempoFormateado {
    final min = _segundos ~/ 60;
    final segs = _segundos % 60;
    return '${min.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
  }

  double get _progreso {
    final total = _modos[_modoActual]!;
    return 1 - (_segundos / total);
  }

  Color get _colorModo {
    switch (_modoActual) {
      case 'Enfoque':
        return AppTheme.primary;
      case 'Descanso corto':
        return AppTheme.accent;
      default:
        return AppTheme.secondary;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo Enfoque'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.view_kanban), text: 'Kanban'),
            Tab(icon: Icon(Icons.timer), text: 'Pomodoro'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildKanban(), _buildPomodoro()],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1 — KANBAN
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildKanban() {
    if (_cargandoTareas) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_kanbanTareas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            const Text(
              'No tienes tareas pendientes',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '¡Crea tareas primero para organizar tu sesión!',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _cargarTareas,
              icon: const Icon(Icons.refresh),
              label: const Text('Recargar'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Banner de instrucción
        if (!_sesionIniciada)
          Container(
            padding: const EdgeInsets.all(10),
            color: AppTheme.primary.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primary, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Arrastra las tareas que harás hoy a "En progreso", luego inicia el Pomodoro.',
                    style: TextStyle(fontSize: 12, color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),

        // Tablero Kanban horizontal
        Expanded(
          child: Row(
            children: [
              _KanbanColumna(
                titulo: 'Por hacer',
                color: Colors.grey,
                icono: Icons.radio_button_unchecked,
                tareas: _porHacer,
                estado: KanbanEstado.porHacer,
                onAcepto: (kt) => _moverTarea(kt, KanbanEstado.porHacer),
              ),
              _KanbanColumna(
                titulo: 'En progreso',
                color: Colors.orange,
                icono: Icons.pending_actions,
                tareas: _enProgreso,
                estado: KanbanEstado.enProgreso,
                onAcepto: (kt) => _moverTarea(kt, KanbanEstado.enProgreso),
              ),
              _KanbanColumna(
                titulo: 'Finalizado',
                color: Colors.green,
                icono: Icons.check_circle,
                tareas: _finalizado,
                estado: KanbanEstado.finalizado,
                onAcepto: (kt) => _moverTarea(kt, KanbanEstado.finalizado),
              ),
            ],
          ),
        ),

        // Botón ir al Pomodoro
        if (_enProgreso.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(1),
              icon: const Icon(Icons.play_arrow),
              label: Text(
                'Iniciar Pomodoro con ${_enProgreso.length} tarea(s)',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2 — POMODORO
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPomodoro() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Selector de modo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: _modos.keys
                    .map(
                      (modo) => Expanded(
                        child: GestureDetector(
                          onTap: () => _cambiarModo(modo),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.all(4),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _modoActual == modo
                                  ? _colorModo
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              modo,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _modoActual == modo
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Círculo de progreso
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: _progreso,
                  strokeWidth: 12,
                  color: _colorModo,
                  backgroundColor: _colorModo.withOpacity(0.1),
                ),
              ),
              Column(
                children: [
                  Text(
                    _tiempoFormateado,
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: _colorModo,
                    ),
                  ),
                  Text(
                    _corriendo ? '▶ En progreso' : '⏸ Pausado',
                    style: TextStyle(color: _colorModo, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Botones
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_corriendo)
                ElevatedButton.icon(
                  onPressed: _iniciar,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    _segundos == _modos[_modoActual]! ? 'Iniciar' : 'Reanudar',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _colorModo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _pausar,
                  icon: const Icon(Icons.pause),
                  label: const Text('Pausar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _reiniciar,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reiniciar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Sesiones completadas
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_sesiones sesión${_sesiones != 1 ? 'es' : ''} completada${_sesiones != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Resumen de tareas de la sesión actual
          if (_sesionIniciada) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sesión actual',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _MiniStat(
                          'En progreso',
                          '${_enProgreso.length}',
                          Colors.orange,
                        ),
                        _MiniStat(
                          'Finalizado',
                          '${_finalizado.length}',
                          Colors.green,
                        ),
                        _MiniStat(
                          'Por hacer',
                          '${_porHacer.length}',
                          Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Botón ver resultados manualmente
          if (_sesionIniciada && _finalizado.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton.icon(
                onPressed: _mostrarResultados,
                icon: const Icon(Icons.bar_chart),
                label: const Text('Ver mis resultados'),
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGET — COLUMNA KANBAN
// ══════════════════════════════════════════════════════════════════════════════
class _KanbanColumna extends StatelessWidget {
  final String titulo;
  final Color color;
  final IconData icono;
  final List<KanbanTarea> tareas;
  final KanbanEstado estado;
  final ValueChanged<KanbanTarea> onAcepto;

  const _KanbanColumna({
    required this.titulo,
    required this.color,
    required this.icono,
    required this.tareas,
    required this.estado,
    required this.onAcepto,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DragTarget<KanbanTarea>(
        onAcceptWithDetails: (details) => onAcepto(details.data),
        onWillAcceptWithDetails: (details) => details.data.estado != estado,
        builder: (context, candidateData, rejectedData) {
          final isHover = candidateData.isNotEmpty;
          return Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isHover ? color.withOpacity(0.15) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isHover ? color : Colors.grey.shade200,
                width: isHover ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                // Header columna
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icono, color: color, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          titulo,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${tareas.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tareas de la columna
                Expanded(
                  child: tareas.isEmpty
                      ? Center(
                          child: Text(
                            'Arrastra aquí',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 11,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(6),
                          itemCount: tareas.length,
                          itemBuilder: (context, i) =>
                              _KanbanCard(kt: tareas[i], color: color),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGET — TARJETA KANBAN DRAGGABLE
// ══════════════════════════════════════════════════════════════════════════════
class _KanbanCard extends StatelessWidget {
  final KanbanTarea kt;
  final Color color;

  const _KanbanCard({required this.kt, required this.color});

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<KanbanTarea>(
      data: kt,
      delay: const Duration(milliseconds: 200),
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: 2),
          ),
          child: Text(
            kt.tarea.titulo,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _buildCard()),
      child: _buildCard(),
    );
  }

  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kt.tarea.titulo,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.colorPrioridad(kt.tarea.prioridad),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  kt.tarea.materia,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGETS HELPER
// ══════════════════════════════════════════════════════════════════════════════
class _ResultadoItem extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;
  final IconData icono;

  const _ResultadoItem({
    required this.label,
    required this.valor,
    required this.color,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icono, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;

  const _MiniStat(this.label, this.valor, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
