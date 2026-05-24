import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:study_manager/services/notificacion_service.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';
import 'themes/app_theme.dart';

final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();

  // Solo leemos el tema antes de arrancar — es instantáneo
  final prefs = await SharedPreferences.getInstance();
  final guardado = prefs.getString('theme_mode');
  if (guardado == 'dark')  themeModeNotifier.value = ThemeMode.dark;
  if (guardado == 'light') themeModeNotifier.value = ThemeMode.light;

  runApp(const StudyManagerApp());
  // Firebase y auth se inicializan dentro del SplashView
}

class StudyManagerApp extends StatelessWidget {
  const StudyManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (_, mode, __) => MaterialApp.router(
        title: 'StudyManager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        darkTheme: AppTheme.darkTheme,
        themeMode: mode,
        routerConfig: appRouter,
      ),
    );
  }
}