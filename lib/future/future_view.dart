import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/base_view.dart';

class FutureView extends StatefulWidget {
  const FutureView({super.key});

  @override
  State<FutureView> createState() => _FutureViewState();
}

class _FutureViewState extends State<FutureView> {
  List<String> _nombres = [];
  String _estado = 'inicial'; // 'inicial', 'cargando', 'exito', 'error'

  @override
  void initState() {
    super.initState();
    debugPrint('>>> [FutureView] initState — antes de cargar datos');
    obtenerDatos();
  }

  Future<List<String>> cargarNombres() async {
    debugPrint('>>> [FutureView] cargarNombres — inicio (esperando 3s)');
    await Future.delayed(const Duration(seconds: 3));
    debugPrint('>>> [FutureView] cargarNombres — datos listos');
    return [
      'Juan', 'Pedro', 'Luis', 'Ana', 'Maria',
      'Jose', 'Carlos', 'Sofia', 'Laura', 'Fernando',
      'Ricardo', 'Diana', 'Elena', 'Miguel', 'Rosa',
      'Luz', 'Carmen', 'Pablo', 'Jorge', 'Roberto',
    ];
  }

  Future<void> obtenerDatos() async {
    setState(() => _estado = 'cargando');
    debugPrint('>>> [FutureView] obtenerDatos — estado: cargando');

    try {
      final datos = await cargarNombres();
      if (!mounted) return;
      setState(() {
        _nombres = datos;
        _estado = 'exito';
      });
      debugPrint('>>> [FutureView] obtenerDatos — estado: éxito');
    } catch (e) {
      if (!mounted) return;
      setState(() => _estado = 'error');
      debugPrint('>>> [FutureView] obtenerDatos — estado: error → $e');
    }
  }

  Widget _buildEstado() {
    switch (_estado) {
      case 'cargando':
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando...', style: TextStyle(fontSize: 16)),
            ],
          ),
        );
      case 'error':
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              const Text('Error al cargar los datos',
                  style: TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: obtenerDatos,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
      case 'exito':
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.green.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('Éxito — ${_nombres.length} registros cargados',
                      style: const TextStyle(color: Colors.green)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: GridView.builder(
                  itemCount: _nombres.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2,
                  ),
                  itemBuilder: (context, index) {
                    return Card(
                      color: const Color.fromARGB(255, 87, 194, 180),
                      child: Center(
                        child: Text(
                          _nombres[index],
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseView(
      title: 'Futures - async/await',
      body: _buildEstado(),
    );
  }
}