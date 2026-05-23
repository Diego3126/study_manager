import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';
import 'themes/app_theme.dart';
import 'services/auth_service.dart';

// ← Notifier global para el tema — accesible desde cualquier pantalla
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AuthService().cerrarSesionSiNoRecuerda();

  // Cargar preferencia guardada
  final prefs = await SharedPreferences.getInstance();
  final guardado = prefs.getString('theme_mode');
  if (guardado == 'dark')  themeModeNotifier.value = ThemeMode.dark;
  if (guardado == 'light') themeModeNotifier.value = ThemeMode.light;

  runApp(const StudyManagerApp());
}

class StudyManagerApp extends StatelessWidget {
  const StudyManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (_, mode, __) => MaterialApp.router(
        title:           'StudyManager',
        debugShowCheckedModeBanner: false,
        theme:           AppTheme.theme,
        darkTheme:       AppTheme.darkTheme,
        themeMode:       mode,
        routerConfig:    appRouter,
      ),
    );
  }
}