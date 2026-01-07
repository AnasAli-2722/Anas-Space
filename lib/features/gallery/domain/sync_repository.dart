import '../../gallery/domain/unified_asset.dart';
abstract class SyncRepository {
  Stream<String> get logs;
  Stream<Map<String, String>> get connections;
  Stream<List<UnifiedAsset>> get remoteAssets;
  Future<String> startServer({required String pairingToken});
  void connectToDevice(String ip, {required String pairingToken});
  void stopServer();
  void dispose();
}

