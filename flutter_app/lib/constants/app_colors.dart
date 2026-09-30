import 'package:flutter/material.dart';

class AppColors {
  // Primary Brands - Modern Automotive Electric Blue & Deep Navy
  static const Color primary = Color(0xFF0075FF); // Automotive Electric Blue
  static const Color primaryDark = Color(0xFF0056C6);
  static const Color primaryLight = Color(0xFFE0EFFF);

  // Accents
  static const Color secondary = Color(0xFF0F172A); // Deep Navy Slate
  static const Color accent = Color(0xFFF59E0B); // Amber Yellow
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color error = Color(0xFFEF4444); // Vibrant Red
  static const Color info = Color(0xFF0284C7); // Sky Blue

  // Neutrals
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // Typography
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0075FF), Color(0xFF0056C6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
