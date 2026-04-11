import 'package:flutter/material.dart';
import '../widgets/custom_drawer.dart';

class CicloVidaScreen extends StatefulWidget {
  const CicloVidaScreen({super.key});

  @override
  State<CicloVidaScreen> createState() => _CicloVidaScreenState();
}

class _CicloVidaScreenState extends State<CicloVidaScreen> {
  int contador = 0;
  String ultimoEvento = 'Ninguno';

  @override
  void initState() {
    super.initState();
    setState(() => ultimoEvento = 'initState()');
    debugPrint('initState ejecutado');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('didChangeDependencies ejecutado');
  }

  @override
  void dispose() {
    debugPrint('dispose ejecutado');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('build ejecutado');
    return Scaffold(
      appBar: AppBar(title: const Text('Ciclo de Vida')),
      drawer: const CustomDrawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Último evento: $ultimoEvento',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Text('Contador: $contador',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  contador++;
                  ultimoEvento = 'setState()';
                });
              },
              child: const Text('Incrementar (setState)'),
            ),
          ],
        ),
      ),
    );
  }
}