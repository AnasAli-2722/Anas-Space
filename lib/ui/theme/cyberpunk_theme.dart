import 'package:flutter/material.dart';
class CyberpunkTheme {
  static const Color neonCyan = Color(0xFF00F5FF);
  static const Color neonMagenta = Color(0xFFFF00FF);
  static const Color neonPurple = Color(0xFFAA00FF);
  static const Color neonPink = Color(0xFFFF006E);
  static const Color darkBg = Color(0xFF0A0A0F);
  static const Color darkBgSecondary = Color(0xFF1A1A24);
  static const Color darkBgTertiary = Color(0xFF2A2A3A);
  static const Color glassOverlay = Color(0x40FFFFFF);
  static const double glassBlur = 10.0;
  static const double glassOpacity = 0.15;
  static const double glowIntensity = 0.8;
  static const double scanlineSpeed = 2.0; // pixels per second
  static const double glitchIntensityMax = 1.0;
  static const double glitchIntensityMin = 0.0;
  static const Duration glitchStabilizeDuration = Duration(seconds: 2);
  static const Duration splashDisplayDuration = Duration(seconds: 3);
  static const Duration transitionDuration = Duration(milliseconds: 800);
  static const double neonBorderWidth = 2.0;
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  static List<BoxShadow> neonGlow(Color color, {double intensity = 1.0}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: color.a * 0.6 * intensity),
        blurRadius: 20.0,
        spreadRadius: 2.0,
      ),
      BoxShadow(
        color: color.withValues(alpha: color.a * 0.3 * intensity),
        blurRadius: 40.0,
        spreadRadius: 4.0,
      ),
    ];
  }
  static LinearGradient holographicGradient({
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: [
        neonCyan.withValues(alpha: neonCyan.a * 0.4),
        neonMagenta.withValues(alpha: neonMagenta.a * 0.4),
        neonPurple.withValues(alpha: neonPurple.a * 0.4),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }
  static const TextStyle glitchTitle = TextStyle(
    fontSize: 48.0,
    fontWeight: FontWeight.bold,
    color: neonCyan,
    letterSpacing: 4.0,
    shadows: [
      Shadow(color: neonCyan, blurRadius: 20.0),
      Shadow(color: neonMagenta, offset: Offset(2, 2), blurRadius: 10.0),
    ],
  );
  static const TextStyle cyberpunkBody = TextStyle(
    fontSize: 14.0,
    color: Color(0xFFE0E0E0),
    letterSpacing: 0.5,
  );
  static const TextStyle cyberpunkCaption = TextStyle(
    fontSize: 12.0,
    color: Color(0xFFB0B0B0),
    letterSpacing: 0.3,
  );
}

