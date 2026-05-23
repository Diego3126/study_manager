import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:study_manager/services/auth_service.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';
import 'themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AuthService().cerrarSesionSiNoRecuerda();
  runApp(const StudyManagerApp());
}

class StudyManagerApp extends StatelessWidget {
  const StudyManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'StudyManager',
      theme: AppTheme.theme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
