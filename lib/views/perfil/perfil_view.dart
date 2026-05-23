import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/usuario_model.dart';
import '../../services/auth_service.dart';
import '../../themes/app_theme.dart';

class PerfilView extends StatefulWidget {
  const PerfilView({super.key});

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  bool _cargando = true;
  Usuario? _usuario;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final u = await AuthService().getPerfil();
    if (!mounted) return;
    setState(() {
      _usuario = u;
      _cargando = false;
    });
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await AuthService().logout();
    if (!mounted) return;
    context.go('/login');
  }

  void _cambiarContrasena() => context.push('/perfil/cambiar-contrasena');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _usuario == null
          ? const Center(child: Text('No se pudo cargar el perfil'))
          : RefreshIndicator(
              onRefresh: _cargar,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _Header(usuario: _usuario!)),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel('CONTACTO'),
                          const SizedBox(height: 8),
                          _SectionCard(
                            children: [
                              _OptionTile(
                                icon: Icons.mail_outline_rounded,
                                iconColor: AppTheme.primary,
                                title: _usuario!.email,
                                subtitle: 'Correo electrónico',
                                showArrow: false,
                              ),
                              _Divider(),
                              _OptionTile(
                                icon: Icons.phone_outlined,
                                iconColor: AppTheme.primary,
                                title: _usuario!.telefono.isEmpty
                                    ? 'No registrado'
                                    : _usuario!.telefono,
                                subtitle: 'Teléfono',
                                showArrow: false,
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          _SectionLabel('CUENTA'),
                          const SizedBox(height: 8),
                          _SectionCard(
                            children: [
                              _OptionTile(
                                icon: Icons.person_outline_rounded,
                                iconColor: AppTheme.primary,
                                title: 'Información personal',
                                onTap: () => context.push('/perfil/info'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          _SectionLabel('AJUSTES'),
                          const SizedBox(height: 8),
                          _SectionCard(
                            children: [
                              _OptionTile(
                                icon: Icons.palette_outlined,
                                iconColor: AppTheme.primary,
                                title: 'Apariencia',
                                onTap: _cambiarTema,
                              ),
                              _Divider(),
                              _OptionTile(
                                icon: Icons.lock_outline_rounded,
                                iconColor: AppTheme.primary,
                                title: 'Cambiar contraseña',
                                onTap: _cambiarContrasena,
                              ),
                              _Divider(),
                              _OptionTile(
                                icon: Icons.logout_rounded,
                                iconColor: Colors.red,
                                title: 'Cerrar sesión',
                                titleColor: Colors.red,
                                onTap: _cerrarSesion,
                                showArrow: false,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _cambiarTema() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Apariencia',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _OpcionTema(
              icono: Icons.brightness_auto_rounded,
              label: 'Automático (sistema)',
              modo: ThemeMode.system,
            ),
            const SizedBox(height: 10),
            _OpcionTema(
              icono: Icons.light_mode_rounded,
              label: 'Modo claro',
              modo: ThemeMode.light,
            ),
            const SizedBox(height: 10),
            _OpcionTema(
              icono: Icons.dark_mode_rounded,
              label: 'Modo oscuro',
              modo: ThemeMode.dark,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final Usuario usuario;
  const _Header({required this.usuario});

  @override
  Widget build(BuildContext context) {
    final foto = usuario.fotoPerfil;
    final tieneFoto = foto != null && foto.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.primaryOf(context),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 32,
        left: 20,
        right: 20,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              const Text(
                'Mi Perfil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),

          const SizedBox(height: 20),

          // ── Avatar ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: Colors.white.withOpacity(0.25),
              backgroundImage: tieneFoto
                  ? NetworkImage(foto!) as ImageProvider
                  : null,
              child: tieneFoto
                  ? null
                  : Text(
                      usuario.nombre.isNotEmpty
                          ? usuario.nombre[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            usuario.nombre,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 4),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Estudiante',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade500,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: const Color(0xFF2A2D45)) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(children: children),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final bool showArrow;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.showArrow = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color:
                          titleColor ?? Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.55),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showArrow)
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFCCCCCC),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 70,
      endIndent: 16,
      color: Theme.of(context).dividerColor,
    );
  }
}

class _OpcionTema extends StatelessWidget {
  final IconData icono;
  final String label;
  final ThemeMode modo;

  const _OpcionTema({
    required this.icono,
    required this.label,
    required this.modo,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (_, modoActual, __) {
        final seleccionado = modoActual == modo;
        return GestureDetector(
          onTap: () async {
            themeModeNotifier.value = modo;
            final prefs = await SharedPreferences.getInstance();
            final key = modo == ThemeMode.dark
                ? 'dark'
                : modo == ThemeMode.light
                ? 'light'
                : 'system';
            await prefs.setString('theme_mode', key);
            if (context.mounted) Navigator.pop(context);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: seleccionado
                  ? primary.withOpacity(0.08)
                  : isDark
                  ? const Color(0xFF242840)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: seleccionado ? primary : Theme.of(context).dividerColor,
                width: seleccionado ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icono,
                  color: seleccionado ? primary : Colors.grey,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: seleccionado
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: seleccionado
                          ? primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                if (seleccionado)
                  Icon(Icons.check_circle_rounded, color: primary, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
