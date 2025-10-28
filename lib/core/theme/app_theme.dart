import 'package:flutter/material.dart';

class AppTheme {
  // ----- Light Theme -----
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF6F2ED), // Frothy White
    primaryColor: const Color(0xFF4B2C20), // Espresso Brown
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF4B2C20),
      secondary: Color(0xFF4E8D7C), // Fresh Mint
      background: Color(0xFFF6F2ED),
      surface: Color(0xFFD5BBA2), // Creamy Latte
      onPrimary: Colors.white,
      onBackground: Color(0xFF272727), // Black
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF4B2C20),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF272727)),
      bodyMedium: TextStyle(color: Color(0xFF272727)),
      titleLarge: TextStyle(color: Color(0xFF4B2C20), fontWeight: FontWeight.bold),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: Color(0xFF4E8D7C), // Fresh Mint
      textTheme: ButtonTextTheme.primary,
    ),
  );

  // ----- Dark Theme -----
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1E1410), // Black Coffee
    primaryColor: const Color(0xFF332920), // Dark Roast
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF332920),
      secondary: Color(0xFF3C7266), // Moonlight Mint
      background: Color(0xFF1E1410),
      surface: Color(0xFF2E2A27), // Charcoal Foam
      onPrimary: Color(0xFFF6F2ED),
      onBackground: Color(0xFF989898), // Light Grey
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF332920),
      foregroundColor: Color(0xFFF6F2ED),
      elevation: 0,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFF6F2ED)),
      bodyMedium: TextStyle(color: Color(0xFF989898)),
      titleLarge: TextStyle(color: Color(0xFF8C6A4F), fontWeight: FontWeight.bold), // Midnight Caramel
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: Color(0xFF3C7266), // Moonlight Mint
      textTheme: ButtonTextTheme.primary,
    ),
  );
}
