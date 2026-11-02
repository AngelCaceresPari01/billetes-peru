import 'package:flutter/material.dart';

const amarillo = Color(0xFFFFD600);

/// Alto contraste (amarillo sobre negro) y letras grandes, pensado para baja visión.
ThemeData temaAltoContraste() {
  const esquema = ColorScheme.dark(
    primary: amarillo,
    onPrimary: Colors.black,
    secondary: Color(0xFF80DEEA),
    onSecondary: Colors.black,
    surface: Color(0xFF111111),
    onSurface: Colors.white,
    surfaceContainerHighest: Color(0xFF222222),
    error: Color(0xFFFF8A80),
    onError: Colors.black,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: esquema, scaffoldBackgroundColor: Colors.black);
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white, fontSizeFactor: 1.15),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: amarillo,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: amarillo),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      labelStyle: TextStyle(fontSize: 20),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(64),
        textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(64),
        foregroundColor: amarillo,
        side: const BorderSide(color: amarillo, width: 2),
        textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        foregroundColor: amarillo,
        textStyle: const TextStyle(fontSize: 20),
      ),
    ),
  );
}
