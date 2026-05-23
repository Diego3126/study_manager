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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppTheme.primaryOf(context);

    return Scaffold(
      // ✅ Usa el color de fondo del tema en lugar de hardcodeado
      body: CustomScrollView(
        slivers: [
          // ── Header ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                // ✅ Usa primaryOf(context) para adaptarse al modo oscuro
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft:  Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.only(
                top:    MediaQuery.of(context).padding.top + 16,
                bottom: 24,
                left:   20,
                right:  20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Universidades',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Instituciones registradas',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Lista ─────────────────────────────────────────────────────────
          StreamBuilder<List<Universidad>>(
            stream: UniversidadService().getStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('Error: ${snapshot.error}')),
                );
              }

              final unis = snapshot.data ?? [];

              if (unis.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.account_balance_outlined,
                            size: 48,
                            color: primaryColor.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sin universidades registradas',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            // ✅ Usa el color de texto del tema
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Toca el botón para agregar una',
                          style: TextStyle(
                            // ✅ onSurface con opacidad en lugar de Colors.grey fijo
                            color: colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) =>
                        _UniversidadCard(universidad: unis[i]),
                    childCount: unis.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      // ── Botón agregar ─────────────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: ElevatedButton.icon(
            onPressed: () => context.push('/universidades/nueva'),
            icon: const Icon(Icons.add),
            label: const Text('Agregar universidad'),
            style: ElevatedButton.styleFrom(
              // ✅ primaryOf(context) en lugar de AppTheme.primary fijo
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              elevation: 2,
            ),
          ),
        ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmar = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => Container(
        decoration: BoxDecoration(
          // ✅ Usa el color de superficie del tema
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.danger, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Eliminar universidad',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                // ✅ Usa onSurface del tema
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¿Seguro que deseas eliminar "${universidad.nombre}"? Esta acción no se puede deshacer.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                // ✅ onSurface con opacidad en lugar de Colors.grey fijo
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
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
                      borderRadius: BorderRadius.circular(30)),
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
                      borderRadius: BorderRadius.circular(30)),
                  // ✅ Borde usando el divider color del tema
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                // ✅ Sin color hardcodeado; hereda onSurface del tema
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmar != true) return;
    await UniversidadService().eliminar(universidad.id!);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppTheme.primaryOf(context);

    final tienelogo = universidad.logoUrl != null &&
        universidad.logoUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        // ✅ surface del tema en lugar de Colors.white fijo
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        // ✅ Sombra solo en modo claro (en oscuro ya hay borde via cardTheme)
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
        border: isDark
            ? Border.all(color: const Color(0xFF2A2D45))
            : null,
      ),
      child: Column(
        children: [
          // ── Cabecera con logo y nombre ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Logo o ícono
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: primaryColor.withOpacity(0.15)),
                  ),
                  child: tienelogo
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.network(
                            universidad.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.account_balance_rounded,
                              color: primaryColor.withOpacity(0.5),
                              size: 30,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.account_balance_rounded,
                          color: primaryColor.withOpacity(0.5),
                          size: 30,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        universidad.nombre,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          // ✅ onSurface del tema
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'NIT: ${universidad.nit}',
                          style: TextStyle(
                            fontSize: 11,
                            color: primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Botón eliminar
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded,
                      color: AppTheme.danger.withOpacity(0.7)),
                  onPressed: () => _eliminar(context),
                ),
              ],
            ),
          ),

          // ── Divider ─────────────────────────────────────────────────────
          // ✅ Usa el dividerColor del tema automáticamente
          const Divider(height: 1),

          // ── Datos de contacto ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                _FilaInfo(
                  icono: Icons.location_on_outlined,
                  texto: universidad.direccion,
                ),
                const SizedBox(height: 8),
                _FilaInfo(
                  icono: Icons.phone_outlined,
                  texto: universidad.telefono,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _abrirUrl(universidad.paginaWeb),
                  child: _FilaInfo(
                    icono: Icons.language,
                    texto: universidad.paginaWeb,
                    color: AppTheme.primaryOf(context),
                    subrayado: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaInfo extends StatelessWidget {
  final IconData icono;
  final String   texto;
  final Color?   color;
  final bool     subrayado;

  const _FilaInfo({
    required this.icono,
    required this.texto,
    this.color,
    this.subrayado = false,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Usa onSurface con opacidad como fallback en lugar de Colors.grey.shade600
    final c = color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: c.withOpacity(0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icono, size: 14, color: c),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 13,
              color: c,
              decoration: subrayado ? TextDecoration.underline : null,
            ),
          ),
        ),
      ],
    );
  }
}