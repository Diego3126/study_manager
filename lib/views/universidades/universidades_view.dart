import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/universidad_model.dart';
import '../../services/universidad_service.dart';
import '../../themes/app_theme.dart';

class UniversidadesView extends StatelessWidget {
  const UniversidadesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Universidades')),
      floatingActionButton: null, // ← quita el FAB
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: ElevatedButton.icon(
            onPressed: () => context.push('/universidades/nueva'),
            icon: const Icon(Icons.add),
            label: const Text('Agregar universidad'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 2,
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Universidad>>(
        stream: UniversidadService().getStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final unis = snapshot.data ?? [];
          if (unis.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No hay universidades registradas',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Toca el botón + para agregar una',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: unis.length,
            itemBuilder: (context, i) => _UniversidadCard(universidad: unis[i]),
          );
        },
      ),
    );
  }
}

class _UniversidadCard extends StatelessWidget {
  final Universidad universidad;
  const _UniversidadCard({required this.universidad});

  Future<void> _abrirUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _eliminar(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar universidad'),
        content: Text('¿Eliminar "${universidad.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await UniversidadService().eliminar(universidad.id!);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppTheme.primary,
                  child: Icon(
                    Icons.account_balance,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        universidad.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'NIT: ${universidad.nit}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _eliminar(context),
                ),
              ],
            ),
            const Divider(height: 20),
            _Fila(Icons.location_on_outlined, universidad.direccion),
            const SizedBox(height: 6),
            _Fila(Icons.phone_outlined, universidad.telefono),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => _abrirUrl(universidad.paginaWeb),
              child: _Fila(
                Icons.language,
                universidad.paginaWeb,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color? color;
  const _Fila(this.icono, this.texto, {this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 16, color: color ?? Colors.grey),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            texto,
            style: TextStyle(fontSize: 13, color: color ?? Colors.black87),
          ),
        ),
      ],
    );
  }
}
