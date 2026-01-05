import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:math';

class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      color: Colors.black,
      child: Row(
        children: [
          Expanded(
            child: DragToMoveArea(
              child: Container(
                padding: const EdgeInsets.only(left: 16),
                alignment: Alignment.centerLeft,
                child: const Text(
                  "Anas Space",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          WindowCaptionButton.minimize(),
          WindowCaptionButton.maximize(),
          WindowCaptionButton.close(),
        ],
      ),
    );
  }
}

class WindowCaptionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isClose;
  WindowCaptionButton.minimize({super.key})
    : icon = Icons.remove,
      onPressed = windowManager.minimize,
      isClose = false;
  WindowCaptionButton.maximize({super.key})
    : icon = Icons.crop_square,
      onPressed = _toggleMax,
      isClose = false;
  WindowCaptionButton.close({super.key})
    : icon = Icons.close,
      onPressed = windowManager.close,
      isClose = true;
  static void _toggleMax() async {
    if (await windowManager.isMaximized()) {
      windowManager.unmaximize();
    } else {
      windowManager.maximize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        hoverColor: isClose
            ? const Color(0xFFE81123)
            : Colors.white.withOpacity(0.2),
        child: Container(
          width: 46,
          height: double.infinity,
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}

class GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random = Random();
    for (int i = 0; i < 40000; i++) {
      paint.color = Colors.white.withOpacity(random.nextDouble() * 0.02);
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        0.7,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
