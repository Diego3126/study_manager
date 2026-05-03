import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../models/tarea_model.dart';
import '../../services/tarea_service.dart';
import '../../widgets/estado_widget.dart';
import '../../widgets/tarea_card.dart';

class TareasView extends StatefulWidget {
  const TareasView({super.key});

  @override
  State<TareasView> createState() => _TareasViewState();
}

class _TareasViewState extends State<TareasView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _cargando = true;
  String? _error;
  List<Tarea> _todas = [];
  List<Tarea> _pendientes = [];
  List<Tarea> _completadas = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final todas = await TareaService().getAll();
      if (!mounted) return;
      setState(() {
        _todas      = todas;
        _pendientes = todas.where((t) => !t.completada).toList();
        _completadas = todas.where((t) => t.completada).toList();
        _cargando   = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _cargando = false; });
    }
  }

  Widget _buildLista(List<Tarea> tareas) {
    if (tareas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No hay tareas aquí',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        itemCount: tareas.length,
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemBuilder: (context, i) => TareaCard(
          tarea: tareas[i],
          onTap: () async {
            await context.push('/tareas/${tareas[i].id}');
            _cargar();
          },
          onCompletada: (val) async {
            await TareaService()
                .marcarCompletada(tareas[i].id!, val ?? false);
            _cargar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tareas'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Todas (${_todas.length})'),
            Tab(text: 'Pendientes (${_pendientes.length})'),
            Tab(text: 'Completadas (${_completadas.length})'),
          ],
        ),
      ),
      body: EstadoWidget(
        cargando: false,
        error: _error,
        onReintentar: _cargar,
        hijo: Skeletonizer(
          enabled: _cargando,
          child: _cargando
              ? ListView.builder(
                  itemCount: 5,
                  itemBuilder: (_, __) => Container(
                    height: 80,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLista(_todas),
                    _buildLista(_pendientes),
                    _buildLista(_completadas),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/tareas/nueva');
          _cargar();
        },
        icon:  const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
    );
  }
}