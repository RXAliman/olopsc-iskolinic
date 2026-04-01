import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';
import '../models/patient.dart';
import '../models/visitation.dart';
import '../services/database_helper.dart';
import '../crdt/hlc.dart';
import '../crdt/node_id.dart';

/// Lightweight HTTP server embedded in the desktop app.
///
/// Exposes REST endpoints that the tablet app uses to submit patient data
/// and fetch existing records over a private local network.
class LocalServerService {
  static final LocalServerService instance = LocalServerService._internal();
  factory LocalServerService() => instance;
  LocalServerService._internal();

  HttpServer? _server;
  String _authToken = '';
  String _localIp = '';
  int _port = 8080;
  final Map<String, DateTime> _connectedDevices = {};
  static const _deviceTimeout = Duration(seconds: 60);

  bool get isRunning => _server != null;
  String get authToken => _authToken;
  String get localIp => _localIp;
  int get port => _port;

  /// Returns only devices that have made a request within the last 60 seconds.
  Set<String> get connectedDevices {
    final now = DateTime.now();
    _connectedDevices.removeWhere(
      (_, lastSeen) => now.difference(lastSeen) > _deviceTimeout,
    );
    return _connectedDevices.keys.toSet();
  }

  /// JSON payload to encode in the QR code.
  String get qrPayload => jsonEncode({
        'host': _localIp,
        'port': _port,
        'token': _authToken,
      });

  /// Callback invoked when patient data changes (new patient/visitation).
  /// The desktop's PatientProvider should listen to this to refresh its UI.
  void Function()? onDataChanged;

  /// Start the HTTP server on all network interfaces.
  Future<void> start({int port = 8080}) async {
    if (_server != null) return; // Already running

    _port = port;
    _authToken = const Uuid().v4();
    _localIp = await _detectLocalIp();

    final router = Router();

    // Health check endpoint
    router.get('/api/health', (shelf.Request request) {
      return shelf.Response.ok(
        jsonEncode({'status': 'ok', 'timestamp': DateTime.now().toIso8601String()}),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // Get all patients (non-deleted)
    router.get('/api/patients', (shelf.Request request) async {
      try {
        final patients = await DatabaseHelper.instance.getPatients();
        final list = patients.map((p) => p.toMap()).toList();
        // Convert numeric isDeleted to bool for JSON
        for (final map in list) {
          map['isDeleted'] = (map['isDeleted'] as int?) == 1;
        }
        return shelf.Response.ok(
          jsonEncode(list),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return shelf.Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    });

    // Add a new patient + visitation from the tablet form
    router.post('/api/patients', (shelf.Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body) as Map<String, dynamic>;

        final nodeId = await NodeId.get();
        final clock = HLC.now(nodeId).send();
        final hlcStr = clock.pack();
        final now = DateTime.now();
        final patientId = const Uuid().v4();

        // Build patientName from parts: "LAST, FIRST MIDDLE EXT"
        final firstName = data['firstName'] as String? ?? '';
        final lastName = data['lastName'] as String? ?? '';
        final middleName = data['middleName'] as String? ?? '';
        final ext = data['extension'] as String? ?? '';
        final patientName = data['patientName'] as String? ??
            '$lastName, $firstName $middleName $ext'
                .trim()
                .replaceAll(RegExp(r'\s+'), ' ');

        final patient = Patient(
          id: patientId,
          firstName: firstName,
          lastName: lastName,
          middleName: middleName,
          extension: ext,
          patientName: patientName,
          idNumber: data['idNumber'] as String? ?? '',
          birthdate: data['birthdate'] != null
              ? DateTime.tryParse(data['birthdate'] as String)
              : null,
          sex: data['sex'] as String? ?? '',
          contactNumber: data['contactNumber'] as String? ?? '',
          address: data['address'] as String? ?? '',
          guardianName: data['guardianName'] as String? ?? '',
          guardianContact: data['guardianContact'] as String? ?? '',
          guardian2Name: data['guardian2Name'] as String? ?? '',
          guardian2Contact: data['guardian2Contact'] as String? ?? '',
          allergicTo: data['allergicTo'] as String? ?? '',
          createdAt: now,
          updatedAt: now,
          hlc: hlcStr,
          nodeId: nodeId,
        );

        await DatabaseHelper.instance.insertPatient(patient);

        // If symptoms are included, create a visitation record too
        final symptoms = data['symptoms'] as List<dynamic>?;
        if (symptoms != null && symptoms.isNotEmpty) {
          final visitation = Visitation(
            id: const Uuid().v4(),
            patientId: patientId,
            symptoms: symptoms.cast<String>(),
            hlc: HLC.now(nodeId).send().pack(),
            nodeId: nodeId,
          );
          await DatabaseHelper.instance.insertVisitation(visitation);
        }

        // Notify desktop UI to refresh
        onDataChanged?.call();

        return shelf.Response(
          201,
          body: jsonEncode({'id': patientId, 'status': 'created'}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return shelf.Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    });

    // Auth middleware — validates Bearer token on every request
    shelf.Middleware authMiddleware() {
      return (shelf.Handler innerHandler) {
        return (shelf.Request request) {
          // Track connected devices
          final remoteIp = (request.context['shelf.io.connection_info']
                  as HttpConnectionInfo?)
              ?.remoteAddress
              .address;
          if (remoteIp != null) {
            _connectedDevices[remoteIp] = DateTime.now();
          }

          final authHeader = request.headers['authorization'];
          if (authHeader == null || authHeader != 'Bearer $_authToken') {
            return shelf.Response(
              401,
              body: jsonEncode({'error': 'Unauthorized'}),
              headers: {'Content-Type': 'application/json'},
            );
          }
          return innerHandler(request);
        };
      };
    }

    // CORS middleware for development
    shelf.Middleware corsMiddleware() {
      return (shelf.Handler innerHandler) {
        return (shelf.Request request) async {
          final response = await innerHandler(request);
          return response.change(headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Authorization, Content-Type',
          });
        };
      };
    }

    final pipeline = const shelf.Pipeline()
        .addMiddleware(corsMiddleware())
        .addMiddleware(authMiddleware())
        .addHandler(router.call);

    try {
      _server = await shelf_io.serve(pipeline, '0.0.0.0', _port);
      _server!.autoCompress = true;
      // ignore: avoid_print
      print('[LocalServer] Running on http://$_localIp:$_port');
    } catch (e) {
      // If default port is taken, try an alternative
      try {
        _port = 8081;
        _server = await shelf_io.serve(pipeline, '0.0.0.0', _port);
        _server!.autoCompress = true;
        // ignore: avoid_print
        print('[LocalServer] Running on http://$_localIp:$_port (fallback port)');
      } catch (e2) {
        // ignore: avoid_print
        print('[LocalServer] Failed to start: $e2');
      }
    }
  }

  /// Stop the HTTP server.
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  /// Regenerate the auth token. All existing tablet connections are invalidated.
  void regenerateToken() {
    _authToken = const Uuid().v4();
    _connectedDevices.clear();
  }

  /// Detect the local IP address on the LAN (not loopback).
  Future<String> _detectLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          // Prefer private network ranges (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
          if (addr.address.startsWith('192.168.') ||
              addr.address.startsWith('10.') ||
              addr.address.startsWith('172.')) {
            return addr.address;
          }
        }
      }
      // Fallback: return the first non-loopback address
      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        return interfaces.first.addresses.first.address;
      }
    } catch (_) {}
    return '127.0.0.1';
  }
}
