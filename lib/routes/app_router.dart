import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../views/auth/login_view.dart';
import '../views/auth/registro_view.dart';
import '../views/perfil/perfil_view.dart';
import '../views/dashboard/dashboard_view.dart';
import '../views/tareas/tareas_view.dart';
import '../views/tareas/tarea_form_view.dart';
import '../views/tareas/tarea_detalle_view.dart';
import '../views/enfoque/enfoque_view.dart';
import '../views/estadisticas/estadisticas_view.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final enLogin  = state.matchedLocation == '/login' ||
                     state.matchedLocation == '/registro';
    if (!loggedIn && !enLogin) return '/login';
    if (loggedIn  &&  enLogin) return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginView(),
    ),
    GoRoute(
      path: '/registro',
      builder: (context, state) => const RegistroView(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardView(),
    ),
    GoRoute(
      path: '/tareas',
      builder: (context, state) => const TareasView(),
    ),
    GoRoute(
      path: '/tareas/nueva',
      builder: (context, state) => const TareaFormView(),
    ),
    GoRoute(
      path: '/tareas/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return TareaDetalleView(id: id);
      },
    ),
    GoRoute(
      path: '/tareas/:id/editar',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return TareaFormView(id: id);
      },
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
      path: '/perfil',
      builder: (context, state) => const PerfilView(),
    ),
  ],
);