import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/app_config.dart';
import '../../models/tarea_model.dart';
import '../../services/tarea_service.dart';
import '../../services/auth_service.dart';
import '../../themes/app_theme.dart';

class TareaFormView extends StatefulWidget {
  final String? id;
  const TareaFormView({super.key, this.id});

  @override
  State<TareaFormView> createState() => _TareaFormViewState();
}

class _TareaFormViewState extends State<TareaFormView> {
  final _formKey = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _descripcion = TextEditingController();

  String _materia = AppConfig.materias.first;
  String _tipo = AppConfig.tiposTarea.first;
  String _prioridad = AppConfig.prioridades[1];
  DateTime _fecha = DateTime.now().add(const Duration(days: 1));
  bool _guardando = false;
  bool _cargando = false;

  // Archivos adjuntos
  final List<_Adjunto> _adjuntos = [];

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
        _titulo.text = t.titulo;
        _descripcion.text = t.descripcion;
        _materia = t.materia;
        _tipo = t.tipo;
        _prioridad = t.prioridad;
        _fecha = t.fechaEntrega;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  // ── Seleccionar archivo o imagen ─────────────────────────────────────────
  Future<void> _agregarAdjunto() async {
    final opcion = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir imagen de galería'),
              onTap: () => Navigator.pop(context, 'galeria'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, 'camara'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file_outlined),
              title: const Text('Elegir archivo (PDF)'),
              onTap: () => Navigator.pop(context, 'archivo'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (opcion == null) return;

    if (opcion == 'galeria' || opcion == 'camara') {
      final source = opcion == 'camara'
          ? ImageSource.camera
          : ImageSource.gallery;
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        if (!mounted) return;
        _mostrarError('La imagen supera el límite de 5 MB');
        return;
      }
      setState(
        () => _adjuntos.add(
          _Adjunto(
            nombre: picked.name,
            bytes: bytes,
            tipo: _TipoAdjunto.imagen,
          ),
        ),
      );
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if ((file.size) > 5 * 1024 * 1024) {
        if (!mounted) return;
        _mostrarError('El archivo supera el límite de 5 MB');
        return;
      }
      setState(
        () => _adjuntos.add(
          _Adjunto(
            nombre: file.name,
            bytes: file.bytes!,
            tipo: _TipoAdjunto.pdf,
          ),
        ),
      );
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // ── Sheet genérico para seleccionar opción ───────────────────────────────
  Future<void> _mostrarSheet<T>({
    required String titulo,
    required List<T> opciones,
    required T seleccionado,
    required String Function(T) etiqueta,
    required Widget Function(T)? leading,
    required void Function(T) onSeleccion,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Divider(),
            ...opciones.map((op) {
              final estaSeleccionado = op == seleccionado;
              return ListTile(
                leading: leading != null ? leading(op) : null,
                title: Text(
                  etiqueta(op),
                  style: TextStyle(
                    fontWeight: estaSeleccionado
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: estaSeleccionado
                        ? AppTheme.primary
                        : const Color(0xFF1A1A2E),
                  ),
                ),
                trailing: estaSeleccionado
                    ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                    : null,
                onTap: () {
                  onSeleccion(op);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Diálogos de confirmación y éxito ────────────────────────────────────
  Future<bool> _mostrarConfirmacion() async {
    return await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black.withOpacity(0.5),
          builder: (_) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: AppTheme.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _esEdicion ? 'Actualizar tarea' : 'Crear nueva tarea',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _esEdicion
                      ? 'Revisa los cambios antes de guardar. ¿Deseas continuar?'
                      : 'Revisa los datos de tu tarea antes de crearla. ¿Deseas continuar?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      _esEdicion ? 'Sí, actualizar' : 'Sí, crear ahora',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      'No, revisar',
                      style: TextStyle(color: Color(0xFF1A1A2E)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  Future<void> _mostrarExito() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      isDismissible: false,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppTheme.accent,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _esEdicion ? '¡Tarea actualizada!' : '¡Tarea creada!',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _esEdicion
                  ? 'Los cambios se guardaron correctamente.'
                  : '¡Felicidades! Tu tarea fue registrada exitosamente.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Ver mis tareas'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Guardar ──────────────────────────────────────────────────────────────
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmar = await _mostrarConfirmacion();
    if (!confirmar) return;

    setState(() => _guardando = true);
    try {
      final List<String> urlsAdjuntos = [];
      // Subir adjuntos a Cloudinary
      for (final adj in _adjuntos) {
        final String url;
        if (adj.tipo == _TipoAdjunto.pdf) {
          url = await AuthService().subirArchivoPdf(adj.bytes, adj.nombre);
        } else {
          url = await AuthService().subirFotoPerfil(adj.bytes);
        }
        urlsAdjuntos.add(url);
      }

      final tarea = Tarea(
        firestoreId: widget.id,
        titulo: _titulo.text.trim(),
        descripcion: _descripcion.text.trim(),
        materia: _materia,
        tipo: _tipo,
        prioridad: _prioridad,
        fechaEntrega: _fecha,
        archivos: urlsAdjuntos,
      );

      if (_esEdicion) {
        await TareaService().editar(tarea);
      } else {
        await TareaService().crear(tarea);
      }

      if (!mounted) return;
      setState(() => _guardando = false);
      await _mostrarExito();
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _mostrarError('Error: $e');
    }
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  // ── Campo selector (reemplaza los DropdownButtonFormField) ───────────────
  Widget _campoSelector({
    required String label,
    required String valor,
    required IconData icono,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Row(
          children: [
            Icon(icono, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    valor,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // ── Header ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 8,
                      bottom: 20,
                      left: 8,
                      right: 20,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => context.pop(),
                        ),
                        Expanded(
                          child: Text(
                            _esEdicion ? 'Editar tarea' : 'Nueva tarea',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),

                // ── Formulario ───────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Adjuntos ──────────────────────────
                            _SeccionLabel('Archivos adjuntos'),
                            Text(
                              'Formato: imagen o PDF, máximo 5 MB',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 90,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  // Botón agregar
                                  GestureDetector(
                                    onTap: _adjuntos.length < 3
                                        ? _agregarAdjunto
                                        : null,
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      margin: const EdgeInsets.only(right: 10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withOpacity(
                                          0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.primary.withOpacity(
                                            0.3,
                                          ),
                                          style: BorderStyle.solid,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.add_rounded,
                                        color: _adjuntos.length < 3
                                            ? AppTheme.primary
                                            : Colors.grey,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                  // Adjuntos agregados
                                  ..._adjuntos.asMap().entries.map((e) {
                                    final i = e.key;
                                    final adj = e.value;
                                    return Stack(
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 80,
                                          margin: const EdgeInsets.only(
                                            right: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: adj.tipo == _TipoAdjunto.imagen
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Image.memory(
                                                    adj.bytes,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                              : Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      Icons
                                                          .picture_as_pdf_rounded,
                                                      color: Colors.red,
                                                      size: 28,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      adj.nombre,
                                                      style: const TextStyle(
                                                        fontSize: 9,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 2,
                                                    ),
                                                  ],
                                                ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () => setState(
                                              () => _adjuntos.removeAt(i),
                                            ),
                                            child: Container(
                                              width: 20,
                                              height: 20,
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                size: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),
                            _SeccionLabel('Información de la tarea'),
                            const SizedBox(height: 10),

                            // Título
                            TextFormField(
                              controller: _titulo,
                              decoration: const InputDecoration(
                                labelText: 'Título *',
                                prefixIcon: Icon(Icons.title),
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Campo requerido'
                                  : null,
                            ),
                            const SizedBox(height: 12),

                            // Descripción
                            TextFormField(
                              controller: _descripcion,
                              decoration: const InputDecoration(
                                labelText: 'Descripción',
                                prefixIcon: Icon(Icons.description),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),

                            // Materia
                            _campoSelector(
                              label: 'Materia *',
                              valor: _materia,
                              icono: Icons.book_outlined,
                              onTap: () => _mostrarSheet<String>(
                                titulo: 'Selecciona una materia',
                                opciones: AppConfig.materias,
                                seleccionado: _materia,
                                etiqueta: (m) => m,
                                leading: (_) => const Icon(
                                  Icons.book_outlined,
                                  color: AppTheme.primary,
                                ),
                                onSeleccion: (v) =>
                                    setState(() => _materia = v),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Tipo
                            _campoSelector(
                              label: 'Tipo *',
                              valor: _tipo,
                              icono: Icons.category_outlined,
                              onTap: () => _mostrarSheet<String>(
                                titulo: 'Selecciona el tipo',
                                opciones: AppConfig.tiposTarea,
                                seleccionado: _tipo,
                                etiqueta: (t) => t,
                                leading: (_) => const Icon(
                                  Icons.category_outlined,
                                  color: AppTheme.primary,
                                ),
                                onSeleccion: (v) => setState(() => _tipo = v),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Prioridad
                            _campoSelector(
                              label: 'Prioridad *',
                              valor: _prioridad,
                              icono: Icons.flag_outlined,
                              onTap: () => _mostrarSheet<String>(
                                titulo: 'Selecciona la prioridad',
                                opciones: AppConfig.prioridades,
                                seleccionado: _prioridad,
                                etiqueta: (p) => p,
                                leading: (p) => Icon(
                                  Icons.circle,
                                  size: 14,
                                  color: AppTheme.colorPrioridad(p),
                                ),
                                onSeleccion: (v) =>
                                    setState(() => _prioridad = v),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Fecha
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _fecha,
                                  firstDate: DateTime.now().subtract(
                                    const Duration(days: 1),
                                  ),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (picked != null) {
                                  setState(() => _fecha = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      color: Colors.grey.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Fecha de entrega *',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_fecha.day}/${_fecha.month}/${_fecha.year}',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Color(0xFF1A1A2E),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Colors.grey.shade500,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            // Botón guardar
                            ElevatedButton.icon(
                              onPressed: _guardando ? null : _guardar,
                              icon: _guardando
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(
                                _guardando
                                    ? 'Guardando...'
                                    : (_esEdicion
                                          ? 'Actualizar tarea'
                                          : 'Crear tarea'),
                              ),
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
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Sección label ─────────────────────────────────────────────────────────────
class _SeccionLabel extends StatelessWidget {
  final String texto;
  const _SeccionLabel(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}

// ── Modelo interno para adjuntos ──────────────────────────────────────────────
enum _TipoAdjunto { imagen, pdf }

class _Adjunto {
  final String nombre;
  final Uint8List bytes;
  final _TipoAdjunto tipo;
  _Adjunto({required this.nombre, required this.bytes, required this.tipo});
}
