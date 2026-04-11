import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color.fromARGB(255, 29, 23, 202),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color.fromARGB(255, 20, 165, 97),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        elevation: 0,
        backgroundColor: Colors.white,
      ),
    );
  }
}