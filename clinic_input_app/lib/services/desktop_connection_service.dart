import 'dart:convert';
import 'package:http/http.dart' as http;

/// Manages the tablet's connection to the desktop app's local HTTP server.
///
/// Stores connection credentials parsed from the QR code and provides
/// methods to verify the connection, fetch patients, and submit new records.
class DesktopConnectionService {
  static final DesktopConnectionService instance =
      DesktopConnectionService._internal();
  factory DesktopConnectionService() => instance;
  DesktopConnectionService._internal();

  String _host = '';
  int _port = 8080;
  String _token = '';
  bool _connected = false;

  bool get isConnected => _connected;
  String get host => _host;
  int get port => _port;
  String get baseUrl => 'http://$_host:$_port';

  /// Parse QR code JSON and attempt to connect.
  ///
  /// Returns `true` if the health check succeeds.
  Future<bool> connect(String qrPayload) async {
    try {
      final data = jsonDecode(qrPayload) as Map<String, dynamic>;
      _host = data['host'] as String;
      _port = data['port'] as int;
      _token = data['token'] as String;

      // Verify connection with health check
      _connected = await _healthCheck();
      return _connected;
    } catch (e) {
      _connected = false;
      return false;
    }
  }

  /// Connect using manual IP and token.
  Future<bool> connectManual({
    required String host,
    required int port,
    required String token,
  }) async {
    _host = host;
    _port = port;
    _token = token;
    _connected = await _healthCheck();
    return _connected;
  }

  /// Verify the server is reachable and the token is valid.
  Future<bool> _healthCheck() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/health'),
            headers: _authHeaders,
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Re-check the connection status. Call this before critical operations.
  Future<bool> checkConnection() async {
    _connected = await _healthCheck();
    return _connected;
  }

  /// Fetch all patients from the desktop database.
  ///
  /// Returns a list of patient maps, or an empty list on failure.
  Future<List<Map<String, dynamic>>> fetchPatients() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/patients'),
            headers: _authHeaders,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      _connected = false;
      return [];
    }
  }

  /// Submit a new patient (and optional visitation) to the desktop database.
  ///
  /// Returns `true` on success.
  Future<bool> submitPatient(Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/patients'),
            headers: {
              ..._authHeaders,
              'Content-Type': 'application/json',
            },
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (_) {
      _connected = false;
      return false;
    }
  }

  /// Disconnect (clear credentials).
  void disconnect() {
    _host = '';
    _port = 8080;
    _token = '';
    _connected = false;
  }

  /// Standard auth headers for every request.
  Map<String, String> get _authHeaders => {
        'Authorization': 'Bearer $_token',
      };
}
