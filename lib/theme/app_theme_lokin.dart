import 'package:flutter/material.dart';

import '../core/constants/app_colors_lokin.dart';

class AppThemeLokin {
  static ThemeData lightTheme = ThemeData(
    primarySwatch: MaterialColor(
      AppColorsLokin.primary.value,
      <int, Color>{
        50: AppColorsLokin.primary.withOpacity(0.1),
        100: AppColorsLokin.primary.withOpacity(0.2),
        200: AppColorsLokin.primary.withOpacity(0.3),
        300: AppColorsLokin.primary.withOpacity(0.4),
        400: AppColorsLokin.primary.withOpacity(0.5),
        500: AppColorsLokin.primary,
        600: AppColorsLokin.primary.withOpacity(0.7),
        700: AppColorsLokin.primary.withOpacity(0.8),
        800: AppColorsLokin.primary.withOpacity(0.9),
        900: AppColorsLokin.primary,
      },
    ),
    primaryColor: AppColorsLokin.primary,
    scaffoldBackgroundColor: AppColorsLokin.background,
    colorScheme: const ColorScheme.light(
      primary: AppColorsLokin.primary,
      secondary: AppColorsLokin.accent,
      surface: AppColorsLokin.surface,
      error: AppColorsLokin.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColorsLokin.textPrimary,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColorsLokin.primary,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorsLokin.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColorsLokin.primary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColorsLokin.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColorsLokin.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColorsLokin.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColorsLokin.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: AppColorsLokin.textSecondary),
    ),
    cardTheme: CardThemeData(
      color: AppColorsLokin.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColorsLokin.border,
      thickness: 1,
    ),
    iconTheme: const IconThemeData(
      color: AppColorsLokin.textPrimary,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColorsLokin.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColorsLokin.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColorsLokin.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColorsLokin.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColorsLokin.textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColorsLokin.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppColorsLokin.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColorsLokin.textPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: AppColorsLokin.textSecondary,
      ),
    ),
    useMaterial3: true,
  );

  static ThemeData darkTheme = ThemeData(
    primarySwatch: MaterialColor(
      AppColorsLokin.primary.value,
      <int, Color>{
        50: AppColorsLokin.primary.withOpacity(0.1),
        100: AppColorsLokin.primary.withOpacity(0.2),
        200: AppColorsLokin.primary.withOpacity(0.3),
        300: AppColorsLokin.primary.withOpacity(0.4),
        400: AppColorsLokin.primary.withOpacity(0.5),
        500: AppColorsLokin.primary,
        600: AppColorsLokin.primary.withOpacity(0.7),
        700: AppColorsLokin.primary.withOpacity(0.8),
        800: AppColorsLokin.primary.withOpacity(0.9),
        900: AppColorsLokin.primary,
      },
    ),
    primaryColor: AppColorsLokin.primary,
    scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    colorScheme: ColorScheme.dark(
      primary: AppColorsLokin.primary,
      secondary: AppColorsLokin.accent,
      surface: const Color(0xFF2A2A2A),
      error: AppColorsLokin.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onError: Colors.white,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2A2A2A),
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorsLokin.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColorsLokin.primary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColorsLokin.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColorsLokin.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: Colors.grey[500]),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF2A2A2A),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF3A3A3A),
      thickness: 1,
    ),
    iconTheme: const IconThemeData(
      color: Colors.white,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: Colors.grey,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF2A2A2A),
      selectedItemColor: AppColorsLokin.primary,
      unselectedItemColor: Colors.grey,
    ),
    useMaterial3: true,
  );
}
