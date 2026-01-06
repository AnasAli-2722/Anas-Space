import 'dart:async';
import '../../../core/network/infinity_bridge.dart';
import '../../gallery/data/gallery_service.dart';
import '../../gallery/domain/unified_asset.dart';
import '../../gallery/domain/sync_repository.dart';

class SyncRepositoryImpl implements SyncRepository {
  final GalleryService _galleryService;
  InfinityBridge? _bridge;

  String _pairingToken = "";

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
  Future<String> startServer({required String pairingToken}) async {
    _pairingToken = pairingToken;
    _bridge = InfinityBridge(
      pairingToken: _pairingToken,
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
      return ip;
    } catch (e) {
      _logController.add("❌ Failed to start: $e");
      rethrow;
    }
  }

  @override
  void connectToDevice(String ip, {required String pairingToken}) {
    _pairingToken = pairingToken;
    _bridge?.connectToDevice(
      ip,
      pairingToken: _pairingToken,
      sendHandshake: true,
    );
  }

  @override
  void stopServer() {
    _bridge?.stop();
    _logController.add("🛑 Server Stopped");
  }

  /// Cleanup method to close all streams and stop the server
  @override
  void dispose() {
    stopServer();
    _logController.close();
    _connectionController.close();
    _remoteAssetsController.close();
  }
}
