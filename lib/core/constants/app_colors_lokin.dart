import 'package:flutter/material.dart';

class AppColorsLokin {
  // Primary Brand Colors
  static const Color primary = Color(0xFFCE0000); // Engineering Orange
  static const Color secondary = Color(0xFF3F2727); // Van Dyke
  static const Color accent = Color(0xFFF85757); // Bittersweet

  // Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color darkSurface = Color(0xFF2D2D2D);

  // Text Colors
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textLight = Color(0xFFBDC3C7);
  static const Color textDark = Color(0xFF34495E);

  // Status Colors
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // Neutral Colors
  static const Color border = Color(0xFFE1E8ED);
  static const Color divider = Color(0xFFECF0F1);
  static const Color shadow = Color(0x1A000000);
  static const Color overlay = Color(0x80000000);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [secondary, Color(0xFF4A2C2A)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, Color(0xFF2ECC71)],
  );

  // Map Colors
  static const Color mapPrimary = Color(0xFF1976D2);
  static const Color mapAccent = Color(0xFF42A5F5);

  // Special Effect Colors
  static const Color shimmerBase = Color(0xFFE1E8ED);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // Chart Colors
  static const List<Color> chartColors = [
    primary,
    accent,
    info,
    success,
    warning,
    Color(0xFF9B59B6),
    Color(0xFF1ABC9C),
    Color(0xFFE67E22),
  ];

  // Attendance Status Colors
  static const Color attendancePresent = success;
  static const Color attendanceAbsent = error;
  static const Color attendancePermission = warning;
  static const Color attendanceLate = Color(0xFFFF6B35);

  // Button Variants
  static const Color buttonPrimary = primary;
  static const Color buttonSecondary = secondary;
  static const Color buttonSuccess = success;
  static const Color buttonWarning = warning;
  static const Color buttonError = error;
  static const Color buttonInfo = info;

  // Social Colors (if needed)
  static const Color google = Color(0xFFDB4437);
  static const Color facebook = Color(0xFF4267B2);
  static const Color twitter = Color(0xFF1DA1F2);

  // Helper method to get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  // Helper method to get lighter shade
  static Color lighter(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  // Helper method to get darker shade
  static Color darker(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}
