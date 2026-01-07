import 'package:flutter/material.dart';
import '../../features/gallery/presentation/pages/dashboard_page.dart';
import '../../features/gallery/data/gallery_service.dart';
import '../../features/gallery/presentation/widgets/cinematic_background.dart';
class SplashScreen extends StatefulWidget {
  final GalleryService galleryService;
  const SplashScreen({super.key, required this.galleryService});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  static const _kFadeDuration = Duration(milliseconds: 450);
  static const _kHoldDuration = Duration(milliseconds: 650);
  static const _kTransitionDuration = Duration(milliseconds: 250);
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: _kFadeDuration,
      value: 0.0,
    );
    _startSequence();
  }
  void _startSequence() async {
    await _fadeController.forward();
    await Future.delayed(_kHoldDuration);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DashboardPage(galleryService: widget.galleryService),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: _kTransitionDuration,
      ),
    );
  }
  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildSplashContent());
  }
  Widget _buildSplashContent() {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        const Positioned.fill(
          child: CinematicBackground(child: SizedBox.shrink()),
        ),
        Center(
          child: FadeTransition(
            opacity: _fadeController,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "ANAS SPACE",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

