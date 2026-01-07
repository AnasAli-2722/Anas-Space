import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:anas_space/ui/widgets/extruded_surface.dart';
class GlassAppBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  const GlassAppBar({
    super.key,
    required this.title,
    this.subtitle = "",
    this.actions,
    this.leading,
  });
  @override
  Widget build(BuildContext context) {
    final isDesktop = Platform.isWindows;
    final cs = Theme.of(context).colorScheme;
    final baseSurface = cs.surface;
    Color surfaceColor = baseSurface;
    if (Theme.of(context).brightness == Brightness.light) {
      final hsl = HSLColor.fromColor(baseSurface);
      surfaceColor = hsl
          .withHue((hsl.hue + 8) % 360)
          .withSaturation((hsl.saturation + 0.02).clamp(0.0, 1.0))
          .withLightness((hsl.lightness - 0.02).clamp(0.0, 1.0))
          .toColor();
    }
    final brightness = Theme.of(context).brightness;
    final double intensity = brightness == Brightness.light ? 2.0 : 1.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExtrudedSurface(
        radius: 20,
        depth: brightness == Brightness.light ? 12 : 10,
        intensity: intensity,
        extraShadow: brightness == Brightness.light,
        color: surfaceColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 15)],
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent, // Catch all touches
                onPanStart: (details) {
                  if (isDesktop) {
                    windowManager.startDragging(); // 👈 2. Native Drag Magic
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 1.8,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.65),
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (actions != null) ...actions!,
            if (isDesktop) ...[
              const SizedBox(width: 20),
              Container(
                height: 20,
                width: 1.5,
                decoration: BoxDecoration(
                  color: cs.outline.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 10),
              _WindowButton(
                icon: Icons.remove,
                color: cs.onSurface,
                depth: brightness == Brightness.light ? 8 : 5,
                onTap: () async => await windowManager.minimize(),
              ),
              _WindowButton(
                icon: Icons.crop_square,
                color: cs.onSurface,
                depth: brightness == Brightness.light ? 8 : 5,
                onTap: () async {
                  if (await windowManager.isMaximized()) {
                    windowManager.unmaximize();
                  } else {
                    windowManager.maximize();
                  }
                },
              ),
              _WindowButton(
                icon: Icons.close,
                color: cs.error,
                depth: brightness == Brightness.light ? 8 : 5,
                onTap: () async => await windowManager.close(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
class _WindowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final double depth;
  const _WindowButton({
    required this.icon,
    required this.onTap,
    required this.color,
    this.depth = 5,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isClose = color == cs.error;
    return ExtrudedIconButton(
      icon: icon,
      onTap: onTap,
      size: 34,
      radius: 10,
      depth: depth,
      iconColor: isClose ? cs.error : cs.onSurface.withValues(alpha: 0.85),
      surfaceColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }
}

