import '../../../gallery/domain/unified_asset.dart';

class SyncState {
  final bool isServerRunning;
  final String myIp;
  final String pairingToken;
  final List<String> logs;
  final List<UnifiedAsset> remoteAssets;

  final Map<String, String> connectedDevices;

  SyncState({
    this.isServerRunning = false,
    this.myIp = "Offline",
    this.pairingToken = "",
    this.logs = const [],
    this.remoteAssets = const [],
    this.connectedDevices = const {},
  });

  SyncState copyWith({
    bool? isServerRunning,
    String? myIp,
    String? pairingToken,
    List<String>? logs,
    List<UnifiedAsset>? remoteAssets,
    Map<String, String>? connectedDevices,
  }) {
    return SyncState(
      isServerRunning: isServerRunning ?? this.isServerRunning,
      myIp: myIp ?? this.myIp,
      pairingToken: pairingToken ?? this.pairingToken,
      logs: logs ?? this.logs,
      remoteAssets: remoteAssets ?? this.remoteAssets,
      connectedDevices: connectedDevices ?? this.connectedDevices,
    );
  }
}
