import 'package:flutter/material.dart';

/// Tema dell'applicazione
class AppTheme {
  // Colori brand - Modern Premium Theme
  static const Color primario = Color(0xFF6366F1); // Modern Indigo
  static const Color primarioScuro = Color(0xFF4338CA);
  static const Color secondario = Color(0xFF14B8A6); // Teal  
  static const Color errore = Color(0xFFEF4444); // Rosso
  static const Color warning = Color(0xFFFBBF24); // Gold
  static const Color success = Color(0xFF10B981); // Verde
  static const Color successLight = Color(0xFF6EE7B7);
  static const Color info = Color(0xFF3B82F6); // Blu
  static const Color gold = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFFFA500);
  
  // Gradienti
  static const LinearGradient gradientPrimario = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF4338CA)],
  );
  
  static const LinearGradient gradientGold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
  );
  
  static const LinearGradient gradientSuccess = LinearGradient(
    begin: Alignment.topLeft,  
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF6EE7B7)],
  );

  // Grigi
  static const Color grigio100 = Color(0xFFF3F4F6);
  static const Color grigio300 = Color(0xFFD1D5DB);
  static const Color grigio500 = Color(0xFF6B7280);
  static const Color grigio700 = Color(0xFF374151);
  static const Color grigio900 = Color(0xFF111827);

  /// Tema chiaro
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primario,
        primary: primario,
        secondary: secondario,
        error: errore,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: grigio100,
      
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: primario,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primario,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primario,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          side: const BorderSide(color: primario, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primario,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Card
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),

      // InputDecoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: grigio300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: grigio300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primario, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errore, width: 2),
        ),
        labelStyle: TextStyle(color: grigio700),
        hintStyle: TextStyle(color: grigio500),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: grigio900,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: grigio900,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: grigio900,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: grigio900,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: grigio900,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: grigio700,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: grigio700,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: grigio700,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: grigio500,
        ),
      ),

      // FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primario,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Spacing costanti
  static const double spacingXs = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXl = 32.0;

  /// Border radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXl = 24.0;
}

