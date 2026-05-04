import 'package:flutter/material.dart';
import 'routes/app_router.dart';
import 'themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StudyManagerApp());
}

class StudyManagerApp extends StatelessWidget {
  const StudyManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title:                  'StudyManager',
      theme:                  AppTheme.theme,
      routerConfig:           appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}