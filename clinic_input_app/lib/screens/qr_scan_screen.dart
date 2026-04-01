import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/desktop_connection_service.dart';
import '../theme/app_theme.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _manualHostCtrl = TextEditingController();
  final _manualPortCtrl = TextEditingController(text: '8080');
  final _manualTokenCtrl = TextEditingController();
  MobileScannerController? _cameraController;
  bool _isProcessing = false;
  bool _cameraAvailable = true;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameraController = MobileScannerController();
    } catch (_) {
      setState(() => _cameraAvailable = false);
    }
  }

  @override
  void dispose() {
    _manualHostCtrl.dispose();
    _manualPortCtrl.dispose();
    _manualTokenCtrl.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _handleCode(String code) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    _cameraController?.stop();

    try {
      // Try to parse as JSON connection payload from the desktop app
      final data = jsonDecode(code);
      if (data is Map &&
          data.containsKey('host') &&
          data.containsKey('port') &&
          data.containsKey('token')) {
        final connected =
            await DesktopConnectionService.instance.connect(code);
        if (!mounted) return;
        if (connected) {
          _showSuccess();
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/welcome');
          }
        } else {
          _showError(
            'Could not connect to the desktop app. '
            'Make sure you are on the same Wi-Fi network.',
          );
          _resumeScanning();
        }
      } else {
        _showError('Invalid QR code. Please scan the code from the desktop app.');
        _resumeScanning();
      }
    } catch (_) {
      // Not valid JSON
      if (!mounted) return;
      _showError('Invalid QR code format. Please scan the code from the desktop app.');
      _resumeScanning();
    }
  }

  Future<void> _handleManualConnect() async {
    final host = _manualHostCtrl.text.trim();
    final portStr = _manualPortCtrl.text.trim();
    final token = _manualTokenCtrl.text.trim();

    if (host.isEmpty || portStr.isEmpty || token.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    final port = int.tryParse(portStr);
    if (port == null) {
      _showError('Invalid port number.');
      return;
    }

    setState(() => _isProcessing = true);

    final connected = await DesktopConnectionService.instance.connectManual(
      host: host,
      port: port,
      token: token,
    );

    if (!mounted) return;

    if (connected) {
      _showSuccess();
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    } else {
      _showError('Connection failed. Check the IP, port, and token.');
      setState(() => _isProcessing = false);
    }
  }

  void _resumeScanning() {
    setState(() => _isProcessing = false);
    _cameraController?.start();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSuccess() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Connected to desktop app!'),
        backgroundColor: AppTheme.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // ── Header ──────────────────────────────────────────
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Connect to Clinic',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Scan the QR code on the desktop app to connect',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // ── Camera preview ──────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _cameraAvailable && _cameraController != null
                      ? Stack(
                          children: [
                            MobileScanner(
                              controller: _cameraController!,
                              onDetect: (capture) {
                                final barcode = capture.barcodes.firstOrNull;
                                if (barcode?.rawValue != null) {
                                  _handleCode(barcode!.rawValue!);
                                }
                              },
                            ),
                            if (_isProcessing)
                              Container(
                                color: Colors.black54,
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Connecting...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: AppTheme.cardLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.dividerColor),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.videocam_off_rounded,
                                  size: 48,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Camera not available',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Use the manual input below',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Manual input fallback ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR CONNECT MANUALLY',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _manualHostCtrl,
                          decoration: const InputDecoration(
                            hintText: 'IP Address (e.g. 192.168.1.100)',
                            prefixIcon: Icon(Icons.language_rounded),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _manualPortCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Port',
                            prefixIcon: Icon(Icons.numbers_rounded),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualTokenCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Auth token...',
                            prefixIcon: Icon(Icons.vpn_key_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : _handleManualConnect,
                          child: const Text('Connect'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

