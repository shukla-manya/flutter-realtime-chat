import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF5B5FEF);
  static const secondary = Color(0xFF8B5CF6);
  static const accent = Color(0xFF22D3EE);
  static const darkBackground = Color(0xFF0B1020);
  static const darkSurface = Color(0xFF151B2E);
  static const lightBackground = Color(0xFFF7F8FC);
  static const white = Color(0xFFFFFFFF);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const textDark = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);

  static const primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
