import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/base_view.dart';

class IsolateView extends StatefulWidget {
  const IsolateView({super.key});

  @override
  State<IsolateView> createState() => _IsolateViewState();
}

class _IsolateViewState extends State<IsolateView> {
  String _resultado = 'Presiona el botón para ejecutar';
  bool _ejecutando = false;

  Future<void> isolateTask() async {
    setState(() {
      _ejecutando = true;
      _resultado = 'Ejecutando tarea en segundo plano...';
    });

    final receivePort = ReceivePort();

    await Isolate.spawn(_simulacionTareaPesada, receivePort.sendPort);

    final sendPort = await receivePort.first as SendPort;
    final response = ReceivePort();

    sendPort.send(['Hola desde el hilo principal', response.sendPort]);

    final result = await response.first as String;

    if (!mounted) return;
    setState(() {
      _resultado = result;
      _ejecutando = false;
    });
  }

  static void _simulacionTareaPesada(SendPort sendPort) async {
    final port = ReceivePort();
    sendPort.send(port.sendPort);

    await for (final message in port) {
      final data = message[0] as String;
      final puertoReceptor = message[1] as SendPort;

      int counter = 0;
      for (int i = 1; i <= 1000000; i++) {
        counter += i;
      }

      if (kDebugMode) print('Isolate: suma completada = $counter');

      puertoReceptor.send(
        'Tarea completada.\nSuma del 1 al 1,000,000: $counter\nMensaje recibido: "$data"',
      );
      port.close();
      Isolate.exit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseView(
      title: 'Isolate — Segundo Plano',
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.memory, size: 64, color: Colors.deepPurple),
              const SizedBox(height: 20),
              Text(
                _resultado,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              if (_ejecutando)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: isolateTask,
                  icon: const Icon(Icons.play_circle),
                  label: const Text('Ejecutar tarea en segundo plano'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}