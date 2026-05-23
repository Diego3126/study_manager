import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/universidad_model.dart';
import '../../services/universidad_service.dart';
import '../../themes/app_theme.dart';

class UniversidadFormView extends StatefulWidget {
  const UniversidadFormView({super.key});

  @override
  State<UniversidadFormView> createState() => _UniversidadFormViewState();
}

class _UniversidadFormViewState extends State<UniversidadFormView> {
  final _formKey   = GlobalKey<FormState>();
  final _nit       = TextEditingController();
  final _nombre    = TextEditingController();
  final _direccion = TextEditingController();
  final _telefono  = TextEditingController();
  final _paginaWeb = TextEditingController();
  bool _guardando  = false;

  Uint8List? _logoBytes;
  bool _logoModificado = false;

  Future<void> _seleccionarLogo() async {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = AppTheme.primaryOf(context);

    final fuente = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          // ✅ surface del tema en lugar de Colors.white
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                // ✅ onSurface con opacidad en lugar de Colors.grey.shade300
                color: colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Seleccionar logo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                // ✅ onSurface del tema
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.photo_library_outlined, color: primaryColor),
              ),
              title: const Text('Elegir de galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.camera_alt_outlined, color: primaryColor),
              ),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (fuente == null) return;

    final picked = await ImagePicker().pickImage(
      source:       fuente,
      imageQuality: 85,
      maxWidth:     800,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('La imagen supera el límite de 5 MB'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _logoBytes      = bytes;
      _logoModificado = true;
    });
  }

  void _descartarLogo() {
    setState(() {
      _logoBytes      = null;
      _logoModificado = false;
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      String? logoUrl;
      if (_logoModificado && _logoBytes != null) {
        logoUrl = await UniversidadService()
            .subirLogo(_logoBytes!, _nombre.text.trim());
      }

      await UniversidadService().crear(Universidad(
        nit:       _nit.text.trim(),
        nombre:    _nombre.text.trim(),
        direccion: _direccion.text.trim(),
        telefono:  _telefono.text.trim(),
        paginaWeb: _paginaWeb.text.trim(),
        logoUrl:   logoUrl,
      ));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('Universidad registrada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:         Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  void dispose() {
    _nit.dispose();
    _nombre.dispose();
    _direccion.dispose();
    _telefono.dispose();
    _paginaWeb.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme  = Theme.of(context).colorScheme;
    final primaryColor = AppTheme.primaryOf(context);

    return Scaffold(
      // ✅ Sin backgroundColor hardcodeado — usa scaffoldBackgroundColor del tema
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            // ✅ primaryOf(context) en lugar de AppTheme.primary fijo
            backgroundColor: primaryColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              'Nueva Universidad',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // ── Logo picker ───────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _guardando ? null : _seleccionarLogo,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      // ✅ outline del tema cuando no hay logo
                                      color: _logoModificado
                                          ? primaryColor
                                          : colorScheme.outline.withOpacity(0.4),
                                      width: _logoModificado ? 2 : 1,
                                    ),
                                  ),
                                  child: _logoBytes != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          child: Image.memory(
                                            _logoBytes!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.account_balance_rounded,
                                              size: 40,
                                              color: primaryColor.withOpacity(0.5),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Logo',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: primaryColor.withOpacity(0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                                // Botón cámara
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        // ✅ surface del tema en lugar de Colors.white
                                        color: colorScheme.surface,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Estado del logo
                          if (_logoModificado)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline,
                                    size: 13, color: primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  'Logo seleccionado (preview)',
                                  style: TextStyle(
                                      fontSize: 12, color: primaryColor),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _descartarLogo,
                                  child: Text(
                                    'Descartar',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.danger,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              'Toca para agregar logo (máx. 5 MB)',
                              style: TextStyle(
                                fontSize: 12,
                                // ✅ onSurface con opacidad en lugar de Colors.grey.shade500
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Sección: Datos institucionales ────────────────
                    // ✅ context pasado al helper para usar primaryOf(context)
                    _buildSeccionLabel(context, 'Datos institucionales'),
                    const SizedBox(height: 12),

                    _buildCampo(
                      context: context,
                      controller: _nit,
                      label: 'NIT',
                      icono: Icons.badge_outlined,
                      hint: 'Ej: 890.123.456-7',
                      requerido: true,
                    ),
                    const SizedBox(height: 12),

                    _buildCampo(
                      context: context,
                      controller: _nombre,
                      label: 'Nombre de la universidad',
                      icono: Icons.account_balance_outlined,
                      requerido: true,
                    ),
                    const SizedBox(height: 24),

                    // ── Sección: Contacto ─────────────────────────────
                    _buildSeccionLabel(context, 'Contacto'),
                    const SizedBox(height: 12),

                    _buildCampo(
                      context: context,
                      controller: _direccion,
                      label: 'Dirección',
                      icono: Icons.location_on_outlined,
                      requerido: true,
                    ),
                    const SizedBox(height: 12),

                    _buildCampo(
                      context: context,
                      controller: _telefono,
                      label: 'Teléfono',
                      icono: Icons.phone_outlined,
                      tipo: TextInputType.phone,
                      requerido: true,
                    ),
                    const SizedBox(height: 12),

                    _buildCampo(
                      context: context,
                      controller: _paginaWeb,
                      label: 'Página web',
                      icono: Icons.language,
                      hint: 'https://www.universidad.edu.co',
                      tipo: TextInputType.url,
                      requerido: true,
                      validador: (v) {
                        if (v == null || v.isEmpty) return 'Campo requerido';
                        final uri = Uri.tryParse(v);
                        if (uri == null || !uri.hasScheme ||
                            !uri.scheme.startsWith('http'))
                          return 'Ingresa una URL válida (https://...)';
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // ── Botones ───────────────────────────────────────
                    ElevatedButton.icon(
                      onPressed: _guardando ? null : _guardar,
                      icon: _guardando
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                          _guardando ? 'Registrando...' : 'Registrar universidad'),
                      style: ElevatedButton.styleFrom(
                        // ✅ primaryOf(context) en lugar de AppTheme.primary fijo
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: _guardando ? null : () => context.pop(),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        // ✅ onSurface del tema en lugar de Color(0xFF1A1A2E) fijo
                        foregroundColor: colorScheme.onSurface,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        // ✅ outlineVariant del tema en lugar de Colors.grey.shade300
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Recibe context para poder usar primaryOf(context)
  Widget _buildSeccionLabel(BuildContext context, String texto) {
    final primaryColor = AppTheme.primaryOf(context);
    return Row(
      children: [
        Container(
          width: 3, height: 18,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          texto,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            // ✅ primaryOf(context) en lugar de AppTheme.primary fijo
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  // ✅ Recibe context para leer colorScheme y primaryOf
  Widget _buildCampo({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icono,
    String? hint,
    TextInputType tipo = TextInputType.text,
    bool requerido = false,
    String? Function(String?)? validador,
  }) {
    final colorScheme  = Theme.of(context).colorScheme;
    final primaryColor = AppTheme.primaryOf(context);

    return TextFormField(
      controller: controller,
      keyboardType: tipo,
      style: TextStyle(
        fontSize: 15,
        // ✅ onSurface del tema en lugar de Color(0xFF1A1A2E) fijo
        color: colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: requerido ? '$label *' : label,
        hintText: hint,
        hintStyle: TextStyle(
          // ✅ onSurface con opacidad en lugar de Color(0xFFAAAAAA) fijo
          color: colorScheme.onSurface.withOpacity(0.35),
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icono,
          // ✅ onSurface con opacidad en lugar de Color(0xFF8A8A9A) fijo
          color: colorScheme.onSurface.withOpacity(0.45),
          size: 20,
        ),
        filled: true,
        // ✅ surface del tema en lugar de Colors.white fijo
        fillColor: colorScheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          // ✅ outline del tema en lugar de Color(0xFFE8E8F0) fijo
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          // ✅ primaryOf(context) en lugar de AppTheme.primary fijo
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
      ),
      validator: validador ??
          (requerido
              ? (v) => v == null || v.isEmpty ? 'Campo requerido' : null
              : null),
    );
  }
}