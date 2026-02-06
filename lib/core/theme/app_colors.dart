import 'package:flutter/material.dart';

/// App color palette based on the design system.
/// "Scientific Minimalism with Warmth" - dark-first with warm accents.
abstract class AppColors {
  // Primary Backgrounds
  static const Color backgroundPrimary = Color(0xFF0D0D0F);
  static const Color backgroundSecondary = Color(0xFF161619);
  static const Color backgroundTertiary = Color(0xFF1E1E22);
  static const Color backgroundQuaternary = Color(0xFF28282D);

  // Accent Colors
  static const Color accentGold = Color(0xFFE8A838);
  static const Color accentGoldMuted = Color(0xFFB8862D);
  static const Color accentGoldSubtle = Color(0x33E8A838); // 20% opacity

  // Semantic Colors
  static const Color completionGreen = Color(0xFF7DB87D);
  static const Color completionGreenSubtle = Color(0x337DB87D);
  static const Color twoMinuteBlue = Color(0xFF6B9BD2);
  static const Color twoMinuteBlueSubtle = Color(0x336B9BD2);
  static const Color skippedGray = Color(0xFF5A5A62);
  static const Color missedCoral = Color(0xFFD4726A);
  static const Color missedCoralSubtle = Color(0x33D4726A);

  // Text Hierarchy
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFFB0B0B8);
  static const Color textTertiary = Color(0xFF6E6E78);
  static const Color textInverse = Color(0xFF0D0D0F);

  // Borders & Dividers
  static const Color borderSubtle = Color(0xFF2A2A30);
  static const Color borderMedium = Color(0xFF3A3A42);
  static const Color borderFocus = Color(0xFFE8A838);

  // Habit Colors (User-Selectable)
  static const List<Color> habitPalette = [
    Color(0xFFE8A838), // Gold
    Color(0xFF7DB87D), // Sage
    Color(0xFF6B9BD2), // Sky
    Color(0xFFD4726A), // Coral
    Color(0xFFB088D4), // Lavender
    Color(0xFF5BC0BE), // Teal
    Color(0xFFE07B53), // Tangerine
    Color(0xFFC9B1FF), // Periwinkle
  ];

  // Heatmap Gradient (5 levels: 0%, 25%, 50%, 75%, 100%)
  static const List<Color> heatmapGradient = [
    Color(0xFF1E1E22), // No activity
    Color(0xFF2D3B2D), // Low
    Color(0xFF3D5A3D), // Medium-low
    Color(0xFF5A8A5A), // Medium-high
    Color(0xFF7DB87D), // High/complete
  ];
}
