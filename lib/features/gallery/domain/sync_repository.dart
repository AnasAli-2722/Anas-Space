// lib/features/sync/domain/sync_repository.dart
import '../../gallery/domain/unified_asset.dart';

abstract class SyncRepository {
  //---------*Streams*---------
  Stream<String> get logs;
  Stream<Map<String, String>> get connections;
  Stream<List<UnifiedAsset>> get remoteAssets;

  //---------*Actions*---------
  Future<String> startServer({required String pairingToken});
  void connectToDevice(String ip, {required String pairingToken});
  void stopServer();

  void dispose();
}
