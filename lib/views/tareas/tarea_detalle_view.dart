import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/tarea_model.dart';
import '../../services/tarea_service.dart';
import '../../themes/app_theme.dart';
import '../../widgets/estado_widget.dart';

class TareaDetalleView extends StatefulWidget {
  final String id;
  const TareaDetalleView({super.key, required this.id});

  @override
  State<TareaDetalleView> createState() => _TareaDetalleViewState();
}

class _TareaDetalleViewState extends State<TareaDetalleView> {
  bool _cargando = true;
  String? _error;
  Tarea? _tarea;
  int _imagenSeleccionada = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final t = await TareaService().getById(widget.id);
      if (!mounted) return;
      setState(() {
        _tarea = t;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  // ── Determina si una URL es imagen ────────────────────────────────────────
  bool _esImagen(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.png') ||
        lower.contains('.webp') ||
        lower.contains('.gif') ||
        lower.contains('/image/upload/');
  }

  // ── Viewer fullscreen al tocar imagen grande ──────────────────────────────
  void _abrirViewer(List<String> imagenes, int indiceInicial) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _ImagenFullscreenView(
          imagenes: imagenes,
          indiceInicial: indiceInicial,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  // ── Bottom sheet eliminar ─────────────────────────────────────────────────
  Future<void> _eliminar() async {
    final confirmar = await showModalBottomSheet<bool>(
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
                color: AppTheme.danger.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.danger,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Eliminar tarea',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¿Estás seguro de que deseas eliminar esta tarea? Esta acción no se puede deshacer.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Sí, eliminar'),
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
                  'Cancelar',
                  style: TextStyle(color: Color(0xFF1A1A2E)),
                ),
              ),
            ),
          ],
        ),
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
      backgroundColor: const Color(0xFFF4F6FA),
      body: EstadoWidget(
        cargando: _cargando,
        error: _error,
        onReintentar: _cargar,
        hijo: _tarea == null ? const SizedBox() : _buildDetalle(_tarea!),
      ),
    );
  }

  Widget _buildDetalle(Tarea tarea) {
    final imagenes = tarea.archivos.where(_esImagen).toList();
    final pdfs = tarea.archivos.where((u) => !_esImagen(u)).toList();
    final tieneImagenes = imagenes.isNotEmpty;

    return CustomScrollView(
      slivers: [
        // ── AppBar con imagen de exhibición ──────────────────────────────
        SliverAppBar(
          expandedHeight: tieneImagenes ? 300 : 0,
          pinned: true,
          backgroundColor: AppTheme.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Detalle',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              onPressed: () async {
                await context.push('/tareas/${widget.id}/editar');
                _cargar();
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.white,
              ),
              onPressed: _eliminar,
            ),
          ],
          flexibleSpace: tieneImagenes
              ? FlexibleSpaceBar(background: _buildImagenExhibicion(imagenes))
              : null,
        ),

        // ── Miniaturas de imágenes (zona roja) ───────────────────────────
        if (tieneImagenes)
          SliverToBoxAdapter(child: _buildMiniaturas(imagenes)),

        // ── Contenido principal ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chips
                Row(
                  children: [
                    _buildChip(tarea.tipo, AppTheme.colorTipo(tarea.tipo)),
                    const SizedBox(width: 8),
                    _buildChip(
                      'Prioridad ${tarea.prioridad}',
                      AppTheme.colorPrioridad(tarea.prioridad),
                    ),
                    const Spacer(),
                    _buildChip(
                      tarea.completada ? 'Completada' : 'Pendiente',
                      tarea.completada ? AppTheme.accent : Colors.grey,
                      icono: tarea.completada
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Título y fecha de creación
                Text(
                  tarea.titulo,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Creada el ${tarea.creadaEn.day}/${tarea.creadaEn.month}/${tarea.creadaEn.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 20),

                // Descripción
                if (tarea.descripcion.isNotEmpty) ...[
                  _buildSeccionLabel('Descripción'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      tarea.descripcion,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF444466),
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Tarjeta info
                _buildInfoCard(tarea),
                const SizedBox(height: 16),

                // Archivos adjuntos — solo PDFs
                if (pdfs.isNotEmpty) ...[
                  _buildSeccionLabel('Archivos adjuntos'),
                  const SizedBox(height: 8),
                  _buildListaPdfs(pdfs),
                  const SizedBox(height: 16),
                ],

                // Botón completar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await TareaService().marcarCompletada(
                        tarea.firestoreId!,
                        !tarea.completada,
                      );
                      _cargar();
                    },
                    icon: Icon(
                      tarea.completada
                          ? Icons.undo_rounded
                          : Icons.check_circle_outline_rounded,
                    ),
                    label: Text(
                      tarea.completada
                          ? 'Marcar como pendiente'
                          : 'Marcar como completada',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tarea.completada
                          ? Colors.grey.shade400
                          : AppTheme.accent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Imagen grande de exhibición (toca → fullscreen) ───────────────────────
  Widget _buildImagenExhibicion(List<String> imagenes) {
    return GestureDetector(
      onTap: () => _abrirViewer(imagenes, _imagenSeleccionada),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Image.network(
              imagenes[_imagenSeleccionada],
              key: ValueKey(_imagenSeleccionada),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade200,
                child: const Icon(
                  Icons.broken_image_outlined,
                  size: 48,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          // Degradado inferior
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.45)],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),
          // Ícono expandir (esquina inferior derecha)
          Positioned(
            bottom: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.fullscreen_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Miniaturas horizontales ────────────────────
  Widget _buildMiniaturas(List<String> imagenes) {
    if (imagenes.length <= 1) return const SizedBox();

    return Container(
      color: AppTheme.primary.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imagenes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final seleccionado = i == _imagenSeleccionada;
          return GestureDetector(
            onTap: () => setState(() => _imagenSeleccionada = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: seleccionado ? AppTheme.primary : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: seleccionado
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imagenes[i],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Tarjeta de info ───────────────────────────────────────────────────────
  Widget _buildInfoCard(Tarea tarea) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildFilaInfo(
            icono: Icons.book_outlined,
            label: 'Materia',
            valor: tarea.materia,
            iconColor: AppTheme.primary,
          ),
          _buildDivider(),
          _buildFilaInfo(
            icono: Icons.calendar_today_outlined,
            label: 'Fecha de entrega',
            valor:
                '${tarea.fechaEntrega.day}/${tarea.fechaEntrega.month}/${tarea.fechaEntrega.year}',
            iconColor: AppTheme.secondary,
          ),
          _buildDivider(),
          _buildFilaInfo(
            icono: Icons.access_time_rounded,
            label: 'Hora de vencimiento',
            valor: tarea.horaEntrega != null
                ? '${tarea.horaEntrega!.hour.toString().padLeft(2, '0')}:${tarea.horaEntrega!.minute.toString().padLeft(2, '0')}'
                : 'Sin hora definida',
            iconColor: AppTheme.secondary,
          ),
          _buildDivider(),
          _buildFilaInfo(
            icono: Icons.category_outlined,
            label: 'Tipo',
            valor: tarea.tipo,
            iconColor: AppTheme.colorTipo(tarea.tipo),
          ),
        ],
      ),
    );
  }

  Widget _buildFilaInfo({
    required IconData icono,
    required String label,
    required String valor,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
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
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => Divider(
    height: 1,
    indent: 64,
    endIndent: 16,
    color: Colors.grey.shade100,
  );

  // ── Extrae nombre legible desde URL de Cloudinary ─────────────────────────
  // URL ejemplo: .../archivos_tareas/mi_tarea_final  (sin extensión en raw)
  // Resultado:   "mi tarea final.pdf"
  String _nombrePdf(String url) {
    final segmento = Uri.parse(url).pathSegments.last;
    // Quitar parámetros de query si los hubiera
    final sinQuery = segmento.split('?').first;
    // Reemplazar guiones bajos por espacios y añadir .pdf si no lo tiene
    final bonito = sinQuery.replaceAll('_', ' ');
    return bonito.toLowerCase().endsWith('.pdf') ? bonito : '$bonito.pdf';
  }

  // ── Descarga el PDF y lo abre con la app predeterminada ──────────────────
  Future<void> _abrirPdf(String url) async {
    // Mostrar indicador de descarga
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 14),
            Text('Descargando archivo...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      // Descargar bytes directamente desde Cloudinary
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      // Guardar en directorio temporal del dispositivo
      final dir = await getTemporaryDirectory();
      final nombre = _nombrePdf(url);
      final archivo = File('${dir.path}/$nombre');
      await archivo.writeAsBytes(response.bodyBytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Abrir con la app predeterminada (Adobe, Files, etc.)
      final resultado = await OpenFilex.open(archivo.path);

      if (resultado.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resultado.type == ResultType.noAppToOpen
                  ? 'No hay app instalada para abrir PDFs'
                  : 'No se pudo abrir el archivo',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al descargar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Lista de PDFs ─────────────────────────────────────────────────────────
  Widget _buildListaPdfs(List<String> pdfs) {
    return Column(
      children: pdfs.map((url) {
        final nombre = _nombrePdf(url);
        return GestureDetector(
          onTap: () => _abrirPdf(url),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: AppTheme.danger,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A2E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Toca para abrir',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.open_in_new_rounded,
                  color: AppTheme.primary.withOpacity(0.6),
                  size: 18,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Chips ─────────────────────────────────────────────────────────────────
  Widget _buildChip(String texto, Color color, {IconData? icono}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: icono != null ? 8 : 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionLabel(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppTheme.primary,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Pantalla fullscreen de imagen (navega con swipe entre imágenes)
// ════════════════════════════════════════════════════════════════════════════
class _ImagenFullscreenView extends StatefulWidget {
  final List<String> imagenes;
  final int indiceInicial;

  const _ImagenFullscreenView({
    required this.imagenes,
    required this.indiceInicial,
  });

  @override
  State<_ImagenFullscreenView> createState() => _ImagenFullscreenViewState();
}

class _ImagenFullscreenViewState extends State<_ImagenFullscreenView> {
  late final PageController _pageController;
  late int _indiceActual;

  @override
  void initState() {
    super.initState();
    _indiceActual = widget.indiceInicial;
    _pageController = PageController(initialPage: widget.indiceInicial);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── PageView con zoom por InteractiveViewer ───────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imagenes.length,
            onPageChanged: (i) => setState(() => _indiceActual = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  widget.imagenes[i],
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),

          // ── Botón cerrar ─────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),

          // ── Contador de imagen (ej. 1 / 3) ───────────────────────────
          if (widget.imagenes.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 14,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_indiceActual + 1} / ${widget.imagenes.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

          // ── Miniaturas inferiores para navegar ────────────────────────
          if (widget.imagenes.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.imagenes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final sel = i == _indiceActual;
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: sel ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.network(
                            widget.imagenes[i],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade800,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white38,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
