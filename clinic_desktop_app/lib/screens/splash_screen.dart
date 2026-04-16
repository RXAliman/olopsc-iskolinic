import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constants/app_config.dart';
import '../providers/patient_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/custom_symptom_provider.dart';
import '../providers/local_server_provider.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';

/// Callback signature for when the splash screen finishes initialization.
typedef InitCompleteCallback =
    void Function({
      required PatientProvider patientProvider,
      required SyncProvider syncProvider,
      required InventoryProvider inventoryProvider,
      required CustomSymptomProvider customSymptomProvider,
      required LocalServerProvider localServerProvider,
    });

/// Startup splash screen that handles:
/// 1. Checking for app updates via Google Drive
/// 2. Offering update download with progress tracking
/// 3. Initializing all app services (DB, sync, inventory, local server)
/// 4. Transitioning to the main dashboard
class SplashScreen extends StatefulWidget {
  final InitCompleteCallback onInitComplete;

  const SplashScreen({super.key, required this.onInitComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

enum _SplashPhase {
  checkingUpdates,
  updateAvailable,
  downloading,
  initializing,
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  _SplashPhase _phase = _SplashPhase.checkingUpdates;
  UpdateInfo? _updateInfo;
  double _downloadProgress = 0;
  String _initStatus = '';
  String? _errorMessage;
  bool _downloadCancelled = false;
  String _currentVersion = '';

  late AnimationController _logoController;
  late Animation<double> _logoFade;
  late AnimationController _contentController;
  late Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _logoFade = CurvedAnimation(parent: _logoController, curve: Curves.easeOut);

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _contentFade = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    );

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _contentController.forward();
    });

    _startUpdateCheck();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ── Update Check ────────────────────────────────────────────────

  Future<void> _startUpdateCheck() async {
    // Read the current app version from the Windows executable metadata
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;
    } catch (_) {
      _currentVersion = '0.0.0';
    }

    final updateInfo = await UpdateService.checkForUpdate(_currentVersion);

    if (!mounted) return;

    if (updateInfo != null) {
      setState(() {
        _phase = _SplashPhase.updateAvailable;
        _updateInfo = updateInfo;
      });
    } else {
      _startInitialization();
    }
  }

  // ── App Initialization ──────────────────────────────────────────

  Future<void> _startInitialization() async {
    if (!mounted) return;
    setState(() {
      _phase = _SplashPhase.initializing;
      _errorMessage = null;
    });

    try {
      // Step 1: Database & patients
      _setStatus('Loading patient database...');
      final patientProvider = PatientProvider();
      await patientProvider.initCrdt();
      await patientProvider.loadPatients();
      if (!mounted) return;



      // Step 3: Inventory
      _setStatus('Loading inventory...');
      final inventoryProvider = InventoryProvider();
      await inventoryProvider.loadInventory();
      patientProvider.setInventoryProvider(inventoryProvider);
      if (!mounted) return;

      // Step 4: Local HTTP server for tablet connection
      _setStatus('Starting local server...');
      final localServerProvider = LocalServerProvider();
      await localServerProvider.startServer();
      localServerProvider.setOnDataChanged(() {
        patientProvider.refreshAll();
      });
      if (!mounted) return;

      // Step 5: Custom Symptoms
      _setStatus('Loading custom symptoms...');
      final customSymptomProvider = CustomSymptomProvider();
      await customSymptomProvider.loadSymptoms();
      if (!mounted) return;

      // Step 6: Sync service (fire-and-forget, don't block startup)
      _setStatus('Starting sync service...');
      final syncProvider = SyncProvider();
      syncProvider.init(
        patientProvider,
        inventoryProvider,
        customSymptomProvider,
        wsUrl: AppConfig.relayServerUrl,
      );
      patientProvider.setOnLocalWrite(() => syncProvider.pushChanges());
      if (!mounted) return;

      // Brief pause so the user sees "Ready!" before the transition
      _setStatus('Ready!');
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      widget.onInitComplete(
        patientProvider: patientProvider,
        syncProvider: syncProvider,
        inventoryProvider: inventoryProvider,
        customSymptomProvider: customSymptomProvider,
        localServerProvider: localServerProvider,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Initialization error: $e';
          _initStatus = 'An error occurred';
        });
      }
    }
  }

  void _setStatus(String status) {
    if (mounted) setState(() => _initStatus = status);
  }

  // ── Download ────────────────────────────────────────────────────

  Future<void> _startDownload() async {
    setState(() {
      _phase = _SplashPhase.downloading;
      _downloadProgress = 0;
      _downloadCancelled = false;
      _errorMessage = null;
    });

    final file = await UpdateService.downloadInstaller(
      _updateInfo!.downloadUrl,
      (progress) {
        if (mounted && !_downloadCancelled) {
          setState(() => _downloadProgress = progress);
        }
      },
    );

    if (_downloadCancelled) return;

    if (file != null && mounted) {
      setState(() => _initStatus = 'Launching installer...');
      await UpdateService.launchInstallerAndExit(file);
    } else if (mounted) {
      setState(() {
        _errorMessage = 'Download failed. Starting app normally...';
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _startInitialization();
    }
  }

  void _skipUpdate() {
    _startInitialization();
  }

  void _cancelDownload() {
    _downloadCancelled = true;
    _startInitialization();
  }

  // ── UI ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryLight,
      body: Center(
        child: FadeTransition(
          opacity: _logoFade,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── App Logo ──
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset('assets/app-icon-colored.png', height: 100),
              ),
              const SizedBox(height: 24),

              // ── App Name ──
              Text(
                AppConfig.appName,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),

              // ── Version + Environment Badge ──
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_currentVersion.isNotEmpty)
                    Text(
                      'v$_currentVersion',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  if (!AppConfig.isProduction) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppTheme.warning.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        'DEV',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.warning,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 48),

              // ── Content Area ──
              FadeTransition(
                opacity: _contentFade,
                child: SizedBox(
                  width: 420,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _buildPhaseContent(),
                  ),
                ),
              ),

              // ── Error Message ──
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.danger.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: AppTheme.danger.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the content widget based on the current splash phase.
  Widget _buildPhaseContent() {
    switch (_phase) {
      case _SplashPhase.checkingUpdates:
        return _buildCheckingUpdates();
      case _SplashPhase.updateAvailable:
        return _buildUpdateAvailable();
      case _SplashPhase.downloading:
        return _buildDownloading();
      case _SplashPhase.initializing:
        return _buildInitializing();
    }
  }

  // ── Phase: Checking for Updates ─────────────────────────────────

  Widget _buildCheckingUpdates() {
    return Column(
      key: const ValueKey('checking'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SpinKitThreeBounce(color: AppTheme.accent, size: 24),
        const SizedBox(height: 16),
        Text(
          'Checking for updates...',
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  // ── Phase: Update Available ─────────────────────────────────────

  Widget _buildUpdateAvailable() {
    return Container(
      key: const ValueKey('update'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: badge + version
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.system_update_alt_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Update Available',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'v${_updateInfo!.version}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accent,
                ),
              ),
            ],
          ),

          // Changelog
          if (_updateInfo!.changelog.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: AppTheme.dividerColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'What\'s new:',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: SingleChildScrollView(
                child: Text(
                  _updateInfo!.changelog,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],

          // Buttons
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _skipUpdate,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Skip'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startDownload,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Update Now'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Phase: Downloading ──────────────────────────────────────────

  Widget _buildDownloading() {
    final percent = (_downloadProgress * 100).toInt();

    return Container(
      key: const ValueKey('downloading'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.downloading_rounded,
                color: AppTheme.accent,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Downloading update...',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _downloadProgress,
              backgroundColor: AppTheme.cardLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _cancelDownload,
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── Phase: Initializing ─────────────────────────────────────────

  Widget _buildInitializing() {
    return Column(
      key: const ValueKey('initializing'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SpinKitPulse(color: AppTheme.accent, size: 44),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _initStatus,
            key: ValueKey(_initStatus),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
