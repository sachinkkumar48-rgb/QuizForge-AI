import 'package:flutter/material.dart';

/// Color tokens and ColorScheme definitions for QuizForge AI Material 3 theme.
abstract class AppColors {
  // Brand Primary
  static const Color primaryLight = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF90CAF9);

  // Secondary
  static const Color secondaryLight = Color(0xFF00897B);
  static const Color secondaryDark = Color(0xFF80CBC4);

  // Surface & Background - Light
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFEFEFEF);

  // Surface & Background - Dark
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariantDark = Color(0xFF2C2C2C);

  // Status & Messaging
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);

  /// Light ColorScheme
  static const ColorScheme lightColorScheme = ColorScheme.light(
    primary: primaryLight,
    secondary: secondaryLight,
    surface: surfaceLight,
    surfaceContainerHighest: surfaceVariantLight,
    error: error,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Color(0xFF212121),
    onError: Colors.white,
  );

  /// Dark ColorScheme
  static const ColorScheme darkColorScheme = ColorScheme.dark(
    primary: primaryDark,
    secondary: secondaryDark,
    surface: surfaceDark,
    surfaceContainerHighest: surfaceVariantDark,
    error: error,
    onPrimary: Color(0xFF00325B),
    onSecondary: Color(0xFF003731),
    onSurface: Color(0xFFE0E0E0),
    onError: Colors.black,
  );
}
