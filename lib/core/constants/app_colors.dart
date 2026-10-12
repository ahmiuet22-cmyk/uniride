import 'package:flutter/material.dart';

class AppColors {
  // Official UET Academic Navy Blues
  static const Color primaryBlue = Color(0xFF0A2240); // Deep UET Navy Blue
  static const Color secondaryBlue = Color(0xFF1D3E6E); // Mid Navy Slate
  static const Color lightBlue = Color(0xFFF0F4FA); // Soft Pale Ice Blue
  static const Color blueAccentSurface = Color(0xFFE4EDF8); // Gentle Navy Tint

  // Official UET Emblem Yellow (Exact match from University Logo & Bus Livery)
  static const Color goldAccent = Color(0xFFFED136); // Exact UET Logo Canary Yellow (#FED136)
  static const Color goldDark = Color(0xFF8C6600); // High-contrast readable gold for text on light pills
  static const Color goldLight = Color(0xFFFFF9DB); // Soft UET emblem inner disc background tint
  static const Color goldBorder = Color(0xFFFED136); // Exact UET Yellow border
  static const Color goldGradientStart = Color(0xFFFFDE59);
  static const Color goldGradientEnd = Color(0xFFF5BE18);

  // Background & Surface
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFE2E8F0);

  // Typography Colors
  static const Color primaryText = Color(0xFF0B192C);
  static const Color secondaryText = Color(0xFF475569);
  static const Color mutedText = Color(0xFF94A3B8);

  // Status Colors (Harmonized with UET Navy & Gold)
  static const Color success = Color(0xFF0A2240);
  static const Color successLight = Color(0xFFF0F4FA);
  static const Color warning = Color(0xFFFED136);
  static const Color warningLight = Color(0xFFFFF9DB);
  static const Color danger = Color(0xFF0A2240);
  static const Color dangerLight = Color(0xFFF0F4FA);
  static const Color info = Color(0xFF1D3E6E);
  static const Color infoLight = Color(0xFFF0F4FA);

  // Shadows
  static const BoxShadow softShadow = BoxShadow(
    color: Color(0x0E0A2240),
    blurRadius: 16,
    offset: Offset(0, 4),
    spreadRadius: 0,
  );

  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x080A2240),
    blurRadius: 12,
    offset: Offset(0, 2),
    spreadRadius: 0,
  );

  static const BoxShadow blueGlow = BoxShadow(
    color: Color(0x280A2240),
    blurRadius: 18,
    offset: Offset(0, 6),
    spreadRadius: 2,
  );
}
