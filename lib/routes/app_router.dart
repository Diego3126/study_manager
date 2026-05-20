import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../views/auth/login_view.dart';
import '../views/auth/registro_view.dart';
import '../views/perfil/perfil_view.dart';
import '../views/dashboard/dashboard_view.dart';
import '../views/tareas/tareas_view.dart';
import '../views/tareas/tarea_form_view.dart';
import '../views/tareas/tarea_detalle_view.dart';
import '../views/enfoque/enfoque_view.dart';
import '../views/estadisticas/estadisticas_view.dart';
import '../views/perfil/editar_perfil_view.dart';
import '../views/universidades/universidades_view.dart';
import '../views/universidades/universidad_form_view.dart';
import '../views/perfil/perfil_info_view.dart';
import '../views/perfil/cambiar_password_view.dart';
import '../views/main_shell.dart';  // ← nuevo

final GoRouter appRouter = GoRouter(
  initialLocation: '/dashboard',
  redirect: (context, state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final enLogin =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/registro';
    if (!loggedIn && !enLogin) return '/login';
    if (loggedIn && enLogin) return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginView()),
    GoRoute(path: '/registro', builder: (context, state) => const RegistroView()),

    // ── Shell con barra inferior ──────────────────────────────────────────
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardView(),
        ),
        GoRoute(
          path: '/tareas',
          builder: (context, state) => const TareasView(),
        ),
        GoRoute(
          path: '/enfoque',
          builder: (context, state) => const EnfoqueView(),
        ),
        GoRoute(
          path: '/estadisticas',
          builder: (context, state) => const EstadisticasView(),
        ),
        GoRoute(
          path: '/universidades',
          builder: (context, state) => const UniversidadesView(),
        ),
      ],
    ),

    // ── Rutas que van por encima del shell (sin barra) ────────────────────
    GoRoute(path: '/tareas/nueva', builder: (context, state) => const TareaFormView()),
    GoRoute(
      path: '/tareas/:id',
      builder: (context, state) => TareaDetalleView(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/tareas/:id/editar',
      builder: (context, state) => TareaFormView(id: state.pathParameters['id']!),
    ),
    GoRoute(path: '/perfil', builder: (context, state) => const PerfilView()),
    GoRoute(path: '/perfil/editar', builder: (context, state) => const EditarPerfilView()),
    GoRoute(path: '/perfil/info', builder: (context, state) => const PerfilInfoView()),
    GoRoute(path: '/perfil/cambiar-contrasena', builder: (context, state) => const CambiarPasswordView()),
    GoRoute(path: '/universidades/nueva', builder: (context, state) => const UniversidadFormView()),
  ],
);