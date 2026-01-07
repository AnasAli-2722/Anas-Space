import 'package:flutter/material.dart';
BoxShadow subtleBoxShadow(
  BuildContext context, {
  Color? color,
  double lightAlpha = 0.18,
  double darkAlpha = 0.06,
  double lightBlur = 18.0,
  double darkBlur = 6.0,
  Offset lightOffset = const Offset(0, 10),
  Offset darkOffset = const Offset(0, 2),
  double lightSpread = 0.0,
  double darkSpread = 0.0,
}) {
  final brightness = Theme.of(context).brightness;
  final isDark = brightness == Brightness.dark;
  final base = color ?? Theme.of(context).colorScheme.shadow;
  final alpha = isDark ? darkAlpha : lightAlpha;
  return BoxShadow(
    color: base.withValues(alpha: base.a * alpha),
    blurRadius: isDark ? darkBlur : lightBlur,
    offset: isDark ? darkOffset : lightOffset,
    spreadRadius: isDark ? darkSpread : lightSpread,
  );
}

