import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../gallery/domain/sync_repository.dart';
import 'sync_state.dart';

class SyncCubit extends Cubit<SyncState> {
  final SyncRepository _syncRepository;

  StreamSubscription? _logSub;
  StreamSubscription? _connSub;
  StreamSubscription? _assetSub;

  SyncCubit(this._syncRepository) : super(SyncState());

  Future<void> toggleServer() async {
    if (state.isServerRunning) {
      _stop();
    } else {
      await _start();
    }
  }

  void connectToDevice(String ip) {
    _addLog("🔄 Attempting connection to $ip...");
    _syncRepository.connectToDevice(ip);
  }

  Future<void> _start() async {
    emit(state.copyWith(logs: [], remoteAssets: [], connectedDevices: {}));

    _logSub?.cancel();
    _logSub = _syncRepository.logs.listen((message) {
      _addLog(message);

      if (message.contains("Server Running on")) {
        final ip = message.split("Server Running on ")[1].trim();
        emit(state.copyWith(isServerRunning: true, myIp: ip));
      }
    });

    _connSub?.cancel();
    _connSub = _syncRepository.connections.listen((data) {
      final newMap = Map<String, String>.from(state.connectedDevices);
      newMap[data['ip']!] = data['name']!;
      emit(state.copyWith(connectedDevices: newMap));
    });

    _assetSub?.cancel();
    _assetSub = _syncRepository.remoteAssets.listen((newAssets) {
      final currentIds = state.remoteAssets.map((e) => e.id).toSet();
      final uniqueNew = newAssets
          .where((e) => !currentIds.contains(e.id))
          .toList();

      if (uniqueNew.isNotEmpty) {
        emit(
          state.copyWith(remoteAssets: [...state.remoteAssets, ...uniqueNew]),
        );
        _addLog("📥 Received ${uniqueNew.length} new files");
      }
    });

    await _syncRepository.startServer();
  }

  void _stop() {
    _syncRepository.stopServer();
    _logSub?.cancel();
    _connSub?.cancel();
    _assetSub?.cancel();
    emit(
      state.copyWith(
        isServerRunning: false,
        myIp: "Offline",
        remoteAssets: [],
        connectedDevices: {},
      ),
    );
  }

  void _addLog(String msg) {
    final updatedLogs = [msg, ...state.logs];
    if (updatedLogs.length > 50) updatedLogs.removeLast();
    emit(state.copyWith(logs: updatedLogs));
  }

  @override
  Future<void> close() {
    _stop();
    return super.close();
  }
}
