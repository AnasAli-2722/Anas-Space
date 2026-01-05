import 'dart:async';
import '../../../core/network/infinity_bridge.dart';
import '../../gallery/data/gallery_service.dart';
import '../../gallery/domain/unified_asset.dart';
import '../../gallery/domain/sync_repository.dart';

class SyncRepositoryImpl implements SyncRepository {
  final GalleryService _galleryService;
  InfinityBridge? _bridge;

  final _logController = StreamController<String>.broadcast();
  final _connectionController =
      StreamController<Map<String, String>>.broadcast();
  final _remoteAssetsController =
      StreamController<List<UnifiedAsset>>.broadcast();

  SyncRepositoryImpl({required GalleryService galleryService})
    : _galleryService = galleryService;

  @override
  Stream<String> get logs => _logController.stream;

  @override
  Stream<Map<String, String>> get connections => _connectionController.stream;

  @override
  Stream<List<UnifiedAsset>> get remoteAssets => _remoteAssetsController.stream;

  @override
  Future<void> startServer() async {
    _bridge = InfinityBridge(
      onLog: (msg) => _logController.add(msg),

      onConnection: (name, ip) {
        _connectionController.add({'name': name, 'ip': ip});
      },

      onNewAssetsReceived: (assets) {
        _remoteAssetsController.add(assets);
      },

      getLocalAssets: () {
        return _galleryService.cachedAssets;
      },
    );

    try {
      final ip = await _bridge!.start();
      _logController.add("✅ Server Running on $ip:4545");
    } catch (e) {
      _logController.add("❌ Failed to start: $e");
    }
  }

  @override
  void connectToDevice(String ip) {
    _bridge?.connectToDevice(ip, sendHandshake: true);
  }

  @override
  void stopServer() {
    _bridge?.stop();
    _logController.add("🛑 Server Stopped");
  }
}
