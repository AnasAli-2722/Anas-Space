import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:window_manager/window_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'ui/pages/splash_screen.dart';
import 'core/theme/theme_cubit.dart';
import 'features/gallery/data/gallery_service.dart';
import 'features/sync/data/sync_repository_impl.dart';
import 'features/sync/presentation/cubit/sync_cubit.dart';
import 'ui/theme/stone_theme.dart';
import 'ui/widgets/theme_ripple_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isDesktop = !kIsWeb && Platform.isWindows;
  if (isDesktop) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      minimumSize: Size(400, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  PaintingBinding.instance.imageCache.maximumSizeBytes = isDesktop
      ? 500 * 1024 * 1024
      : 150 * 1024 * 1024;
  final galleryService = GalleryService();
  final syncRepo = SyncRepositoryImpl(galleryService: galleryService);
  runApp(AnasSpaceApp(galleryService: galleryService, syncRepo: syncRepo));
}

class AnasSpaceApp extends StatelessWidget {
  final GalleryService galleryService;
  final SyncRepositoryImpl syncRepo;
  const AnasSpaceApp({
    super.key,
    required this.galleryService,
    required this.syncRepo,
  });
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SyncCubit(syncRepo)),
        BlocProvider(create: (_) => ThemeCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        buildWhen: (prev, next) => prev.themeMode != next.themeMode,
        builder: (context, themeState) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Anas Space',
            theme: StoneThemes.light,
            darkTheme: StoneThemes.dark,
            themeMode: themeState.themeMode,
            builder: (context, child) {
              if (child == null) return const SizedBox.shrink();
              return ThemeRippleOverlay(child: child);
            },
            home: SplashScreen(galleryService: galleryService),
          );
        },
      ),
    );
  }
}
