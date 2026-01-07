import 'package:flutter/material.dart';

Color _shiftLightness(Color color, double delta) {
  final hsl = HSLColor.fromColor(color);
  final next = (hsl.lightness + delta).clamp(0.0, 1.0).toDouble();
  return hsl.withLightness(next).toColor();
}

class ExtrudedSurface extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double depth;
  final Color? color;
  final bool pressed;

  const ExtrudedSurface({
    super.key,
    required this.child,
    this.onTap,
    this.padding = EdgeInsets.zero,
    this.radius = 16,
    this.depth = 8,
    this.color,
    this.pressed = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = color ?? theme.scaffoldBackgroundColor;

    // Keep everything monochrome by deriving highlight/shadow from the base.
    final highlight = _shiftLightness(
      base,
      theme.brightness == Brightness.dark ? 0.10 : 0.06,
    ).withValues(alpha: theme.brightness == Brightness.dark ? 0.75 : 0.55);
    final shade = _shiftLightness(
      base,
      theme.brightness == Brightness.dark ? -0.14 : -0.10,
    ).withValues(alpha: theme.brightness == Brightness.dark ? 0.75 : 0.28);

    final dx = pressed ? -depth : depth;
    final dy = pressed ? -depth : depth;

    final decoration = BoxDecoration(
      color: base,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: highlight,
          blurRadius: depth * 2.2,
          offset: Offset(-dx, -dy),
        ),
        BoxShadow(
          color: shade,
          blurRadius: depth * 2.2,
          offset: Offset(dx, dy),
        ),
      ],
    );

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}

class ExtrudedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double radius;
  final double depth;
  final Color? iconColor;
  final Color? surfaceColor;

  const ExtrudedIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 40,
    this.radius = 14,
    this.depth = 6,
    this.iconColor,
    this.surfaceColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: size,
      height: size,
      child: ExtrudedSurface(
        onTap: onTap,
        radius: radius,
        depth: depth,
        color: surfaceColor,
        child: Center(
          child: Icon(
            icon,
            size: size * 0.48,
            color: iconColor ?? cs.onSurface.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}
