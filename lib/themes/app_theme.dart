import 'package:flutter/material.dart';

class AppTheme {
  // ── Paleta modo claro ─────────────────────────────────────────────────────
  static const Color primary   = Color(0xFF6C47FF);
  static const Color secondary = Color(0xFF4A90D9);
  static const Color accent    = Color(0xFF00C896);
  static const Color warning   = Color(0xFFF5A623);
  static const Color danger    = Color(0xFFF25C5C);

  // ── Paleta modo oscuro ────────────────────────────────────────────────────
  static const Color primaryDark   = Color(0xFF8B6FFF);
  static const Color accentDark    = Color(0xFF00E5A8);

  // ── Tema claro ────────────────────────────────────────────────────────────
  static ThemeData get theme => _buildTheme(Brightness.light);

  // ── Tema oscuro ───────────────────────────────────────────────────────────
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = isDark
        ? ColorScheme.dark(
            primary:    primaryDark,
            secondary:  secondary,
            surface:    const Color(0xFF1A1D2E),
            error:      danger,
          )
        : ColorScheme.light(
            primary:    primary,
            secondary:  secondary,
            surface:    Colors.white,
            error:      danger,
          );

    return ThemeData(
      useMaterial3:  true,
      brightness:    brightness,
      colorScheme:   colorScheme,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0F1117)
          : const Color(0xFFF4F6FA),

      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1A1D2E) : primary,
        foregroundColor: Colors.white,
        centerTitle:     true,
        elevation:       0,
        titleTextStyle:  const TextStyle(
          color:      Colors.white,
          fontSize:   20,
          fontWeight: FontWeight.bold,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 3,
        color: isDark ? const Color(0xFF1A1D2E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isDark
              ? const BorderSide(color: Color(0xFF2A2D45))
              : BorderSide.none,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? accentDark : accent,
        foregroundColor: Colors.white,
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled:    true,
        fillColor: isDark
            ? const Color(0xFF242840)
            : Colors.grey.shade50,
      ),

      dividerColor: isDark
          ? const Color(0xFF2A2D45)
          : const Color(0xFFF0F0F0),

      textTheme: TextTheme(
        bodyLarge:  TextStyle(
          color: isDark ? const Color(0xFFF0F0FF) : const Color(0xFF1A1A2E),
        ),
        bodyMedium: TextStyle(
          color: isDark ? const Color(0xFFF0F0FF) : const Color(0xFF1A1A2E),
        ),
      ),
    );
  }

  // ── Helper: color primario según modo ─────────────────────────────────────
  static Color primaryOf(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? primaryDark : primary;
  }

  // ── Colores por prioridad ─────────────────────────────────────────────────
  static Color colorPrioridad(String prioridad) {
    switch (prioridad) {
      case 'Alta':   return danger;
      case 'Media':  return warning;
      case 'Baja':   return accent;
      default:       return primary;
    }
  }

  // ── Colores por tipo ──────────────────────────────────────────────────────
  static Color colorTipo(String tipo) {
    switch (tipo) {
      case 'Examen':      return danger;
      case 'Proyecto':    return secondary;
      case 'Tarea':       return primary;
      case 'Quiz':        return warning;
      case 'Exposición':  return const Color(0xFF9C27B0);
      default:            return primary;
    }
  }
}