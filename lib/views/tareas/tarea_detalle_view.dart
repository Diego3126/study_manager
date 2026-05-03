import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/tarea_model.dart';
import '../../services/tarea_service.dart';
import '../../themes/app_theme.dart';
import '../../widgets/estado_widget.dart';

class TareaDetalleView extends StatefulWidget {
  final int id;
  const TareaDetalleView({super.key, required this.id});

  @override
  State<TareaDetalleView> createState() => _TareaDetalleViewState();
}

class _TareaDetalleViewState extends State<TareaDetalleView> {
  bool _cargando = true;
  String? _error;
  Tarea? _tarea;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final t = await TareaService().getById(widget.id);
      if (!mounted) return;
      setState(() { _tarea = t; _cargando = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _cargando = false; });
    }
  }

  Future<void> _eliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text('¿Eliminar "${_tarea?.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await TareaService().eliminar(widget.id);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle'),
        actions: _tarea == null ? null : [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await context.push('/tareas/${widget.id}/editar');
              _cargar();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _eliminar,
          ),
        ],
      ),
      body: EstadoWidget(
        cargando: _cargando,
        error: _error,
        onReintentar: _cargar,
        hijo: _tarea == null ? const SizedBox() : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con tipo y prioridad
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.colorTipo(_tarea!.tipo)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_tarea!.tipo,
                        style: TextStyle(
                          color: AppTheme.colorTipo(_tarea!.tipo),
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.colorPrioridad(_tarea!.prioridad)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Prioridad ${_tarea!.prioridad}',
                        style: TextStyle(
                          color: AppTheme.colorPrioridad(_tarea!.prioridad),
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(_tarea!.titulo,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _campo(Icons.book_outlined,     'Materia',        _tarea!.materia),
              _campo(Icons.calendar_today,    'Fecha de entrega',
                '${_tarea!.fechaEntrega.day}/${_tarea!.fechaEntrega.month}/${_tarea!.fechaEntrega.year}'),
              _campo(Icons.description_outlined, 'Descripción', _tarea!.descripcion),
              const SizedBox(height: 16),
              // Botón marcar completada
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await TareaService().marcarCompletada(
                        _tarea!.id!, !_tarea!.completada);
                    _cargar();
                  },
                  icon: Icon(_tarea!.completada
                      ? Icons.undo : Icons.check_circle_outline),
                  label: Text(_tarea!.completada
                      ? 'Marcar como pendiente'
                      : 'Marcar como completada'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tarea!.completada
                        ? Colors.grey : AppTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo(IconData icono, String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
                Text(valor,
                    style: const TextStyle(fontSize: 15)),
                const Divider(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}