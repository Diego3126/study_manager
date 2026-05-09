import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_config.dart';
import '../../models/tarea_model.dart';
import '../../services/tarea_service.dart';
import '../../themes/app_theme.dart';

class TareaFormView extends StatefulWidget {
  final String? id;
  const TareaFormView({super.key, this.id});

  @override
  State<TareaFormView> createState() => _TareaFormViewState();
}

class _TareaFormViewState extends State<TareaFormView> {
  final _formKey    = GlobalKey<FormState>();
  final _titulo     = TextEditingController();
  final _descripcion = TextEditingController();

  String   _materia   = AppConfig.materias.first;
  String   _tipo      = AppConfig.tiposTarea.first;
  String   _prioridad = AppConfig.prioridades[1];
  DateTime _fecha     = DateTime.now().add(const Duration(days: 1));
  bool     _guardando = false;
  bool     _cargando  = false;

  bool get _esEdicion => widget.id != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final t = await TareaService().getById(widget.id!);
      if (!mounted) return;
      setState(() {
        _titulo.text      = t.titulo;
        _descripcion.text = t.descripcion;
        _materia          = t.materia;
        _tipo             = t.tipo;
        _prioridad        = t.prioridad;
        _fecha            = t.fechaEntrega;
        _cargando         = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context:       context,
      initialDate:   _fecha,
      firstDate:     DateTime.now().subtract(const Duration(days: 1)),
      lastDate:      DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final tarea = Tarea(
        firestoreId:  widget.id,
        titulo:       _titulo.text.trim(),
        descripcion:  _descripcion.text.trim(),
        materia:      _materia,
        tipo:         _tipo,
        prioridad:    _prioridad,
        fechaEntrega: _fecha,
      );
      if (_esEdicion) {
        await TareaService().editar(tarea);
      } else {
        await TareaService().crear(tarea);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_esEdicion
            ? 'Tarea actualizada' : 'Tarea creada'),
        backgroundColor: Colors.green,
      ));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar tarea' : 'Nueva tarea'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titulo,
                      decoration: const InputDecoration(
                        labelText: 'Título *',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descripcion,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _materia,
                      decoration: const InputDecoration(
                        labelText: 'Materia *',
                        prefixIcon: Icon(Icons.book),
                      ),
                      items: AppConfig.materias.map((m) =>
                          DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (v) => setState(() => _materia = v!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _tipo,
                      decoration: const InputDecoration(
                        labelText: 'Tipo *',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: AppConfig.tiposTarea.map((t) =>
                          DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _tipo = v!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _prioridad,
                      decoration: const InputDecoration(
                        labelText: 'Prioridad *',
                        prefixIcon: Icon(Icons.flag),
                      ),
                      items: AppConfig.prioridades.map((p) =>
                          DropdownMenuItem(
                            value: p,
                            child: Row(
                              children: [
                                Icon(Icons.circle,
                                    size: 12,
                                    color: AppTheme.colorPrioridad(p)),
                                const SizedBox(width: 8),
                                Text(p),
                              ],
                            ),
                          )).toList(),
                      onChanged: (v) => setState(() => _prioridad = v!),
                    ),
                    const SizedBox(height: 12),
                    // Selector de fecha
                    InkWell(
                      onTap: _seleccionarFecha,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha de entrega *',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          '${_fecha.day}/${_fecha.month}/${_fecha.year}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _guardando ? null : _guardar,
                      icon: _guardando
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save),
                      label: Text(_guardando ? 'Guardando...'
                          : (_esEdicion ? 'Actualizar' : 'Crear tarea')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}