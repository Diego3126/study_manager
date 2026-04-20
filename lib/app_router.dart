import 'package:go_router/go_router.dart';
import 'home_screen.dart';
import 'paso_parametros/detalle_screen.dart';
import 'paso_parametros/paso_parametros_screen.dart';
import 'ciclo_vida/ciclo_vida_screen.dart';
import 'future/future_view.dart';
import 'timer/timer_view.dart';
import 'isolate/isolate_view.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/paso_parametros',
      builder: (context, state) => const PasoParametrosScreen(),
    ),
    GoRoute(
      path: '/detalle/:parametro/:metodo',
      builder: (context, state) {
        final parametro = state.pathParameters['parametro']!;
        final metodo = state.pathParameters['metodo']!;
        return DetalleScreen(parametro: parametro, metodoNavegacion: metodo);
      },
    ),
    GoRoute(
      path: '/ciclo_vida',
      name: 'ciclo_vida',
      builder: (context, state) => const CicloVidaScreen(),
    ),
    GoRoute(
      path: '/future',
      builder: (context, state) => const FutureView(),
    ),
    GoRoute(
      path: '/timer',
      builder: (context, state) => const TimerView(),
    ),
    GoRoute(
      path: '/isolate',
      builder: (context, state) => const IsolateView(),
    ),
  ],
);