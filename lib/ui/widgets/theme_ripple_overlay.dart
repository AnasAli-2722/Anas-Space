import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/theme_cubit.dart';
import '../theme/stone_theme.dart';

class ThemeRippleOverlay extends StatefulWidget {
  final Widget child;

  const ThemeRippleOverlay({super.key, required this.child});

  @override
  State<ThemeRippleOverlay> createState() => _ThemeRippleOverlayState();
}

class _ThemeRippleOverlayState extends State<ThemeRippleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  ThemeRippleRequest? _active;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startRipple(ThemeRippleRequest request) {
    _active = request;
    _controller
      ..stop()
      ..value = 0;

    _controller.forward().whenComplete(() {
      if (!mounted) return;
      final active = _active;
      if (active == null) return;
      context.read<ThemeCubit>().commitToggle(active.id);
      setState(() {
        _active = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ThemeCubit, ThemeState>(
      listenWhen: (prev, next) => prev.pendingRipple != next.pendingRipple,
      listener: (context, state) {
        final request = state.pendingRipple;
        if (request == null) return;
        _startRipple(request);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_active != null)
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: CustomPaint(
                  painter: _ThemeRipplePainter(
                    repaint: _controller,
                    origin: _active!.origin,
                    fillColor: StoneThemes.rippleFillFor(_active!.targetMode),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThemeRipplePainter extends CustomPainter {
  final Listenable repaint;
  final Offset origin;
  final Color fillColor;

  _ThemeRipplePainter({
    required this.repaint,
    required this.origin,
    required this.fillColor,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final t = (repaint as Animation<double>).value;

    final maxRadius = _maxDistanceToCorners(origin, size);
    final radius = uiEaseOutCubic(t) * maxRadius;

    final rect = Offset.zero & size;

    // Feathered edge (matte, no glow): radial gradient with a soft falloff.
    final gradient = RadialGradient(
      center: Alignment(
        (origin.dx / size.width) * 2 - 1,
        (origin.dy / size.height) * 2 - 1,
      ),
      radius: (radius / maxRadius).clamp(0.0, 1.0),
      colors: [fillColor, fillColor, fillColor.withValues(alpha: 0.0)],
      stops: const [0.0, 0.98, 1.0],
    );

    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _ThemeRipplePainter oldDelegate) {
    return oldDelegate.origin != origin || oldDelegate.fillColor != fillColor;
  }

  static double _maxDistanceToCorners(Offset o, Size size) {
    final corners = <Offset>[
      Offset(0, 0),
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];

    double maxD = 0;
    for (final c in corners) {
      final dx = o.dx - c.dx;
      final dy = o.dy - c.dy;
      final d = math.sqrt(dx * dx + dy * dy);
      if (d > maxD) maxD = d;
    }
    return maxD;
  }

  static double uiEaseOutCubic(double t) {
    final p = 1 - t;
    return 1 - p * p * p;
  }
}
