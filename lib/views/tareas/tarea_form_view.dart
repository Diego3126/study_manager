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
import '../../services/notificacion_service.dart';

class TareaFormView extends StatefulWidget {
  final String? id;
  const TareaFormView({super.key, this.id});

  @override
  State<TareaFormView> createState() => _TareaFormViewState();
}

class _TareaFormViewState extends State<TareaFormView> {
  final _formKey     = GlobalKey<FormState>();
  final _titulo      = TextEditingController();
  final _descripcion = TextEditingController();

  String    _materia    = AppConfig.materias.first;
  String    _otraMateria = '';
  String    _tipo       = AppConfig.tiposTarea.first;
  String    _prioridad  = AppConfig.prioridades[1];
  DateTime  _fecha      = DateTime.now().add(const Duration(days: 1));
  TimeOfDay? _hora;
  bool _guardando = false;
  bool _cargando  = false;

  final List<_Adjunto> _adjuntos           = [];
  final List<String>   _archivosExistentes = [];

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
        _materia          = AppConfig.materias.contains(t.materia) ? t.materia : 'Otra';
        _otraMateria      = AppConfig.materias.contains(t.materia) ? '' : t.materia;
        _tipo             = t.tipo;
        _prioridad        = t.prioridad;
        _fecha            = t.fechaEntrega;
        _hora             = t.horaEntrega;
        _archivosExistentes.addAll(t.archivos);
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  Future<void> _seleccionarMateria() async {
    await _mostrarSheet<String>(
      titulo:      'Selecciona una materia',
      opciones:    AppConfig.materias,
      seleccionado: _materia,
      etiqueta:    (m) => m,
      leading:     (_) => Icon(Icons.book_outlined,
          color: AppTheme.primaryOf(context)),
      onSeleccion: (v) => setState(() => _materia = v),
    );

    await Future.delayed(const Duration(milliseconds: 500));

    if (_materia == 'Otra' && mounted) {
      await _mostrarDialogoOtraMateria();
    }
  }

  Future<void> _mostrarDialogoOtraMateria() async {
    final controller = TextEditingController(text: _otraMateria);
    // ✅ Capturar tema antes del builder
    final primary    = AppTheme.primaryOf(context);
    final onSurface  = Theme.of(context).colorScheme.onSurface;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '¿Cuál es la materia?',
          style: TextStyle(
            fontSize:   17,
            fontWeight: FontWeight.bold,
            color:      onSurface,
          ),
        ),
        content: TextField(
          controller:          controller,
          autofocus:           false,
          textCapitalization:  TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText:    'Ej: Cálculo diferencial',
            prefixIcon:  const Icon(Icons.book_outlined),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _materia = AppConfig.materias.first);
              Navigator.of(context).pop();
            },
            child: Text(
              'Cancelar',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface
                      .withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final texto = controller.text.trim();
              if (texto.isNotEmpty) {
                setState(() => _otraMateria = texto);
              }
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _agregarAdjunto() async {
    // ✅ Capturar tema antes del builder
    final dividerColor = Theme.of(context).dividerColor;

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
              width: 40, height: 4,
              decoration: BoxDecoration(
                color:        dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title:   const Text('Elegir imagen de galería'),
              onTap:   () => Navigator.pop(context, 'galeria'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title:   const Text('Tomar foto'),
              onTap:   () => Navigator.pop(context, 'camara'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file_outlined),
              title:   const Text('Elegir archivo (PDF)'),
              onTap:   () => Navigator.pop(context, 'archivo'),
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
        source:       source,
        imageQuality: 85,
        maxWidth:     800,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        if (!mounted) return;
        _mostrarError('La imagen supera el límite de 5 MB');
        return;
      }
      setState(() => _adjuntos.add(_Adjunto(
        nombre: picked.name,
        bytes:  bytes,
        tipo:   _TipoAdjunto.imagen,
      )));
    } else {
      final result = await FilePicker.platform.pickFiles(
        type:              FileType.custom,
        allowedExtensions: ['pdf'],
        withData:          true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.size > 5 * 1024 * 1024) {
        if (!mounted) return;
        _mostrarError('El archivo supera el límite de 5 MB');
        return;
      }
      setState(() => _adjuntos.add(_Adjunto(
        nombre: file.name,
        bytes:  file.bytes!,
        tipo:   _TipoAdjunto.pdf,
      )));
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _mostrarSheet<T>({
    required String titulo,
    required List<T> opciones,
    required T seleccionado,
    required String Function(T) etiqueta,
    required Widget Function(T)? leading,
    required void Function(T) onSeleccion,
  }) async {
    // ✅ Capturar tema antes del builder
    final primary      = AppTheme.primaryOf(context);
    final onSurface    = Theme.of(context).colorScheme.onSurface;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final dividerColor = Theme.of(context).dividerColor;

    await showModalBottomSheet(
      context:         context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor:    Colors.black.withOpacity(0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Container(
        decoration: BoxDecoration(
          color:        surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color:        dividerColor,
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
                    style: TextStyle(
                      fontSize:   17,
                      fontWeight: FontWeight.bold,
                      color:      onSurface,
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
                    color: estaSeleccionado ? primary : onSurface,
                  ),
                ),
                trailing: estaSeleccionado
                    ? Icon(Icons.check_rounded, color: primary)
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

  Future<bool> _mostrarConfirmacion() async {
    // ✅ Capturar tema antes del builder
    final primary      = AppTheme.primaryOf(context);
    final onSurface    = Theme.of(context).colorScheme.onSurface;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final dividerColor = Theme.of(context).dividerColor;

    return await showModalBottomSheet<bool>(
          context:         context,
          backgroundColor: Colors.transparent,
          barrierColor:    Colors.black.withOpacity(0.5),
          builder: (_) => Container(
            decoration: BoxDecoration(
              color:        surfaceColor,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color:  primary.withOpacity(0.12),
                    shape:  BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.assignment_outlined,
                    color: primary,
                    size:  32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _esEdicion ? 'Actualizar tarea' : 'Crear nueva tarea',
                  style: TextStyle(
                    fontSize:   18,
                    fontWeight: FontWeight.bold,
                    color:      onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _esEdicion
                      ? 'Revisa los cambios antes de guardar. ¿Deseas continuar?'
                      : 'Revisa los datos de tu tarea antes de crearla. ¿Deseas continuar?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color:    onSurface.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                        _esEdicion ? 'Sí, actualizar' : 'Sí, crear ahora'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: onSurface,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      side: BorderSide(color: dividerColor),
                    ),
                    child: const Text('No, revisar'),
                  ),
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  Future<void> _mostrarExito() async {
    // ✅ Capturar tema antes del builder
    final primary      = AppTheme.primaryOf(context);
    final onSurface    = Theme.of(context).colorScheme.onSurface;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    await showModalBottomSheet(
      context:         context,
      backgroundColor: Colors.transparent,
      barrierColor:    Colors.black.withOpacity(0.5),
      isDismissible:   false,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color:        surfaceColor,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color:  AppTheme.accent.withOpacity(0.15),
                shape:  BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppTheme.accent,
                size:  36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _esEdicion ? '¡Tarea actualizada!' : '¡Tarea creada!',
              style: TextStyle(
                fontSize:   18,
                fontWeight: FontWeight.bold,
                color:      onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _esEdicion
                  ? 'Los cambios se guardaron correctamente.'
                  : '¡Felicidades! Tu tarea fue registrada exitosamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color:    onSurface.withOpacity(0.55),
              ),
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
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Ver mis tareas'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
  if (!_formKey.currentState!.validate()) return;

  final confirmar = await _mostrarConfirmacion();
  if (!confirmar) return;

  setState(() => _guardando = true);
  try {
    final List<String> urlsAdjuntos = [];
    urlsAdjuntos.addAll(_archivosExistentes);

    for (final adj in _adjuntos) {
      final String url;
      if (adj.tipo == _TipoAdjunto.pdf) {
        url = await AuthService().subirArchivoPdf(adj.bytes, adj.nombre);
      } else {
        url = await AuthService().subirImagenTarea(adj.bytes);
      }
      urlsAdjuntos.add(url);
    }

    final tarea = Tarea(
      firestoreId:  widget.id,
      titulo:       _titulo.text.trim(),
      descripcion:  _descripcion.text.trim(),
      materia:      _materia == 'Otra' && _otraMateria.isNotEmpty
          ? _otraMateria
          : _materia,
      tipo:         _tipo,
      prioridad:    _prioridad,
      fechaEntrega: _fecha,
      horaEntrega:  _hora,
      archivos:     urlsAdjuntos,
    );

    if (_esEdicion) {
      await TareaService().editar(tarea);
      // En edición el id ya existe en tarea.firestoreId
      await NotificationService().programarParaTarea(tarea); // ✅
    } else {
      final nuevoId = await TareaService().crear(tarea); // ✅ capturamos el ID
      final tareaConId = tarea.copyWith(firestoreId: nuevoId); // ✅ lo inyectamos
      await NotificationService().programarParaTarea(tareaConId); // ✅
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

  Widget _campoSelector({
    required String    label,
    required String    valor,
    required IconData  icono,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242840) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Icon(icono,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    valor,
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary  = AppTheme.primaryOf(context);
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // ── Header ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: const BorderRadius.only(
                        bottomLeft:  Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    padding: EdgeInsets.only(
                      top:    MediaQuery.of(context).padding.top + 8,
                      bottom: 20,
                      left:   8,
                      right:  20,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        Expanded(
                          child: Text(
                            _esEdicion ? 'Editar tarea' : 'Nueva tarea',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color:      Colors.white,
                              fontSize:   18,
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
                                color: onSurface.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 90,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  // ── Botón agregar ──────────────
                                  GestureDetector(
                                    onTap: (_adjuntos.length +
                                                _archivosExistentes.length) <
                                            3
                                        ? _agregarAdjunto
                                        : null,
                                    child: Container(
                                      width:  80,
                                      height: 80,
                                      margin: const EdgeInsets.only(right: 10),
                                      decoration: BoxDecoration(
                                        color: primary.withOpacity(0.08),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: primary.withOpacity(0.3),
                                          style: BorderStyle.solid,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.add_rounded,
                                        color: (_adjuntos.length +
                                                    _archivosExistentes
                                                        .length) <
                                                3
                                            ? primary
                                            : onSurface.withOpacity(0.3),
                                        size: 32,
                                      ),
                                    ),
                                  ),

                                  // ── Archivos existentes (edición) ──
                                  ..._archivosExistentes.asMap().entries.map(
                                    (e) {
                                      final i   = e.key;
                                      final url = e.value;
                                      final esImagen =
                                          url.toLowerCase().contains(
                                                  '/image/upload/') ||
                                              url.toLowerCase().endsWith(
                                                  '.jpg') ||
                                              url.toLowerCase().endsWith(
                                                  '.jpeg') ||
                                              url.toLowerCase().endsWith(
                                                  '.png');
                                      return Stack(
                                        children: [
                                          Container(
                                            width:  80,
                                            height: 80,
                                            margin: const EdgeInsets.only(
                                                right: 10),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF242840)
                                                  : Colors.grey.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: esImagen
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    child: Image.network(url,
                                                        fit: BoxFit.cover),
                                                  )
                                                : Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: const [
                                                      Icon(
                                                        Icons
                                                            .picture_as_pdf_rounded,
                                                        color: Colors.red,
                                                        size: 28,
                                                      ),
                                                      SizedBox(height: 4),
                                                      Text('PDF',
                                                          style: TextStyle(
                                                              fontSize: 9),
                                                          textAlign:
                                                              TextAlign.center),
                                                    ],
                                                  ),
                                          ),
                                          Positioned(
                                            top:   0,
                                            right: 8,
                                            child: GestureDetector(
                                              onTap: () => setState(() =>
                                                  _archivosExistentes
                                                      .removeAt(i)),
                                              child: Container(
                                                width:  20,
                                                height: 20,
                                                decoration:
                                                    const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.close,
                                                    size:  12,
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),

                                  // ── Archivos nuevos ────────────
                                  ..._adjuntos.asMap().entries.map((e) {
                                    final i   = e.key;
                                    final adj = e.value;
                                    return Stack(
                                      children: [
                                        Container(
                                          width:  80,
                                          height: 80,
                                          margin: const EdgeInsets.only(
                                              right: 10),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF242840)
                                                : Colors.grey.shade200,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: adj.tipo ==
                                                  _TipoAdjunto.imagen
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Image.memory(adj.bytes,
                                                      fit: BoxFit.cover),
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
                                                          fontSize: 9),
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
                                          top:   0,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () => setState(
                                                () => _adjuntos.removeAt(i)),
                                            child: Container(
                                              width:  20,
                                              height: 20,
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.close,
                                                  size:  12,
                                                  color: Colors.white),
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
                                labelText:  'Título *',
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
                                labelText:  'Descripción',
                                prefixIcon: Icon(Icons.description),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),

                            // Materia
                            _campoSelector(
                              label: 'Materia *',
                              valor: _materia == 'Otra' &&
                                      _otraMateria.isNotEmpty
                                  ? _otraMateria
                                  : _materia,
                              icono: Icons.book_outlined,
                              onTap: _seleccionarMateria,
                            ),
                            const SizedBox(height: 12),

                            // Tipo
                            _campoSelector(
                              label: 'Tipo *',
                              valor: _tipo,
                              icono: Icons.category_outlined,
                              onTap: () => _mostrarSheet<String>(
                                titulo:       'Selecciona el tipo',
                                opciones:     AppConfig.tiposTarea,
                                seleccionado: _tipo,
                                etiqueta:     (t) => t,
                                leading: (_) => Icon(
                                    Icons.category_outlined,
                                    color: AppTheme.primaryOf(context)),
                                onSeleccion: (v) =>
                                    setState(() => _tipo = v),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Prioridad
                            _campoSelector(
                              label: 'Prioridad *',
                              valor: _prioridad,
                              icono: Icons.flag_outlined,
                              onTap: () => _mostrarSheet<String>(
                                titulo:       'Selecciona la prioridad',
                                opciones:     AppConfig.prioridades,
                                seleccionado: _prioridad,
                                etiqueta:     (p) => p,
                                leading: (p) => Icon(
                                  Icons.circle,
                                  size:  14,
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
                                  context:     context,
                                  initialDate: _fecha,
                                  firstDate: DateTime.now()
                                      .subtract(const Duration(days: 1)),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setState(() => _fecha = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF242840)
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Theme.of(context).dividerColor),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today_outlined,
                                        color: onSurface.withOpacity(0.6),
                                        size: 20),
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
                                              color: onSurface.withOpacity(0.5),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_fecha.day}/${_fecha.month}/${_fecha.year}',
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.keyboard_arrow_down_rounded,
                                        color: onSurface.withOpacity(0.5)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Hora
                            GestureDetector(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context:     context,
                                  initialTime: _hora ?? TimeOfDay.now(),
                                  builder: (context, child) {
                                    return MediaQuery(
                                      data: MediaQuery.of(context).copyWith(
                                          alwaysUse24HourFormat: true),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setState(() => _hora = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF242840)
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Theme.of(context).dividerColor),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time_rounded,
                                        color: onSurface.withOpacity(0.6),
                                        size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Hora de vencimiento',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: onSurface.withOpacity(0.5),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _hora != null
                                                ? '${_hora!.hour.toString().padLeft(2, '0')}:${_hora!.minute.toString().padLeft(2, '0')}'
                                                : 'Sin hora definida',
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: _hora != null
                                                  ? onSurface
                                                  : onSurface.withOpacity(0.35),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        if (_hora != null)
                                          GestureDetector(
                                            onTap: () =>
                                                setState(() => _hora = null),
                                            child: Icon(Icons.close_rounded,
                                                color: onSurface
                                                    .withOpacity(0.4),
                                                size: 18),
                                          ),
                                        const SizedBox(width: 4),
                                        Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: onSurface.withOpacity(0.5)),
                                      ],
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
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
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
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                minimumSize:
                                    const Size(double.infinity, 52),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(30)),
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
        style: TextStyle(
          fontSize:   13,
          fontWeight: FontWeight.bold,
          color:      AppTheme.primaryOf(context),
        ),
      ),
    );
  }
}

// ── Modelo interno para adjuntos ──────────────────────────────────────────────
enum _TipoAdjunto { imagen, pdf }

class _Adjunto {
  final String      nombre;
  final Uint8List   bytes;
  final _TipoAdjunto tipo;
  _Adjunto({required this.nombre, required this.bytes, required this.tipo});
}