import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF070A13);
  static const surface = Color(0xFF101522);
  static const elevated = Color(0xFF171D2E);
  static const purple = Color(0xFFA855F7);
  static const cyan = Color(0xFF06B6D4);
  static const blue = Color(0xFF3B82F6);
  static const pink = Color(0xFFEC4899);
  static const electricPurple = purple;
  static const neonCyan = cyan;
  static const softBlue = blue;
  static const pinkAccent = pink;
  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFF94A3B8);
  static const success = Color(0xFF34D399);
  static const error = Color(0xFFF87171);
  static const warning = Color(0xFFF59E0B);

  static const primaryGradient = LinearGradient(
    colors: [purple, blue, cyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const glowGradient = LinearGradient(
    colors: [purple, cyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
