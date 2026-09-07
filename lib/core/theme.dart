import 'package:flutter/material.dart';

class DarkTraceTheme {
  static const background = Color(0xFF0B1020);
  static const surface = Color(0xFF121A2F);
  static const violet = Color(0xFF8B5CF6);
  static const cyan = Color(0xFF22D3EE);
  static const danger = Color(0xFFF43F5E);
  static const success = Color(0xFF34D399);
  static const gold = Color(0xFFFBBF24);
  static const text = Color(0xFFF8FAFC);
  static const muted = Color(0xFF94A3B8);

  static ThemeData get data => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          surface: surface,
          primary: violet,
          secondary: cyan,
          error: danger,
        ),
        fontFamily: 'sans',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 1.2),
          headlineMedium: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          bodyMedium: TextStyle(fontSize: 14, color: muted, height: 1.4),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xE6121A2F),
          indicatorColor: Color(0x338B5CF6),
          labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      );
}
