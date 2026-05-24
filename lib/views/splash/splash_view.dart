import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../firebase_options.dart';
import '../../services/auth_service.dart';
import '../../themes/app_theme.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  // ── Animaciones ────────────────────────────────────────────────────────────
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<double> _fadeOut;

  // ── Barra de progreso ──────────────────────────────────────────────────────
  double _progreso = 0.0;
  String _mensaje = 'Iniciando...';
  String? _destino; // guarda a dónde ir hasta que el fade out termine

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Fade + scale de entrada (0 → 800 ms)
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );
    _scaleIn = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    // Fade out de salida (últimos 400 ms del controller)
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    _inicializar();
  }

  Future<void> _inicializar() async {
    // ── Paso 1: Firebase ───────────────────────────────────────────────────
    _setProgreso(0.15, 'Iniciando servicios...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // ── Paso 2: Verificar sesión ───────────────────────────────────────────
    _setProgreso(0.50, 'Verificando tu sesión...');
    await AuthService().cerrarSesionSiNoRecuerda();

    // ── Paso 3: Decidir destino ────────────────────────────────────────────
    _setProgreso(0.80, 'Cargando tus tareas...');
    await Future.delayed(const Duration(milliseconds: 400));

    final user = FirebaseAuth.instance.currentUser;
    _destino = user != null ? '/dashboard' : '/login';

    // ── Paso 4: Completar barra y salir ───────────────────────────────────
    _setProgreso(1.0, 'Listo ✓');
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Dispara el fade out (interval 0.75–1.0 del controller)
    await _controller.animateTo(
      1.0,
      duration: const Duration(milliseconds: 400),
    );
    if (!mounted) return;

    context.go(_destino!);
  }

  void _setProgreso(double valor, String mensaje) {
    if (!mounted) return;
    setState(() {
      _progreso = valor;
      _mensaje = mensaje;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryOf(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFEDE8FF),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return Opacity(
            opacity: _fadeOut.value,
            child: FadeTransition(
              opacity: _fadeIn,
              child: ScaleTransition(
                scale: _scaleIn,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // ── Fondo que cubre toda la pantalla ─────────────────
                    Image.asset(
                      'assets/images/splash_bg.png',
                      fit: BoxFit.cover,
                      width: size.width,
                      height: size.height,
                    ),

                    // ── Contenido sobre el fondo ─────────────────────────
                    SafeArea(
                      child: Column(
                        children: [
                          // ── Ícono centrado ───────────────────────────────
                          Expanded(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 48,
                                ),
                                child: Image.asset(
                                  'assets/images/splash_icon.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),

                          // ── Título ───────────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Column(
                              children: [
                                RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 38,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Study ',
                                        style: TextStyle(
                                          color: Color(0xFF1A1A2E),
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Manager',
                                        style: TextStyle(
                                          color: Color(0xFF6C47FF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Organiza tus tareas, cumple tus metas\ny alcanza tu mejor versión.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF7A7A9A),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // ── Barra de progreso ────────────────────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: _progreso),
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                    builder: (_, value, __) =>
                                        LinearProgressIndicator(
                                          value: value,
                                          minHeight: 8,
                                          backgroundColor: primary.withOpacity(
                                            0.15,
                                          ),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                primary,
                                              ),
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Text(
                                    _mensaje,
                                    key: ValueKey(_mensaje),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: primary.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
