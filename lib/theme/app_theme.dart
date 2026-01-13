// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

/// Upbit-inspired Light and Dark themes
class AppTheme {
  // Color constants
  // Light
  static const Color _lightScaffold = Color(0xFFF9FAFB); // grey[50]
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightText = Color(0xFF111827); // grey[900]
  static const Color _lightDivider = Color(0xFFE5E7EB); // grey[200]
  static const Color _lightBorder = Color(0xFFE5E7EB);
  
  // Dark
  static const Color _darkScaffold = Color(0xFF0B0E11);
  static const Color _darkCard = Color(0xFF1F2937);
  static const Color _darkText = Color(0xFFE5E7EB);
  static const Color _darkDivider = Color(0xFF374151);
  static const Color _darkBorder = Color(0xFF374151);
  
  // Common
  static const Color buyColor = Color(0xFF10b981); // green
  static const Color sellColor = Color(0xFFef4444); // red
  static const Color primaryBlue = Color(0xFF3B82F6);
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        primary: primaryBlue,
        surface: _lightCard,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: _lightScaffold,
      
      // Card
      cardTheme: CardThemeData(
        color: _lightCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: _lightCard,
        foregroundColor: _lightText,
        elevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _lightText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Text
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: _lightText),
        bodyMedium: TextStyle(color: _lightText),
        bodySmall: TextStyle(color: _lightText.withOpacity(0.7)),
        titleLarge: TextStyle(color: _lightText, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: _lightText, fontWeight: FontWeight.w600),
        labelLarge: TextStyle(color: _lightText),
      ),
      
      // Divider
      dividerTheme: DividerThemeData(
        color: _lightDivider,
        thickness: 1,
      ),
      
      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
      ),
      
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.dark,
        primary: primaryBlue,
        surface: _darkCard,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: _darkScaffold,
      
      // Card
      cardTheme: CardThemeData(
        color: _darkCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: _darkCard,
        foregroundColor: _darkText,
        elevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _darkText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Text
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: _darkText),
        bodyMedium: TextStyle(color: _darkText),
        bodySmall: TextStyle(color: _darkText.withOpacity(0.7)),
        titleLarge: TextStyle(color: _darkText, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: _darkText, fontWeight: FontWeight.w600),
        labelLarge: TextStyle(color: _darkText),
      ),
      
      // Divider
      dividerTheme: DividerThemeData(
        color: _darkDivider,
        thickness: 1,
      ),
      
      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkScaffold,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
      ),
      
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
