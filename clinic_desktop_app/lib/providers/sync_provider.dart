import 'package:flutter/material.dart';
import '../crdt/sync_client.dart';
import '../crdt/data_compactor.dart';
import '../crdt/node_id.dart';
import 'patient_provider.dart';

/// Manages the CRDT sync lifecycle and exposes connection status to the UI.
class SyncProvider extends ChangeNotifier {
  SyncClient? _client;
  PatientProvider? _patientProvider;

  SyncConnectionState _connectionState = SyncConnectionState.disconnected;
  SyncConnectionState get connectionState => _connectionState;

  bool get isConnected => _connectionState == SyncConnectionState.connected;
  bool get isConnecting => _connectionState == SyncConnectionState.connecting;

  /// Initialize the sync system.
  /// Call this after PatientProvider.initCrdt() has been called.
  Future<void> init(PatientProvider patientProvider, {String? wsUrl}) async {
    _patientProvider = patientProvider;

    if (wsUrl == null || wsUrl.isEmpty) {
      debugPrint('SyncProvider: no wsUrl configured, running offline');
      return;
    }

    final nodeId = await NodeId.get();
    _client = SyncClient(wsUrl: wsUrl, nodeId: nodeId);

    _client!.onStateChanged = () {
      _connectionState = _client!.state;
      notifyListeners();
    };

    _client!.onSyncComplete = (changedIds) {
      _patientProvider?.onSyncComplete(changedIds);
    };

    // Run data compaction on startup
    final removed = await DataCompactor.run();
    if (removed > 0) {
      debugPrint('SyncProvider: compacted $removed old tombstones');
    }

    // Auto-connect to relay server
    await connect();
  }

  /// Manually connect to the relay server.
  Future<void> connect() async {
    await _client?.connect();
  }

  /// Disconnect from the relay server.
  void disconnect() {
    _client?.disconnect();
  }

  /// Push local changes after a write.
  Future<void> pushChanges() async {
    await _client?.pushChanges();
  }

  @override
  void dispose() {
    _client?.disconnect();
    super.dispose();
  }
}
