import 'dart:async';
import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

class EnfoqueView extends StatefulWidget {
  const EnfoqueView({super.key});

  @override
  State<EnfoqueView> createState() => _EnfoqueViewState();
}

class _EnfoqueViewState extends State<EnfoqueView> {
  // Modos Pomodoro
  static const Map<String, int> _modos = {
    'Enfoque':       25 * 60,
    'Descanso corto': 5 * 60,
    'Descanso largo': 15 * 60,
  };

  String  _modoActual  = 'Enfoque';
  int     _segundos    = 25 * 60;
  bool    _corriendo   = false;
  int     _sesiones    = 0;
  Timer?  _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _iniciar() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_segundos == 0) {
        _timer?.cancel();
        setState(() => _corriendo = false);
        if (_modoActual == 'Enfoque') {
          setState(() => _sesiones++);
        }
        _mostrarNotificacion();
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
      _segundos  = _modos[_modoActual]!;
      _corriendo = false;
    });
  }

  void _cambiarModo(String modo) {
    _timer?.cancel();
    setState(() {
      _modoActual = modo;
      _segundos   = _modos[modo]!;
      _corriendo  = false;
    });
  }

  void _mostrarNotificacion() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_modoActual == 'Enfoque'
          ? '¡Sesión completada! Toma un descanso 🎉'
          : '¡Descanso terminado! A enfocarse 💪'),
      backgroundColor: AppTheme.accent,
      duration: const Duration(seconds: 3),
    ));
  }

  String get _tiempoFormateado {
    final min  = _segundos ~/ 60;
    final segs = _segundos % 60;
    return '${min.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
  }

  double get _progreso {
    final total = _modos[_modoActual]!;
    return 1 - (_segundos / total);
  }

  Color get _colorModo {
    switch (_modoActual) {
      case 'Enfoque':        return AppTheme.primary;
      case 'Descanso corto': return AppTheme.accent;
      default:               return AppTheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modo Enfoque')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Selector de modo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: _modos.keys.map((modo) => Expanded(
                    child: GestureDetector(
                      onTap: () => _cambiarModo(modo),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _modoActual == modo
                              ? _colorModo : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          modo,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _modoActual == modo
                                ? Colors.white : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Círculo de progreso
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value:           _progreso,
                    strokeWidth:     12,
                    color:           _colorModo,
                    backgroundColor: _colorModo.withOpacity(0.1),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      _tiempoFormateado,
                      style: TextStyle(
                        fontSize:   56,
                        fontWeight: FontWeight.bold,
                        color:      _colorModo,
                      ),
                    ),
                    Text(
                      _corriendo ? '▶ En progreso' : '⏸ Pausado',
                      style: TextStyle(color: _colorModo, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Botones
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_corriendo)
                  ElevatedButton.icon(
                    onPressed: _iniciar,
                    icon:  const Icon(Icons.play_arrow),
                    label: Text(_segundos == _modos[_modoActual]!
                        ? 'Iniciar' : 'Reanudar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _colorModo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _pausar,
                    icon:  const Icon(Icons.pause),
                    label: const Text('Pausar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                    ),
                  ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _reiniciar,
                  icon:  const Icon(Icons.restart_alt),
                  label: const Text('Reiniciar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Sesiones completadas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: Colors.orange, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      '$_sesiones sesión${_sesiones != 1 ? 'es' : ''} completada${_sesiones != 1 ? 's' : ''}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}