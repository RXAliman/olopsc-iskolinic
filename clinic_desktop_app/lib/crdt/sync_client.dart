import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/database_helper.dart';
import '../crdt/hlc.dart';
import '../crdt/sync_isolate.dart';

/// Connection states for the WebSocket sync client.
enum SyncConnectionState { disconnected, connecting, connected }

/// WebSocket client for CRDT sync with relay server.
///
/// Features:
/// - Heartbeat every 3 minutes (prevents Render timeout)
/// - Chunked sync in batches of 50 records
/// - Outbound: sends local changes after each write
/// - Inbound: receives remote changes, merges via SyncIsolate
class SyncClient {
  final String wsUrl;
  final String nodeId;
  final String? authSecret;
  final DatabaseHelper _db = DatabaseHelper.instance;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  SyncConnectionState _state = SyncConnectionState.disconnected;
  SyncConnectionState get state => _state;

  /// Called when connection state changes.
  VoidCallback? onStateChanged;

  /// Called after a sync batch has been merged, with the set of changed IDs.
  void Function(Set<String> changedIds)? onSyncComplete;

  static const int _batchSize = 50;
  static const Duration _heartbeatInterval = Duration(minutes: 3);

  // Exponential backoff for reconnect (1s → 2s → 4s → ... → max 30s)
  int _reconnectAttempts = 0;
  static const int _maxReconnectDelaySec = 30;
  String _currentSyncMaxHlc = '';

  SyncClient({required this.wsUrl, required this.nodeId, this.authSecret});

  // ── HLC Data-Driven Safeguard ───────────────────────────────────

  String _getBatchMaxHlc(List<dynamic> batchRecords, String currentMax) {
    var max = currentMax;
    for (final r in batchRecords) {
      if (r is Map<String, dynamic>) {
        final recHlc = r['hlc'] as String?;
        if (recHlc != null && recHlc.isNotEmpty) {
          try {
            final unpacked = HLC.unpack(recHlc);
            final nowMs = DateTime.now().millisecondsSinceEpoch;
            // Sanity Check: Reject "Time Traveler" HLCs > 1 day in the future
            if (unpacked.timestamp > nowMs + 86400000) continue;

            if (max.isEmpty || unpacked > HLC.unpack(max)) {
              max = recHlc;
            }
          } catch (_) {}
        }
      }
    }
    return max;
  }

  // ── Connection lifecycle ────────────────────────────────────────

  /// Connect to the relay server.
  Future<void> connect() async {
    if (_state == SyncConnectionState.connecting ||
        _state == SyncConnectionState.connected) {
      return;
    }

    _setState(SyncConnectionState.connecting);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      await _channel!.ready;

      _setState(SyncConnectionState.connected);
      _reconnectAttempts = 0; // Reset backoff on successful connect
      _startHeartbeat();

      _subscription = _channel!.stream.listen(
        _onMessage,
        onDone: _onDisconnected,
        onError: (_) => _onDisconnected(),
      );

      // Request Handshake for server resets
      _send({'type': 'handshake_request', 'nodeId': nodeId});

      // Request initial sync — tell server our last known HLC
      await _requestSync();
    } catch (e) {
      debugPrint('SyncClient: connection failed: $e');
      _setState(SyncConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  /// Disconnect gracefully.
  void disconnect() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _setState(SyncConnectionState.disconnected);
  }

  void _onDisconnected() {
    _heartbeatTimer?.cancel();
    _channel = null;
    _setState(SyncConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    // Exponential backoff: 1s, 2s, 4s, 8s, 16s, 30s, 30s, ...
    final delaySec = (1 << _reconnectAttempts).clamp(1, _maxReconnectDelaySec);
    _reconnectAttempts++;
    debugPrint(
      'SyncClient: reconnecting in ${delaySec}s (attempt $_reconnectAttempts)',
    );
    _reconnectTimer = Timer(Duration(seconds: delaySec), connect);
  }

  void _setState(SyncConnectionState newState) {
    if (_state == newState) return;
    _state = newState;
    onStateChanged?.call();
  }

  // ── Heartbeat ───────────────────────────────────────────────────

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _send({'type': 'ping', 'nodeId': nodeId});
    });
  }

  // ── Outbound: send local changes ─────────────────────────────

  /// Send a batch of local changes to the relay server.
  /// Called by SyncProvider after every local write.
  Future<void> pushChanges() async {
    if (_state != SyncConnectionState.connected) return;

    final lastSync = await _db.getMeta('lastSyncHlc') ?? '';

    // Send patients
    final patients = await _db.getPatientChangesSince(lastSync);
    for (int i = 0; i < patients.length; i += _batchSize) {
      final end = (i + _batchSize).clamp(0, patients.length);
      final batch = patients.sublist(i, end);
      _send({
        'type': 'sync_push',
        'nodeId': nodeId,
        'table': 'patients',
        'records': batch.map((p) => p.toSyncMap()).toList(),
      });
    }

    // Send visitations
    final visitations = await _db.getVisitationChangesSince(lastSync);
    for (int i = 0; i < visitations.length; i += _batchSize) {
      final end = (i + _batchSize).clamp(0, visitations.length);
      final batch = visitations.sublist(i, end);
      _send({
        'type': 'sync_push',
        'nodeId': nodeId,
        'table': 'visitations',
        'records': batch.map((v) => v.toSyncMap()).toList(),
      });
    }

    // Send inventory
    final inventoryItems = await _db.getInventoryChangesSince(lastSync);
    for (int i = 0; i < inventoryItems.length; i += _batchSize) {
      final end = (i + _batchSize).clamp(0, inventoryItems.length);
      final batch = inventoryItems.sublist(i, end);
      _send({
        'type': 'sync_push',
        'nodeId': nodeId,
        'table': 'inventory',
        'records': batch.map((v) => v.toSyncMap()).toList(),
      });
    }

    // Send inventory stocks
    final inventoryStocks = await _db.getInventoryStockChangesSince(lastSync);
    for (int i = 0; i < inventoryStocks.length; i += _batchSize) {
      final end = (i + _batchSize).clamp(0, inventoryStocks.length);
      final batch = inventoryStocks.sublist(i, end);
      _send({
        'type': 'sync_push',
        'nodeId': nodeId,
        'table': 'inventory_stocks',
        'records': batch.map((v) => v.toSyncMap()).toList(),
      });
    }

    // Send custom symptoms
    final customSymptoms = await _db.getCustomSymptomChangesSince(lastSync);
    for (int i = 0; i < customSymptoms.length; i += _batchSize) {
      final end = (i + _batchSize).clamp(0, customSymptoms.length);
      final batch = customSymptoms.sublist(i, end);
      _send({
        'type': 'sync_push',
        'nodeId': nodeId,
        'table': 'custom_symptoms',
        'records': batch.map((v) => v.toMap()).toList(),
      });
    }

    // We NO LONGER update lastSyncHlc based on our local push.
    // Bookmarks are entirely data-driven based on incoming server batches.
  }

  Future<void> forcePushAllChanges() async {
    if (_state != SyncConnectionState.connected) return;

    final patients = await _db.getPatientChangesSince('');
    for (int i = 0; i < patients.length; i += _batchSize) {
      final end = (i + _batchSize).clamp(0, patients.length);
      final batch = patients.sublist(i, end);
      _send({
        'type': 'sync_push',
        'nodeId': nodeId,
        'table': 'patients',
        'records': batch.map((p) => p.toSyncMap()).toList(),
      });
    }

    final visitations = await _db.getVisitationChangesSince('');
    for (int i = 0; i < visitations.length; i += _batchSize) {
      final end = (i + _batchSize).clamp(0, visitations.length);
      final batch = visitations.sublist(i, end);
      _send({
        'type': 'sync_push',
        'nodeId': nodeId,
        'table': 'visitations',
        'records': batch.map((v) => v.toSyncMap()).toList(),
      });
    }

    final inventoryItems = await _db.getInventoryChangesSince('');
    for (int i = 0; i < inventoryItems.length; i += _batchSize) {
      final end = (i + _batchSize).clamp(0, inventoryItems.length);
      final batch = inventoryItems.sublist(i, end);
      _send({
        'type': 'sync_push',
        'nodeId': nodeId,
        'table': 'inventory',
        'records': batch.map((v) => v.toSyncMap()).toList(),
      });
    }

    final inventoryStocks = await _db.getInventoryStockChangesSince('');
    for (int i = 0; i < inventoryStocks.length; i += _batchSize) {
      final end = (i + _batchSize).clamp(0, inventoryStocks.length);
      final batch = inventoryStocks.sublist(i, end);
      _send({
        'type': 'sync_push',
        'nodeId': nodeId,
        'table': 'inventory_stocks',
        'records': batch.map((v) => v.toSyncMap()).toList(),
      });
    }

    final customSymptoms = await _db.getCustomSymptomChangesSince('');
    for (int i = 0; i < customSymptoms.length; i += _batchSize) {
      final end = (i + _batchSize).clamp(0, customSymptoms.length);
      final batch = customSymptoms.sublist(i, end);
      _send({
        'type': 'sync_push',
        'nodeId': nodeId,
        'table': 'custom_symptoms',
        'records': batch.map((v) => v.toMap()).toList(),
      });
    }
  }

  /// Request any changes we've missed from the server.
  Future<void> _requestSync() async {
    _currentSyncMaxHlc = ''; // Reset when we begin a new request
    final lastSync = await _db.getMeta('lastSyncHlc') ?? '';
    _send({
      'type': 'sync_request',
      'nodeId': nodeId,
      'sinceHlc': lastSync,
      'batchSize': _batchSize,
    });

    // Also push our local changes
    await pushChanges();
  }

  // ── Inbound: receive remote changes ──────────────────────────

  void _onMessage(dynamic raw) async {
    try {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = msg['type'] as String?;

      switch (type) {
        case 'pong':
          // Heartbeat acknowledged
          break;

        case 'sync_push':
          // Remote node pushed changes to us via the relay
          final senderNodeId = msg['nodeId'] as String? ?? '';
          if (senderNodeId == nodeId) return; // Ignore our own echoes

          final table = msg['table'] as String? ?? '';
          final records =
              (msg['records'] as List?)?.cast<Map<String, dynamic>>() ?? [];

          final batch = SyncBatch(
            patients: table == 'patients' ? records : [],
            visitations: table == 'visitations' ? records : [],
            inventory: table == 'inventory' ? records : [],
            inventoryStocks: table == 'inventory_stocks' ? records : [],
            customSymptoms: table == 'custom_symptoms' ? records : [],
          );

          final result = await SyncIsolate.mergeBatch(batch);
          final allChanged = {
            ...result.changedPatientIds,
            ...result.changedVisitationIds,
            ...result.changedInventoryIds,
            ...result.changedCustomSymptomIds,
          };
          if (allChanged.isNotEmpty) {
            onSyncComplete?.call(allChanged);
          }
          break;

        case 'sync_response':
          // Server sending us historical data in batches
          final patients =
              (msg['patients'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final visitations =
              (msg['visitations'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final inventory =
              (msg['inventory'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final inventoryStocks =
              (msg['inventory_stocks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final customSymptoms =
              (msg['custom_symptoms'] as List?)?.cast<Map<String, dynamic>>() ?? [];

          // Track max HLC for data-driven bookmarking
          _currentSyncMaxHlc = _getBatchMaxHlc(patients, _currentSyncMaxHlc);
          _currentSyncMaxHlc = _getBatchMaxHlc(visitations, _currentSyncMaxHlc);
          _currentSyncMaxHlc = _getBatchMaxHlc(inventory, _currentSyncMaxHlc);
          _currentSyncMaxHlc = _getBatchMaxHlc(inventoryStocks, _currentSyncMaxHlc);
          _currentSyncMaxHlc = _getBatchMaxHlc(customSymptoms, _currentSyncMaxHlc);

          final batch = SyncBatch(
            patients: patients,
            visitations: visitations,
            inventory: inventory,
            inventoryStocks: inventoryStocks,
            customSymptoms: customSymptoms,
          );
          final result = await SyncIsolate.mergeBatch(batch);
          final allChanged = {
            ...result.changedPatientIds,
            ...result.changedVisitationIds,
            ...result.changedInventoryIds,
            ...result.changedCustomSymptomIds,
          };
          if (allChanged.isNotEmpty) {
            onSyncComplete?.call(allChanged);
          }

          // Acknowledge to get the next batch
          final hasMore = msg['hasMore'] as bool? ?? false;
          if (hasMore) {
            _send({
              'type': 'sync_ack',
              'nodeId': nodeId,
              'batchSize': _batchSize,
            });
          } else {
            // Full sync complete — update marker conditionally based on received HLC
            if (_currentSyncMaxHlc.isNotEmpty) {
              final currentLocal = await _db.getMeta('lastSyncHlc') ?? '';
              if (currentLocal.isEmpty || HLC.unpack(_currentSyncMaxHlc) > HLC.unpack(currentLocal)) {
                await _db.setMeta('lastSyncHlc', _currentSyncMaxHlc);
              }
            }
          }
          break;
          
        case 'handshake_response':
          final recognized = msg['recognized'] as bool? ?? true;
          if (!recognized || (msg['server_reset'] == true)) {
            debugPrint('Server reset indicated. Forcing full push of local data...');
            await forcePushAllChanges();
          }
          break;
      }
    } catch (e) {
      debugPrint('SyncClient: error processing message: $e');
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────

  void _send(Map<String, dynamic> data) {
    if (_channel == null) return;
    try {
      // Inject the secret if it exists
      if (authSecret != null) {
        data['authSecret'] = authSecret;
      }
      _channel!.sink.add(jsonEncode(data));
    } catch (e) {
      debugPrint('SyncClient: send error: $e');
    }
  }
}
