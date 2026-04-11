import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/custom_drawer.dart';

class PasoParametrosScreen extends StatefulWidget {
  const PasoParametrosScreen({super.key});

  @override
  State<PasoParametrosScreen> createState() => PasoParametrosScreenState();
}

class PasoParametrosScreenState extends State<PasoParametrosScreen> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void goToDetalle(String metodo) {
    String valor = controller.text;
    if (valor.isEmpty) return;

    switch (metodo) {
      case 'go':
        context.go('/detalle/$valor/$metodo');
        break;
      case 'push':
        context.push('/detalle/$valor/$metodo');
        break;
      case 'replace':
        context.replace('/detalle/$valor/$metodo');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paso de Parámetros')),
      drawer: const CustomDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Ingrese un valor',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => goToDetalle('go'),
              child: const Text('Ir con Go'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => goToDetalle('push'),
              child: const Text('Ir con Push'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => goToDetalle('replace'),
              child: const Text('Ir con Replace'),
            ),
          ],
        ),
      ),
    );
  }
}