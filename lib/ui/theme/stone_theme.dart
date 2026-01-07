import 'package:flutter/material.dart';

class StoneThemes {
  static const _seed = Color(0xFF5B6772);

  // Light: off-white background and slightly warm surfaces (muted, not yellow)
  static const Color _paperBg = Color(0xFFFAF9F7);
  static const Color _paperSurface = Color(0xFFF1ECE6);

  // Dark: matte charcoal
  static const Color _charcoalBg = Color(0xFF111212);
  static const Color _charcoalSurface = Color(0xFF161717);

  static ThemeData get light {
    final base = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    );

    final scheme = base.copyWith(
      surface: _paperSurface,
      primary: const Color(0xFF556673),
      secondary: const Color(0xFF6F6B63),
      tertiary: const Color(0xFF7A6A57),
      outline: const Color.fromARGB(255, 206, 189, 162),
      shadow: const Color(0xFF000000),
      surfaceTint: Colors.transparent,
      onSurface: const Color(0xFF1D1B18),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Segoe UI',
      colorScheme: scheme,
      scaffoldBackgroundColor: _paperBg,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: 0.35),
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static ThemeData get dark {
    final base = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );

    final scheme = base.copyWith(
      surface: _charcoalSurface,
      primary: const Color(0xFF8A97A3),
      secondary: const Color(0xFF9A9182),
      tertiary: const Color(0xFFA28C78),
      outline: const Color(0xFF2F3234),
      shadow: const Color(0xFF000000),
      surfaceTint: Colors.transparent,
      onSurface: const Color(0xFFEAE5DA),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Segoe UI',
      colorScheme: scheme,
      scaffoldBackgroundColor: _charcoalBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: _charcoalSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _charcoalSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      cardTheme: CardThemeData(
        color: _charcoalSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static Color rippleFillFor(ThemeMode targetMode) {
    switch (targetMode) {
      case ThemeMode.light:
        return _paperBg;
      case ThemeMode.dark:
        return _charcoalBg;
      case ThemeMode.system:
        // You are not using system mode right now; treat as dark.
        return _charcoalBg;
    }
  }
}
