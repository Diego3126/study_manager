import 'package:go_router/go_router.dart';
import '../views/dashboard/dashboard_view.dart';
import '../views/tareas/tareas_view.dart';
import '../views/tareas/tarea_form_view.dart';
import '../views/tareas/tarea_detalle_view.dart';
import '../views/enfoque/enfoque_view.dart';
import '../views/estadisticas/estadisticas_view.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
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
        final id = state.pathParameters['id']!;
        return TareaDetalleView(id: id);
      },
    ),
    GoRoute(
      path: '/tareas/:id/editar',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
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
  ],
);