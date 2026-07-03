import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF070A13);
  static const surface = Color(0xFF101522);
  static const elevated = Color(0xFF171D2E);
  static const electricPurple = Color(0xFFA855F7);
  static const neonCyan = Color(0xFF06B6D4);
  static const softBlue = Color(0xFF3B82F6);
  static const pinkAccent = Color(0xFFEC4899);
  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFF94A3B8);
  static const success = Color(0xFF34D399);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFF87171);

  static const primaryGradient = LinearGradient(
    colors: [electricPurple, softBlue, neonCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const glowGradient = LinearGradient(
    colors: [electricPurple, neonCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
