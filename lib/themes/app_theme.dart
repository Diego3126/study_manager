import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF4A90D9);
  static const Color secondary = Color(0xFF7B68EE);
  static const Color accent = Color(0xFF50C878);
  static const Color warning = Color(0xFFFFB347);
  static const Color danger = Color(0xFFFF6B6B);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  // Colores por prioridad
  static Color colorPrioridad(String prioridad) {
    switch (prioridad) {
      case 'Alta':
        return danger;
      case 'Media':
        return warning;
      case 'Baja':
        return accent;
      default:
        return primary;
    }
  }

  // Colores por tipo
  static Color colorTipo(String tipo) {
    switch (tipo) {
      case 'Examen':
        return danger;
      case 'Proyecto':
        return secondary;
      case 'Tarea':
        return primary;
      case 'Quiz':
        return warning;
      case 'Exposición':
        return const Color(0xFF9C27B0);
      default:
        return primary;
    }
  }
}
