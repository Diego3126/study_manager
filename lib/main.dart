import 'package:flutter/material.dart';
import 'app_router.dart';
import 'app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: AppTheme.lightTheme,
      title: 'StudyManager',
      routerConfig: appRouter,
    );
  }
}