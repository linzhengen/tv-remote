import 'package:flutter/material.dart';

class AppTheme {
  static const _primaryColor = Color(0xFF1A1A2E);
  static const _accentColor = Color(0xFF00ADB5);
  static const _buttonColor = Color(0xFF2D2D44);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: _primaryColor,
      scaffoldBackgroundColor: _primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: _accentColor,
        secondary: _accentColor,
        surface: _buttonColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _buttonColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
        ),
      ),
      cardTheme: CardThemeData(
        color: _buttonColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
