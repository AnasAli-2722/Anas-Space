import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/theme_cubit.dart';

class StoneThemeSwitch extends StatefulWidget {
  const StoneThemeSwitch({super.key});
  @override
  State<StoneThemeSwitch> createState() => _StoneThemeSwitchState();
}

class _StoneThemeSwitchState extends State<StoneThemeSwitch> {
  final GlobalKey _key = GlobalKey();

  Offset _thumbCenterGlobal({required bool isDark}) {
    final ctx = _key.currentContext;
    if (ctx == null) return Offset.zero;
    final renderObject = ctx.findRenderObject();
    if (renderObject is! RenderBox) return Offset.zero;
    final topLeft = renderObject.localToGlobal(Offset.zero);
    final size = renderObject.size;
    final thumbCenterLocal = Offset(
      isDark ? (size.width - size.height / 2) : (size.height / 2),
      size.height / 2,
    );
    return topLeft + thumbCenterLocal;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.select<ThemeCubit, bool>((c) {
      final pending = c.state.pendingRipple;
      if (pending != null) return pending.targetMode == ThemeMode.dark;
      return c.state.themeMode == ThemeMode.dark;
    });
    final cs = Theme.of(context).colorScheme;
    final track = cs.surface;
    final outline = cs.outline.withValues(alpha: 0.75);
    final thumbBase = Color.lerp(cs.surface, cs.onSurface, 0.06) ?? cs.surface;
    final thumbShadow = Colors.black.withValues(alpha: 0.45);

    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            HapticFeedback.lightImpact();
            final origin = _thumbCenterGlobal(isDark: isDark);
            context.read<ThemeCubit>().requestToggle(origin: origin);
          },
          child: Container(
            key: _key,
            width: 58,
            height: 34,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: outline, width: 1),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(track, Colors.white, isDark ? 0.02 : 0.12) ??
                      track,
                  Color.lerp(track, Colors.black, isDark ? 0.18 : 0.06) ??
                      track,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: isDark ? 0.03 : 0.35),
                  blurRadius: 0,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: AnimatedAlign(
              alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(thumbBase, Colors.white, 0.22) ?? thumbBase,
                      Color.lerp(
                            thumbBase,
                            Colors.black,
                            isDark ? 0.18 : 0.08,
                          ) ??
                          thumbBase,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: thumbShadow,
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: outline.withValues(alpha: 0.55),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: RotationTransition(
                            turns: Tween<double>(
                              begin: isDark ? -0.25 : 0.25,
                              end: 0.0,
                            ).animate(animation),
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.5, end: 1.0)
                                  .animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.elasticOut,
                                    ),
                                  ),
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: Icon(
                        isDark
                            ? Icons.nights_stay_rounded
                            : Icons.wb_sunny_rounded,
                        key: ValueKey<bool>(isDark),
                        size: 16,
                        color: cs.onSurface.withValues(
                          alpha: isDark ? 0.85 : 0.65,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
