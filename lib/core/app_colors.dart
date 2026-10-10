import 'package:flutter/material.dart';

/// Centralized color palette for AlgoKids
class AppColors {
  AppColors._();

  // Primary brand colors
  static const Color primary = Color(0xFF4361EE);
  static const Color primaryDark = Color(0xFF3A0CA3);
  static const Color secondary = Color(0xFF4CC9F0);
  static const Color accent = Color(0xFF7209B7);

  // Backgrounds & Neutrals
  static const Color background = Color(0xFFF1F5F9);
  static const Color surface = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);

  // Game Elements
  static const Color starGold = Color(0xFFFFB703);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFFB8500);
  static const Color dangerRed = Color(0xFFEF4444);

  // Command Block Colors
  static const Color cmdForward = Color(0xFF3B82F6);
  static const Color cmdTurnRight = Color(0xFF8B5CF6);
  static const Color cmdTurnLeft = Color(0xFFF97316);
  static const Color cmdLoop = Color(0xFFEAB308);
  static const Color cmdCondition = Color(0xFFEC4899);
  static const Color cmdFunction = Color(0xFF6366F1);

  // Age Modes
  static const Color ageMini = Color(0xFFFF9800);
  static const Color ageExplorer = Color(0xFF4361EE);
  static const Color ageMaster = Color(0xFF7209B7);
}
