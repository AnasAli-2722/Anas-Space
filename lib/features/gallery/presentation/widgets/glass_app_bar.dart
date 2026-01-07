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
    final base = Theme.of(context).scaffoldBackgroundColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExtrudedSurface(
        radius: 20,
        depth: 10,
        color: base,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // 1. LEADING ICON
            if (leading != null) ...[leading!, const SizedBox(width: 15)],

            // 2. DRAGGABLE TITLE AREA
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

              // Minimize
              _WindowButton(
                icon: Icons.remove,
                color: cs.onSurface,
                onTap: () async => await windowManager.minimize(),
              ),
              // Maximize / Restore
              _WindowButton(
                icon: Icons.crop_square,
                color: cs.onSurface,
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

  const _WindowButton({
    required this.icon,
    required this.onTap,
    required this.color,
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
      depth: 5,
      iconColor: isClose ? cs.error : cs.onSurface.withValues(alpha: 0.85),
      surfaceColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }
}
