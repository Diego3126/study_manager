import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/tarea_model.dart';
import '../../services/tarea_service.dart';
import '../../themes/app_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MODELO KANBAN
// ══════════════════════════════════════════════════════════════════════════════
enum KanbanEstado { porHacer, enProgreso, finalizado }

class KanbanTarea {
  final Tarea tarea;
  KanbanEstado estado;
  KanbanTarea({required this.tarea, this.estado = KanbanEstado.porHacer});
}

// ══════════════════════════════════════════════════════════════════════════════
// PALETA DE COLUMNAS
// ══════════════════════════════════════════════════════════════════════════════
class _ColPalette {
  final Color header;
  final Color headerText;
  final Color badge;
  final Color badgeText;
  final Color body;
  final Color border;
  final Color dropBorder;
  final Color dropText;
  const _ColPalette({
    required this.header,
    required this.headerText,
    required this.badge,
    required this.badgeText,
    required this.body,
    required this.border,
    required this.dropBorder,
    required this.dropText,
  });
}

// ── Paletas modo CLARO ────────────────────────────────────────────────────────
const _palettePorHacerLight = _ColPalette(
  header: Color(0xFFF1F3F9),
  headerText: Color(0xFF374151),
  badge: Color(0xFF374151),
  badgeText: Colors.white,
  body: Color(0xFFF8F9FC),
  border: Color(0xFFE5E7EB),
  dropBorder: Color(0xFFD1D5DB),
  dropText: Color(0xFF9CA3AF),
);
const _paletteProgresoLight = _ColPalette(
  header: Color(0xFFFFF3E0),
  headerText: Color(0xFFB45309),
  badge: Color(0xFFF59E0B),
  badgeText: Colors.white,
  body: Color(0xFFFFFBF5),
  border: Color(0xFFFDE68A),
  dropBorder: Color(0xFFFCD34D),
  dropText: Color(0xFFD97706),
);
const _paletteFinalizadoLight = _ColPalette(
  header: Color(0xFFECFDF5),
  headerText: Color(0xFF065F46),
  badge: Color(0xFF10B981),
  badgeText: Colors.white,
  body: Color(0xFFF6FDFB),
  border: Color(0xFFA7F3D0),
  dropBorder: Color(0xFF6EE7B7),
  dropText: Color(0xFF059669),
);

// ── Paletas modo OSCURO ────────────────────────────────────────────────────────
const _palettePorHacerDark = _ColPalette(
  header: Color(0xFF232638),
  headerText: Color(0xFFB0B8CC),
  badge: Color(0xFF3A3F5C),
  badgeText: Color(0xFFB0B8CC),
  body: Color(0xFF1A1D2E),
  border: Color(0xFF2A2D45),
  dropBorder: Color(0xFF3A3F5C),
  dropText: Color(0xFF6B7280),
);
const _paletteProgresoDark = _ColPalette(
  header: Color(0xFF2D2410),
  headerText: Color(0xFFFBBF24),
  badge: Color(0xFFF59E0B),
  badgeText: Color(0xFF1A1500),
  body: Color(0xFF1E1A0F),
  border: Color(0xFF3D2E00),
  dropBorder: Color(0xFFFCD34D),
  dropText: Color(0xFFD97706),
);
const _paletteFinalizadoDark = _ColPalette(
  header: Color(0xFF0D2B1F),
  headerText: Color(0xFF34D399),
  badge: Color(0xFF10B981),
  badgeText: Color(0xFF001A10),
  body: Color(0xFF0A1E16),
  border: Color(0xFF1A4030),
  dropBorder: Color(0xFF6EE7B7),
  dropText: Color(0xFF059669),
);

// ── Selector de paleta según modo ─────────────────────────────────────────────
_ColPalette _paletteForEstado(KanbanEstado estado, bool isDark) {
  switch (estado) {
    case KanbanEstado.porHacer:
      return isDark ? _palettePorHacerDark : _palettePorHacerLight;
    case KanbanEstado.enProgreso:
      return isDark ? _paletteProgresoDark : _paletteProgresoLight;
    case KanbanEstado.finalizado:
      return isDark ? _paletteFinalizadoDark : _paletteFinalizadoLight;
  }
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;

  List<KanbanTarea> _kanbanTareas = [];
  bool _cargandoTareas = true;
  bool _sesionIniciada = false;

  Map<String, Color> _coloresMateria = {};

  static const Map<String, int> _modos = {
    'Enfoque': 25 * 60,
    'Descanso corto': 5 * 60,
    'Descanso largo': 15 * 60,
  };
  String _modoActual = 'Enfoque';
  int _segundos = 25 * 60;
  bool _corriendo = false;
  Timer? _timer;
  DateTime? _tiempoInicio;

  int _pomodoroCiclo = 0;
  bool _esperandoDescanso = false;
  bool _esperandoEnfoque = false;
  bool _esDescansoLargo = false;

  bool _modoClasico = true;

  int _sesionesEnfoque = 0;
  int _sesionesDescansoCorto = 0;
  int _sesionesDescansoLargo = 0;

  int _sesionesEnfoqueLibre = 0;
  int _sesionesDescansoCortoLibre = 0;
  int _sesionesDescansoLargoLibre = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _cargarColoresMateria().then((_) => _cargarTareas());
    _cargarSesiones();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _corriendo &&
        _tiempoInicio != null) {
      final ahora = DateTime.now();
      final transcurrido = ahora.difference(_tiempoInicio!).inSeconds;
      final segundosOriginales = _modos[_modoActual]!;
      _timer?.cancel();
      final nuevosSegundos = segundosOriginales - transcurrido;
      if (nuevosSegundos <= 0) {
        setState(() {
          _segundos = 0;
          _corriendo = false;
        });
        if (_modoActual == 'Enfoque') {
          if (_modoClasico) {
            setState(() {
              _sesionesEnfoque++;
              _pomodoroCiclo++;
              _esDescansoLargo = _pomodoroCiclo >= 4;
              if (_pomodoroCiclo >= 4) _pomodoroCiclo = 0;
              _esperandoDescanso = true;
            });
            _mostrarResultados();
          } else {
            setState(() {
              _sesionesEnfoqueLibre++;
              _segundos = _modos[_modoActual]!;
              _corriendo = false;
              _tiempoInicio = null;
            });
            _mostrarSnack('¡Sesión de enfoque terminada! 🍅');
          }
        } else {
          setState(() {
            if (_modoClasico) {
              if (_modoActual == 'Descanso corto')
                _sesionesDescansoCorto++;
              else
                _sesionesDescansoLargo++;
              _esperandoEnfoque = true;
              _esperandoDescanso = false;
            } else {
              if (_modoActual == 'Descanso corto')
                _sesionesDescansoCortoLibre++;
              else
                _sesionesDescansoLargoLibre++;
            }
            _segundos = _modos[_modoActual]!;
            _corriendo = false;
            _tiempoInicio = null;
          });
          _timer?.cancel();
          if (_modoClasico) _guardarContadorDescanso(_modoActual);
          _mostrarSnack(
            _modoActual == 'Descanso corto'
                ? '¡Descanso corto terminado! A enfocarse 💪'
                : '¡Descanso largo terminado! ¡Nuevo ciclo! 💪',
          );
        }
      } else {
        setState(() => _segundos = nuevosSegundos);
        _iniciarTimer();
      }
    }
  }

  Future<void> _cargarColoresMateria() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final snap = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('materias')
          .get();
      final mapa = <String, Color>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final nombre = data['nombre'] as String? ?? doc.id;
        final colorVal = data['color'];
        if (colorVal != null) {
          if (colorVal is int) {
            mapa[nombre] = Color(colorVal);
          } else if (colorVal is String) {
            final hex = colorVal.replaceFirst('#', '');
            final parsed = int.tryParse(
              hex.length == 6 ? 'FF$hex' : hex,
              radix: 16,
            );
            if (parsed != null) mapa[nombre] = Color(parsed);
          }
        }
      }
      if (mounted) setState(() => _coloresMateria = mapa);
    } catch (_) {}
  }

  Color _colorDeMateria(String materia) =>
      _coloresMateria[materia] ?? const Color(0xFF94A3B8);

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

  Future<void> _cargarSesiones() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final snap = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('sesiones_pomodoro')
          .get();
      if (!mounted) return;
      int enfoque = 0, corto = 0, largo = 0;
      int enfoqueL = 0, cortoL = 0, largoL = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final tipo = data['tipo'] as String? ?? 'Enfoque';
        final esLibre = data['modoLibre'] as bool? ?? false;
        if (esLibre) {
          if (tipo == 'Enfoque')
            enfoqueL++;
          else if (tipo == 'Descanso corto')
            cortoL++;
          else if (tipo == 'Descanso largo')
            largoL++;
        } else {
          if (tipo == 'Enfoque')
            enfoque++;
          else if (tipo == 'Descanso corto')
            corto++;
          else if (tipo == 'Descanso largo')
            largo++;
        }
      }
      setState(() {
        _sesionesEnfoque = enfoque;
        _sesionesDescansoCorto = corto;
        _sesionesDescansoLargo = largo;
        _sesionesEnfoqueLibre = enfoqueL;
        _sesionesDescansoCortoLibre = cortoL;
        _sesionesDescansoLargoLibre = largoL;
      });
    } catch (_) {}
  }

  void _moverTarea(KanbanTarea kt, KanbanEstado nuevoEstado) async {
    final estadoAnterior = kt.estado;
    setState(() => kt.estado = nuevoEstado);
    if (nuevoEstado == KanbanEstado.finalizado) {
      try {
        await TareaService().marcarCompletada(kt.tarea.firestoreId!, true);
      } catch (_) {}
    }
    if (estadoAnterior == KanbanEstado.finalizado &&
        nuevoEstado != KanbanEstado.finalizado) {
      try {
        await TareaService().marcarCompletada(kt.tarea.firestoreId!, false);
      } catch (_) {}
    }
  }

  List<KanbanTarea> get _porHacer =>
      _kanbanTareas.where((k) => k.estado == KanbanEstado.porHacer).toList();
  List<KanbanTarea> get _enProgreso =>
      _kanbanTareas.where((k) => k.estado == KanbanEstado.enProgreso).toList();
  List<KanbanTarea> get _finalizado =>
      _kanbanTareas.where((k) => k.estado == KanbanEstado.finalizado).toList();

  void _iniciarTimer() {
    _tiempoInicio = DateTime.now().subtract(
      Duration(seconds: _modos[_modoActual]! - _segundos),
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_segundos == 0) {
        _timer?.cancel();
        setState(() => _corriendo = false);
        _tiempoInicio = null;
        if (_modoActual == 'Enfoque') {
          if (_modoClasico) {
            setState(() {
              _sesionesEnfoque++;
              _pomodoroCiclo++;
              _esDescansoLargo = _pomodoroCiclo >= 4;
              if (_pomodoroCiclo >= 4) _pomodoroCiclo = 0;
              _esperandoDescanso = true;
            });
            _mostrarResultados();
          } else {
            setState(() {
              _sesionesEnfoqueLibre++;
              _segundos = _modos[_modoActual]!;
              _corriendo = false;
              _tiempoInicio = null;
            });
            _mostrarSnack('¡Sesión de enfoque terminada! 🍅');
          }
        } else {
          setState(() {
            if (_modoClasico) {
              if (_modoActual == 'Descanso corto')
                _sesionesDescansoCorto++;
              else
                _sesionesDescansoLargo++;
              _esperandoDescanso = false;
              _esperandoEnfoque = true;
            } else {
              if (_modoActual == 'Descanso corto')
                _sesionesDescansoCortoLibre++;
              else
                _sesionesDescansoLargoLibre++;
            }
            _segundos = _modos[_modoActual]!;
            _corriendo = false;
            _tiempoInicio = null;
          });
          _timer?.cancel();
          if (_modoClasico) _guardarContadorDescanso(_modoActual);
          _mostrarSnack(
            _modoActual == 'Descanso corto'
                ? '¡Descanso corto terminado! A enfocarse 💪'
                : '¡Descanso largo terminado! ¡Nuevo ciclo! 💪',
          );
        }
      } else {
        setState(() => _segundos--);
      }
    });
  }

  Future<void> _guardarContadorDescanso(String tipo) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('sesiones_pomodoro')
          .add({
            'fecha': DateTime.now().toIso8601String(),
            'tipo': tipo,
            'modoLibre': false,
            'finalizadas': 0,
            'enProgreso': 0,
            'productividad': 0,
          });
      await _cargarSesiones();
    } catch (_) {}
  }

  void _iniciar() {
    if (!_sesionIniciada) setState(() => _sesionIniciada = true);
    _tiempoInicio = DateTime.now().subtract(
      Duration(seconds: _modos[_modoActual]! - _segundos),
    );
    _iniciarTimer();
    setState(() => _corriendo = true);
  }

  void _pausar() {
    _timer?.cancel();
    _tiempoInicio = null;
    setState(() => _corriendo = false);
  }

  void _reiniciar() {
    _timer?.cancel();
    _tiempoInicio = null;
    setState(() {
      _segundos = _modos[_modoActual]!;
      _corriendo = false;
    });
  }

  void _cambiarModo(String modo) {
    _timer?.cancel();
    _tiempoInicio = null;
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

  void _mostrarResultados() {
    final enProg = _enProgreso.length;
    final fin = _finalizado.length;
    final total = enProg + fin;
    final pct = total == 0 ? 0 : (fin / total * 100).round();

    _timer?.cancel();
    setState(() => _corriendo = false);

    late String mensaje;
    late Color colorMensaje;
    late String emoji;

    if (pct >= 80) {
      mensaje =
          '¡Excelente! Completaste todas las tareas que te propusiste. ¡Sigue así!';
      colorMensaje = Colors.green;
      emoji = '🏆';
    } else if (pct >= 50) {
      mensaje =
          '¡Buen trabajo! Completaste la mitad o más de la mitad, Ya casi estamos!';
      colorMensaje = Colors.orange;
      emoji = '💪';
    } else if (fin > 0) {
      mensaje =
          '¡Ya completaste una o más tareas! Sigue así que vas muy bien!';
      colorMensaje = Colors.orange;
      emoji = '📝';
    } else {
      mensaje =
          '¡No te desanimes! Todavía tienes un camino que recorrer.';
      colorMensaje = Colors.red;
      emoji = '💡';
    }

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        // ✅ Leemos el tema dentro del builder para que el modal lo herede
        final colorScheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            // ✅ surface del tema en lugar de Colors.white fijo
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  // ✅ onSurface con opacidad en lugar de Color(0xFFE5E7EB) fijo
                  color: colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text(
                'Avances de la sesión',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  // ✅ onSurface del tema en lugar de Color(0xFF111827) fijo
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  // ✅ onSurface con opacidad en lugar de Color(0xFFF8F9FC) fijo
                  color: colorScheme.onSurface.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.onSurface.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ResultadoItem(
                      label: 'En progreso',
                      valor: '$enProg',
                      color: Colors.orange,
                      icono: Icons.pending_actions,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      // ✅ divider del tema
                      color: colorScheme.onSurface.withOpacity(0.1),
                    ),
                    _ResultadoItem(
                      label: 'Finalizado',
                      valor: '$fin',
                      color: Colors.green,
                      icono: Icons.check_circle,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: colorScheme.onSurface.withOpacity(0.1),
                    ),
                    _ResultadoItem(
                      label: 'Productividad',
                      valor: '$pct%',
                      color: colorMensaje,
                      icono: Icons.bar_chart,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 10,
                  // ✅ onSurface con opacidad en lugar de Colors.grey.shade200
                  backgroundColor: colorScheme.onSurface.withOpacity(0.1),
                  color: colorMensaje,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorMensaje.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorMensaje.withOpacity(0.25)),
                ),
                child: Text(
                  mensaje,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorMensaje,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: OutlinedButton.styleFrom(
                    // ✅ primaryOf(context) en lugar de AppTheme.primary fijo
                    foregroundColor: AppTheme.primaryOf(context),
                    side: BorderSide(
                      color: AppTheme.primaryOf(context),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  child: const Text('Continuar sesión'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    Future.microtask(() async {
                      await _guardarSesion(fin, enProg, pct);
                      if (mounted) {
                        setState(() {
                          _pomodoroCiclo = 0;
                          _esDescansoLargo = false;
                          _esperandoDescanso = false;
                          _esperandoEnfoque = false;
                          _sesionIniciada = false;
                          _segundos = _modos['Enfoque']!;
                          _modoActual = 'Enfoque';
                          _corriendo = false;
                          _tiempoInicio = null;
                          for (final kt in _kanbanTareas) {
                            kt.estado = KanbanEstado.porHacer;
                          }
                        });
                        _timer?.cancel();
                        _cargarTareas();
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOf(context),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  child: const Text('Finalizar sesión'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
            'tipo': _modoActual,
            'modoLibre': !_modoClasico,
            'finalizadas': finalizadas,
            'enProgreso': enProgreso,
            'productividad': productividad,
          });
      await _cargarSesiones();
    } catch (_) {}
  }

  void _resetKanban() {
    setState(() {
      for (final kt in _kanbanTareas) {
        kt.estado = KanbanEstado.porHacer;
      }
      _sesionIniciada = false;
      _segundos = _modos[_modoActual]!;
      _corriendo = false;
      _tiempoInicio = null;
      _esperandoDescanso = false;
      _esperandoEnfoque = false;
    });
    _timer?.cancel();
    _cargarTareas();
  }

  void _mostrarInfoModos() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final colorScheme = Theme.of(context).colorScheme;
        final primaryColor = AppTheme.primaryOf(context);
        return Container(
          decoration: BoxDecoration(
            // ✅ surface del tema en lugar de Colors.white fijo
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    // ✅ onSurface con opacidad
                    color: colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                '¿Cómo funcionan los modos?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  // ✅ onSurface del tema en lugar de Color(0xFF111827) fijo
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              _InfoModoCard(
                icono: Icons.military_tech_rounded,
                color: primaryColor,
                titulo: 'Modo Clásico',
                descripcion:
                    'Sigue el ciclo Pomodoro original. Trabaja 25 min, '
                    'descansa 5 min y cada 4 sesiones toma un descanso largo de 15 min. '
                    'El sistema te guía en cada paso y no puedes saltar etapas.',
                items: const [
                  '🍅  25 min de enfoque',
                  '☕  5 min de descanso corto',
                  '🌙  15 min de descanso largo cada 4 pomodoros',
                ],
              ),
              const SizedBox(height: 16),
              _InfoModoCard(
                icono: Icons.tune_rounded,
                color: AppTheme.accent,
                titulo: 'Modo Libre',
                descripcion:
                    'Tú decides cuándo y cómo descansar. Puedes cambiar '
                    'entre contadores libremente cuando el timer esté detenido. '
                    'Ideal si prefieres un ritmo más flexible.',
                items: const [
                  '🍅  Enfoque cuando quieras',
                  '☕  Descanso corto a tu ritmo',
                  '🌙  Descanso largo cuando lo necesites',
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String get _tiempoFormateado {
    final min = _segundos ~/ 60;
    final segs = _segundos % 60;
    return '${min.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
  }

  double get _progreso => 1 - (_segundos / _modos[_modoActual]!);

  // ✅ _colorModo usa primaryOf(context) — llamado solo dentro de build
  Color _colorModo(BuildContext context) {
    switch (_modoActual) {
      case 'Enfoque':
        return AppTheme.primaryOf(context);
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
      // ✅ Sin backgroundColor hardcodeado — usa scaffoldBackgroundColor del tema
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildKanban(context), _buildPomodoro(context)],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(BuildContext context) {
    final colorTop = _colorModo(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        // ✅ colorTop ya usa primaryOf(context) en modo Enfoque
        color: _tabController.index == 1
            ? colorTop
            : AppTheme.primaryOf(context),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(_tabController.index == 1 ? 0 : 28),
          bottomRight: Radius.circular(_tabController.index == 1 ? 0 : 28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Modo Enfoque',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Organiza tu sesión de estudio',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (_tabController.index == 1)
                    Row(
                      children: [
                        Text(
                          'Clásico',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _modoClasico
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            final bloqueado = _modoClasico
                                ? (_corriendo || _sesionIniciada)
                                : _corriendo;
                            if (!bloqueado) {
                              _timer?.cancel();
                              setState(() {
                                _modoClasico = !_modoClasico;
                                _modoActual = 'Enfoque'; // ✅ volver a enfoque
                                _segundos =
                                    _modos['Enfoque']!; // ✅ resetear contador
                                _corriendo = false;
                                _tiempoInicio = null;
                                _esperandoDescanso =
                                    false; // ✅ limpiar estado clásico
                                _esperandoEnfoque = false;
                                _pomodoroCiclo = 0;
                                _sesionIniciada = false;
                              });
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 40,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              alignment: _modoClasico
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              child: Container(
                                width: 16,
                                height: 16,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Libre',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: !_modoClasico
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              indicatorColor: Colors.white,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.view_kanban_outlined, size: 18),
                  text: 'Kanban',
                ),
                Tab(
                  icon: Icon(Icons.timer_outlined, size: 18),
                  text: 'Pomodoro',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1 — KANBAN
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildKanban(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppTheme.primaryOf(context);

    if (_cargandoTareas) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_kanbanTareas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                // ✅ primaryOf(context) con opacidad en lugar de Color(0xFFEEF4FF) fijo
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 48,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes tareas pendientes',
              style: TextStyle(
                // ✅ onSurface con opacidad en lugar de Color(0xFF6B7280) fijo
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _cargarTareas,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Recargar'),
              style: OutlinedButton.styleFrom(
                // ✅ primaryOf(context) en lugar de Color(0xFF2C6FED) fijo
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (!_sesionIniciada)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              // ✅ primaryOf(context) con opacidad en lugar de Color(0xFFEEF4FF) fijo
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  // ✅ primaryOf(context) en lugar de Color(0xFF2C6FED) fijo
                  color: primaryColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mueve tareas a "En progreso" e inicia el Pomodoro.',
                    style: TextStyle(
                      fontSize: 12,
                      // ✅ primaryOf(context) con ligera variación en lugar de Color(0xFF1E50C8)
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KanbanColumna(
                  titulo: 'Por hacer',
                  icono: Icons.radio_button_unchecked_rounded,
                  palette: _paletteForEstado(KanbanEstado.porHacer, isDark),
                  tareas: _porHacer,
                  estado: KanbanEstado.porHacer,
                  colorDeMateria: _colorDeMateria,
                  onAcepto: (kt) => _moverTarea(kt, KanbanEstado.porHacer),
                ),
                _KanbanColumna(
                  titulo: 'En progreso',
                  icono: Icons.play_circle_outline_rounded,
                  palette: _paletteForEstado(KanbanEstado.enProgreso, isDark),
                  tareas: _enProgreso,
                  estado: KanbanEstado.enProgreso,
                  colorDeMateria: _colorDeMateria,
                  onAcepto: (kt) => _moverTarea(kt, KanbanEstado.enProgreso),
                ),
                _KanbanColumna(
                  titulo: 'Listo',
                  icono: Icons.check_circle_outline_rounded,
                  palette: _paletteForEstado(KanbanEstado.finalizado, isDark),
                  tareas: _finalizado,
                  estado: KanbanEstado.finalizado,
                  colorDeMateria: _colorDeMateria,
                  onAcepto: (kt) => _moverTarea(kt, KanbanEstado.finalizado),
                ),
              ],
            ),
          ),
        ),
        if (_enProgreso.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(1),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                'Iniciar Pomodoro con ${_enProgreso.length} tarea(s)',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2 — POMODORO
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPomodoro(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = AppTheme.primaryOf(context);
    final colorTop = _colorModo(context);

    final selectorBloqueado = _modoClasico
        ? (_pomodoroCiclo > 0 ||
              _esperandoDescanso ||
              _esperandoEnfoque ||
              _corriendo ||
              _sesionIniciada)
        : _corriendo;

    final selectorOpacity = _modoClasico
        ? (selectorBloqueado ? 0.0 : 1.0)
        : (_corriendo ? 0.5 : 1.0);

    return Column(
      children: [
        Container(
          color: colorTop,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            children: [
              // ── Selector de modo ──────────────────────────────────────
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: selectorOpacity,
                child: IgnorePointer(
                  ignoring: selectorBloqueado,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: _modos.keys.map((modo) {
                        final seleccionado = _modoActual == modo;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (!_corriendo) _cambiarModo(modo);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: seleccionado
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: Text(
                                modo,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: seleccionado
                                      ? colorTop
                                      : Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Círculo timer ─────────────────────────────────────────
              Center(
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // ✅ surface del tema en lugar de Colors.white fijo
                          color: colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 30,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: _progreso,
                          strokeWidth: 10,
                          color: colorTop,
                          backgroundColor: colorTop.withOpacity(0.12),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _tiempoFormateado,
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w800,
                              // ✅ onSurface del tema en lugar de Color(0xFF1A1D2E) fijo
                              color: colorScheme.onSurface,
                              letterSpacing: -2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _modoClasico
                                ? '$_sesionesEnfoque 🍅  $_sesionesDescansoCorto ☕  $_sesionesDescansoLargo 🌙'
                                : '$_sesionesEnfoqueLibre 🍅  $_sesionesDescansoCortoLibre ☕  $_sesionesDescansoLargoLibre 🌙',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              // ✅ onSurface con opacidad en lugar de Color(0xFF6B7280) fijo
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        right: 0,
                        bottom: 8,
                        child: GestureDetector(
                          onTap: _mostrarInfoModos,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              // ✅ surface del tema
                              color: colorScheme.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: colorTop,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),

        // ── Mitad inferior ────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              children: [
                // ── Botones según estado ──────────────────────────────────
                if (_modoClasico && _esperandoDescanso) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.25),
                      ),
                    ),
                    child: Text(
                      _esDescansoLargo
                          ? '¡Completaste 4 pomodoros! Toma un descanso largo 🌙'
                          : '¡Buen trabajo! Toma un descanso corto ☕',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FocusifyBtn(
                    label: _esDescansoLargo
                        ? 'Ir a descanso largo'
                        : 'Ir a descanso corto',
                    icon: _esDescansoLargo
                        ? Icons.nightlight_round
                        : Icons.coffee_rounded,
                    color: Colors.orange,
                    filled: true,
                    onTap: () {
                      setState(() {
                        _esperandoDescanso = false;
                        _cambiarModo(
                          _esDescansoLargo
                              ? 'Descanso largo'
                              : 'Descanso corto',
                        );
                      });
                    },
                  ),
                ] else if (_modoClasico && _esperandoEnfoque) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      // ✅ primaryOf(context) en lugar de AppTheme.primary fijo
                      color: primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.25)),
                    ),
                    child: Text(
                      '¡Descansaste bien! Vuelve al modo enfoque 🍅',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FocusifyBtn(
                    label: 'Volver a enfocarse',
                    icon: Icons.play_arrow_rounded,
                    color: primaryColor,
                    filled: true,
                    onTap: () {
                      setState(() {
                        _esperandoEnfoque = false;
                        _cambiarModo('Enfoque');
                      });
                    },
                  ),
                ] else ...[
                  if (!_corriendo && _segundos == _modos[_modoActual]!)
                    _FocusifyBtn(
                      label: 'Iniciar',
                      icon: Icons.play_arrow_rounded,
                      color: colorTop,
                      filled: true,
                      onTap: _iniciar,
                    ),
                  if (_corriendo)
                    _FocusifyBtn(
                      label: 'Pausar',
                      icon: Icons.pause_rounded,
                      color: colorTop,
                      filled: false,
                      onTap: _pausar,
                    ),
                  if (!_corriendo && _segundos != _modos[_modoActual]!)
                    Row(
                      children: [
                        Expanded(
                          child: _FocusifyBtn(
                            label: 'Detener',
                            icon: Icons.stop_rounded,
                            color: colorTop,
                            filled: false,
                            onTap: _reiniciar,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FocusifyBtn(
                            label: 'Continuar',
                            icon: Icons.play_arrow_rounded,
                            color: colorTop,
                            filled: true,
                            onTap: _iniciar,
                          ),
                        ),
                      ],
                    ),
                ],

                const SizedBox(height: 24),

                // ── Resumen sesión actual ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    // ✅ onSurface con opacidad en lugar de Color(0xFFF8F9FC) fijo
                    color: colorScheme.onSurface.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.onSurface.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sesión actual',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          // ✅ onSurface del tema en lugar de Color(0xFF374151) fijo
                          color: colorScheme.onSurface.withOpacity(0.8),
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
                            'Finalizadas',
                            '${_finalizado.length}',
                            Colors.green,
                          ),
                          _MiniStat(
                            'Por hacer',
                            '${_porHacer.length}',
                            colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (_enProgreso.isNotEmpty || _finalizado.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: _mostrarResultados,
                    icon: const Icon(Icons.insights_rounded),
                    label: const Text('Ver avances'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorTop,
                      side: BorderSide(color: colorTop),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGET — COLUMNA KANBAN
// ══════════════════════════════════════════════════════════════════════════════
class _KanbanColumna extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final _ColPalette palette;
  final List<KanbanTarea> tareas;
  final KanbanEstado estado;
  final Color Function(String) colorDeMateria;
  final ValueChanged<KanbanTarea> onAcepto;

  const _KanbanColumna({
    required this.titulo,
    required this.icono,
    required this.palette,
    required this.tareas,
    required this.estado,
    required this.colorDeMateria,
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
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: isHover ? palette.header.withOpacity(0.5) : palette.body,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isHover ? palette.dropBorder : palette.border,
                width: isHover ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 9,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: palette.header,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(13),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icono, color: palette.headerText, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          titulo,
                          style: TextStyle(
                            color: palette.headerText,
                            fontWeight: FontWeight.w700,
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
                          color: palette.badge,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${tareas.length}',
                          style: TextStyle(
                            color: palette.badgeText,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: tareas.isEmpty
                      ? _DropZone(palette: palette, isHover: isHover)
                      : ListView.builder(
                          padding: const EdgeInsets.all(6),
                          itemCount: tareas.length,
                          itemBuilder: (context, i) => _KanbanCard(
                            kt: tareas[i],
                            materiaColor: colorDeMateria(
                              tareas[i].tarea.materia,
                            ),
                          ),
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
// WIDGET — DROP ZONE VACÍA
// ══════════════════════════════════════════════════════════════════════════════
class _DropZone extends StatelessWidget {
  final _ColPalette palette;
  final bool isHover;
  const _DropZone({required this.palette, required this.isHover});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: DottedBorder(
        borderColor: isHover
            ? palette.dropBorder
            : palette.dropBorder.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.drag_indicator_rounded,
                color: palette.dropText.withOpacity(0.5),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                'Arrastra aquí',
                style: TextStyle(
                  color: palette.dropText,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGET — TARJETA KANBAN DRAGGABLE
// ══════════════════════════════════════════════════════════════════════════════
class _KanbanCard extends StatelessWidget {
  final KanbanTarea kt;
  final Color materiaColor;
  const _KanbanCard({required this.kt, required this.materiaColor});

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
            // ✅ surface del tema en lugar de Colors.white fijo
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: materiaColor, width: 2),
          ),
          child: Text(
            kt.tarea.titulo,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _buildCard(context)),
      child: _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        // ✅ surface del tema en lugar de Colors.white fijo
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: materiaColor.withOpacity(0.4)),
        boxShadow: isDark
            ? null
            : [
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
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              // ✅ onSurface del tema
              color: colorScheme.onSurface,
            ),
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
                  style: TextStyle(
                    fontSize: 9,
                    // ✅ onSurface con opacidad en lugar de Colors.grey.shade600 fijo
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
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
// WIDGET — BOTÓN POMODORO
// ══════════════════════════════════════════════════════════════════════════════
class _FocusifyBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _FocusifyBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: filled
          ? ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DOTTED BORDER
// ══════════════════════════════════════════════════════════════════════════════
class DottedBorder extends StatelessWidget {
  final Color borderColor;
  final BorderRadius borderRadius;
  final Widget child;

  const DottedBorder({
    super.key,
    required this.borderColor,
    required this.borderRadius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedBorderPainter(
        color: borderColor,
        radius: borderRadius.topLeft.x,
      ),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  _DottedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 4.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double dist = 0;
      while (dist < metric.length) {
        final end = (dist + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(dist, end), paint);
        dist += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DottedBorderPainter old) =>
      old.color != color || old.radius != radius;
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
    final colorScheme = Theme.of(context).colorScheme;
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
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            // ✅ onSurface con opacidad en lugar de Colors.grey fijo
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

class _InfoModoCard extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String titulo;
  final String descripcion;
  final List<String> items;

  const _InfoModoCard({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.descripcion,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            descripcion,
            style: TextStyle(
              fontSize: 12,
              // ✅ onSurface con opacidad en lugar de Color(0xFF6B7280) fijo
              color: colorScheme.onSurface.withOpacity(0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  // ✅ onSurface del tema en lugar de Color(0xFF374151) fijo
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ),
          ),
        ],
      ),
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
    final colorScheme = Theme.of(context).colorScheme;
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
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            // ✅ onSurface con opacidad en lugar de Colors.grey fijo
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}
