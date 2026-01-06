import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
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
                        windowManager
                            .startDragging(); // 👈 2. Native Drag Magic
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 2.0,
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 10,
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
                    width: 1,
                    color: Colors.white.withOpacity(0.2),
                  ), // Divider
                  const SizedBox(width: 10),

                  // Minimize
                  _WindowButton(
                    icon: Icons.remove,
                    onTap: () async => await windowManager.minimize(),
                  ),
                  // Maximize / Restore
                  _WindowButton(
                    icon: Icons.crop_square,
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
                    color: Colors.redAccent,
                    onTap: () async => await windowManager.close(),
                  ),
                ],
              ],
            ),
          ),
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
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18, color: color.withOpacity(0.8)),
      onPressed: onTap,
      splashRadius: 15,
      constraints: const BoxConstraints(minWidth: 35, minHeight: 35),
      padding: EdgeInsets.zero,
      tooltip: "Window Control",
    );
  }
}
