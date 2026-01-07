import 'package:flutter/material.dart';

class CinematicBackground extends StatefulWidget {
  final Widget child;
  const CinematicBackground({super.key, required this.child});

  @override
  State<CinematicBackground> createState() => _CinematicBackgroundState();
}

class _CinematicBackgroundState extends State<CinematicBackground>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgA = Theme.of(context).scaffoldBackgroundColor;
    final bgB = isDark
        ? bgA
        : (Color.lerp(bgA, cs.surface, 0.16) ?? cs.surface);

    return Stack(
      children: [
        // Base: pure matte charcoal in dark mode; soft paper wash in light.
        Container(
          decoration: isDark
              ? BoxDecoration(color: bgA)
              : BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [bgA, bgB, bgA],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
        ),

        // Subtle matte grain (large surface only)
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: isDark ? 0.10 : 0.045,
              child: CustomPaint(
                painter: _StoneGrainPainter(color: cs.onSurface),
                size: Size.infinite,
              ),
            ),
          ),
        ),

        SafeArea(child: widget.child),
      ],
    );
  }
}

class _StoneGrainPainter extends CustomPainter {
  final Color color;

  _StoneGrainPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.07);
    // Deterministic speckle: cheap, stable, and subtle.
    for (int i = 0; i < 2200; i++) {
      final dx = (i * 13.0) % size.width;
      final dy = (i * 7.0) % size.height;

      final radius = (i % 7 == 0) ? 1.3 : 0.9;
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
