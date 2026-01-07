import 'package:flutter/material.dart';
class HoloCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final bool enableShader;
  const HoloCard({
    super.key,
    required this.child,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.all(2.0),
    this.enableShader = true,
  });
  @override
  State<HoloCard> createState() => _HoloCardState();
}
class _HoloCardState extends State<HoloCard>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final outer = cs.surface;
    final inner =
        Color.lerp(cs.surface, cs.onSurface, isDark ? 0.05 : 0.03) ??
        cs.surface;
    final shadow = Colors.black.withValues(alpha: isDark ? 0.40 : 0.10);
    final highlight = Colors.white.withValues(alpha: isDark ? 0.03 : 0.25);
    final outline = cs.outline.withValues(alpha: isDark ? 0.65 : 0.50);
    return Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: outline, width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(outer, Colors.white, isDark ? 0.03 : 0.10) ?? outer,
            Color.lerp(outer, Colors.black, isDark ? 0.10 : 0.04) ?? outer,
          ],
        ),
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 16, offset: const Offset(0, 10)),
          BoxShadow(
            color: highlight,
            blurRadius: 0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius - 2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: inner,
            borderRadius: BorderRadius.circular(widget.borderRadius - 2),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

