import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/usuario_model.dart';
import '../../services/auth_service.dart';
import '../../themes/app_theme.dart';

class PerfilInfoView extends StatefulWidget {
  const PerfilInfoView({super.key});

  @override
  State<PerfilInfoView> createState() => _PerfilInfoViewState();
}

class _PerfilInfoViewState extends State<PerfilInfoView> {
  bool     _cargando = true;
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
      _usuario  = u;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _usuario == null
              ? const Center(child: Text('No se pudo cargar la información'))
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [

                      // ── Header ──────────────────────────────────────
                      SliverToBoxAdapter(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: const BorderRadius.only(
                              bottomLeft:  Radius.circular(32),
                              bottomRight: Radius.circular(32),
                            ),
                          ),
                          padding: EdgeInsets.only(
                            top:    MediaQuery.of(context).padding.top + 16,
                            bottom: 28,
                            left:   20,
                            right:  20,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_rounded,
                                    color: Colors.white),
                                onPressed: () => context.pop(),
                              ),
                              const Expanded(
                                child: Text(
                                  'Información personal',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color:      Colors.white,
                                    fontSize:   18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              // Espacio para mantener el título centrado
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),
                      ),

                      // ── Contenido ────────────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              // Tarjeta de datos
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color:     Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset:    const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    _InfoTile(
                                      icon:  Icons.person_outline_rounded,
                                      label: 'Nombre',
                                      valor: _usuario!.nombre,
                                    ),
                                    _InfoTile(
                                      icon:  Icons.mail_outline_rounded,
                                      label: 'Correo',
                                      valor: _usuario!.email,
                                    ),
                                    _InfoTile(
                                      icon:  Icons.lock_outline_rounded,
                                      label: 'Contraseña',
                                      valor: '••••••••',
                                    ),
                                    _InfoTile(
                                      icon:  Icons.phone_outlined,
                                      label: 'Teléfono',
                                      valor: _usuario!.telefono.isEmpty
                                          ? 'No registrado'
                                          : _usuario!.telefono,
                                    ),
                                    _InfoTile(
                                      icon:  Icons.school_outlined,
                                      label: 'Carrera',
                                      valor: _usuario!.carrera.isEmpty
                                          ? 'No registrada'
                                          : _usuario!.carrera,
                                    ),
                                    _InfoTile(
                                      icon:  Icons.numbers_outlined,
                                      label: 'Semestre',
                                      valor: _usuario!.semestre.isEmpty
                                          ? 'No registrado'
                                          : _usuario!.semestre,
                                    ),
                                    _InfoTile(
                                      icon:     Icons.account_balance_outlined,
                                      label:    'Universidad',
                                      valor:    _usuario!.universidad.isEmpty
                                          ? 'No registrada'
                                          : _usuario!.universidad,
                                      esUltimo: true,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 28),

                              // ── Botón editar ───────────────────────
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await context.push('/perfil/editar');
                                    _cargar();
                                  },
                                  icon:  const Icon(Icons.edit_outlined),
                                  label: const Text('Editar información'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
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
}

// ── Widget de fila de información ─────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   valor;
  final bool     esUltimo;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.valor,
    this.esUltimo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width:  40,
                height: 40,
                decoration: BoxDecoration(
                  color:        AppTheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color:    Color(0xFF8A8A9A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      valor,
                      style: const TextStyle(
                        fontSize:   15,
                        fontWeight: FontWeight.w500,
                        color:      Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!esUltimo)
          const Divider(
            height:    1,
            indent:    70,
            endIndent: 16,
            color:     Color(0xFFF0F0F0),
          ),
      ],
    );
  }
}