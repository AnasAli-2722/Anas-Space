import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui';

class CinematicBackground extends StatelessWidget {
  final Widget child;
  const CinematicBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF050505), Color(0xFF13131F), Color(0xFF000000)],
              stops: [0.0, 0.6, 1.0],
            ),
          ),
        ),

        IgnorePointer(
          child: Opacity(
            opacity: 0.03,
            child: CustomPaint(
              painter: _ProceduralNoisePainter(),
              size: Size.infinite,
            ),
          ),
        ),

        SafeArea(child: child),
      ],
    );
  }
}

class _ProceduralNoisePainter extends CustomPainter {
  final Random _random = Random();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    const double step = 4;

    final List<Offset> points = [];
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        if (_random.nextDouble() > 0.8) {
          points.add(
            Offset(
              x + _random.nextDouble() * step,
              y + _random.nextDouble() * step,
            ),
          );
        }
      }
    }

    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
