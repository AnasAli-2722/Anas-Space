import 'package:flutter/material.dart';
import '../helpers/shadow_helpers.dart';

class GlitchText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double glitchIntensity;

  const GlitchText({
    super.key,
    required this.text,
    this.style,
    this.glitchIntensity = 1.0,
  });

  @override
  State<GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<GlitchText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Text(widget.text, style: widget.style);
      },
    );
  }
}

class NeonBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double borderWidth;
  final double borderRadius;
  final bool animate;

  const NeonBorder({
    super.key,
    required this.child,
    this.color = const Color(0xFF00F5FF),
    this.borderWidth = 2.0,
    this.borderRadius = 12.0,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: color, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 10.0,
            spreadRadius: 2.0,
          ),
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20.0,
            spreadRadius: 4.0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        child: child,
      ),
    );
  }
}

class CyberpunkButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color color;
  final double borderRadius;

  const CyberpunkButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color = const Color(0xFF00F5FF),
    this.borderRadius = 8.0,
  });

  @override
  State<CyberpunkButton> createState() => _CyberpunkButtonState();
}

class _CyberpunkButtonState extends State<CyberpunkButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: widget.color, width: 2.0),
          gradient: LinearGradient(
            colors: [
              widget.color.withOpacity(_isPressed ? 0.3 : 0.1),
              widget.color.withOpacity(_isPressed ? 0.2 : 0.05),
            ],
          ),
          boxShadow: _isPressed
              ? []
              : [
                  subtleBoxShadow(
                    context,
                    color: widget.color,
                    lightAlpha: 0.5,
                    darkAlpha: 0.12,
                    lightBlur: 15.0,
                    darkBlur: 6.0,
                    lightOffset: const Offset(0, 6),
                    darkOffset: const Offset(0, 2),
                    lightSpread: 2.0,
                    darkSpread: 0.0,
                  ),
                ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: widget.child,
      ),
    );
  }
}
