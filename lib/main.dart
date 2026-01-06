import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:window_manager/window_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'features/gallery/presentation/pages/dashboard_page.dart';
import 'features/gallery/data/gallery_service.dart';
import 'features/sync/data/sync_repository_impl.dart';
import 'features/sync/presentation/cubit/sync_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool isDesktop =
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

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

  PaintingBinding.instance.imageCache.maximumSizeBytes = 500 * 1024 * 1024;

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
      providers: [BlocProvider(create: (_) => SyncCubit(syncRepo))],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Anas Space',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0A0A0A),
          useMaterial3: true,
          fontFamily: 'Segoe UI',
          colorScheme: const ColorScheme.dark(
            primary: Colors.blueAccent,
            error: Colors.redAccent,
          ),
        ),
        home: DashboardPage(galleryService: galleryService),
      ),
    );
  }
}
