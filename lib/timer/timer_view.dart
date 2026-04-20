import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/base_view.dart';

class TimerView extends StatefulWidget {
  const TimerView({super.key});

  @override
  State<TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends State<TimerView> {
  Timer? _timer;
  int _segundos = 0;
  bool _corriendo = false;

  // Inicia o reanuda el cronómetro
  void _iniciar() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _segundos++);
    });
    setState(() => _corriendo = true);
  }

  // Pausa cancelando el timer activo
  void _pausar() {
    _timer?.cancel();
    setState(() => _corriendo = false);
  }

  // Reinicia todo a cero
  void _reiniciar() {
    _timer?.cancel();
    setState(() {
      _segundos = 0;
      _corriendo = false;
    });
  }

  // Formatea segundos → MM:SS
  String get _tiempoFormateado {
    final minutos = _segundos ~/ 60;
    final segs = _segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel(); // Limpieza de recursos al salir
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseView(
      title: 'Cronómetro — Timer',
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _tiempoFormateado,
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                fontFeatures: [],
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _corriendo ? '▶ Corriendo' : '⏸ Pausado',
              style: TextStyle(
                fontSize: 16,
                color: _corriendo ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botón Iniciar / Pausar / Reanudar
                if (!_corriendo)
                  ElevatedButton.icon(
                    onPressed: _iniciar,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(_segundos == 0 ? 'Iniciar' : 'Reanudar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
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
                          horizontal: 24, vertical: 14),
                    ),
                  ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _reiniciar,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reiniciar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}