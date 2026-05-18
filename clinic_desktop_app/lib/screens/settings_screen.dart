import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../constants/app_config.dart';
import '../providers/settings_provider.dart';
import '../providers/sync_provider.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../services/database_backup_service.dart';
import '../services/update_service.dart';
import '../providers/patient_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';
  int _dropdownKeyCounter = 0;
  late TextEditingController _lanIpController;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _lanIpController = TextEditingController(text: settings.lanServerIp);
  }

  @override
  void dispose() {
    _lanIpController.dispose();
    super.dispose();
  }

  void _applyLanIp(SettingsProvider settings, SyncProvider sync, String val) async {
    final cleanIp = val.trim();
    if (cleanIp.isNotEmpty) {
      await settings.updateLanServerIp(cleanIp);
      sync.setConnectionMode(1, wsUrl: settings.lanWsUrl);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'LAN Server IP updated to $cleanIp and reconnecting...',
          ),
        ),
      );
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text(
            'Manage your application preferences and synchronization modes.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),

          // ── Connection Modes ──────────────────────────────────────────
          _buildSectionHeader('Connection Mode', Icons.sync_rounded),
          const SizedBox(height: 16),
          Consumer2<SettingsProvider, SyncProvider>(
            builder: (context, settings, sync, _) {
              return Container(
                decoration: AppTheme.glassCard(),
                child: RadioGroup<int>(
                  groupValue: settings.connectionMode,
                  onChanged: (v) {
                    if (v == null) return;
                    settings.updateConnectionMode(v);

                    final String wsUrl;
                    if (v == 1) {
                      wsUrl = settings.lanWsUrl;
                    } else {
                      wsUrl = AppConfig.relayServerUrl;
                    }
                    sync.setConnectionMode(v, wsUrl: wsUrl);
                  },
                  child: Column(
                    children: [
                      _buildRadioTile(
                        value: 1,
                        isSelected: settings.connectionMode == 1,
                        title: 'Local Area Network (LAN)',
                        subtitle:
                            'Connect directly to other devices on the same Wi-Fi or Ethernet. Best for real-time local sync.',
                        icon: Icons.router_rounded,
                        onTap: () {
                          settings.updateConnectionMode(1);
                          sync.setConnectionMode(
                            1,
                            wsUrl: settings.lanWsUrl,
                          );
                        },
                      ),
                      if (settings.connectionMode == 1) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 76,
                            right: 24,
                            bottom: 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LAN Server IP / Hostname',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 40,
                                      child: TextField(
                                        controller: _lanIpController,
                                        decoration: InputDecoration(
                                          hintText:
                                              'e.g., 192.168.1.100 or localhost',
                                          prefixIcon: const Icon(
                                            Icons.computer_rounded,
                                            size: 16,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        onSubmitted: (val) =>
                                            _applyLanIp(settings, sync, val),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      minimumSize: const Size(80, 40),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () => _applyLanIp(
                                      settings,
                                      sync,
                                      _lanIpController.text,
                                    ),
                                    child: const Text('Apply'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Type the IP address of the Clinic A computer running the relay server and click Apply.',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Divider(),
                      _buildRadioTile(
                        value: 2,
                        isSelected: settings.connectionMode == 2,
                        title: 'Relay Server',
                        subtitle:
                            'Sync through a central secure server. Works across different networks and over the internet.',
                        icon: Icons.cloud_done_rounded,
                        onTap: () {
                          settings.updateConnectionMode(2);
                          sync.setConnectionMode(
                            2,
                            wsUrl: AppConfig.relayServerUrl,
                          );
                        },
                      ),
                      const Divider(),
                      _buildRadioTile(
                        value: 0,
                        isSelected: settings.connectionMode == 0,
                        title: 'Work Offline',
                        subtitle:
                            'Keep all data on this device only. Synchronization is disabled.',
                        icon: Icons.cloud_off_rounded,
                        onTap: () {
                          settings.updateConnectionMode(0);
                          sync.setConnectionMode(0);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 48),

          // ── Sync Security ─────────────────────────────────────────────
          _buildSectionHeader('Sync Security', Icons.vignette_rounded),
          const SizedBox(height: 16),
          Container(
            decoration: AppTheme.glassCard(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relay Sync Secret',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The shared secret key used to authenticate with the cloud relay server.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.key_rounded, size: 18),
                    label: const Text('Update Sync Secret'),
                    onPressed: () => _showUpdateSecretDialog(context),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // ── Data Management ─────────────────────────────────────────────
          _buildSectionHeader('Data Management', Icons.folder_delete_rounded),
          const SizedBox(height: 16),
          Container(
            decoration: AppTheme.glassCard(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data Retention Policy',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Automatically delete patient records securely after a specified number of years. This helps keep the database performant and secures unneeded historical data.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 16),
                          Consumer<SettingsProvider>(
                            builder: (context, settings, _) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 200,
                                    child: DropdownButtonFormField<int>(
                                      key: ValueKey(
                                        'retention_dropdown_${settings.retentionYears}_$_dropdownKeyCounter',
                                      ),
                                      initialValue: settings.retentionYears,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 5,
                                          child: Text('5 Years'),
                                        ),
                                        DropdownMenuItem(
                                          value: 7,
                                          child: Text('7 Years'),
                                        ),
                                        DropdownMenuItem(
                                          value: 10,
                                          child: Text('10 Years'),
                                        ),
                                      ],
                                      onChanged: (v) {
                                        if (v != null) {
                                          _handleRetentionChange(
                                            context,
                                            settings,
                                            v,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Export Patients List',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Generate a Comma-separated values Excel (CSV) file containing all registered patient records for external use or reporting. Note that this doesn\'t include patient visitation data.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.file_download_rounded, size: 18),
                      label: const Text('Export to Excel/CSV'),
                      onPressed: () => _handleExportPatients(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // ── Database Backup & Restore ───────────────────────────────────
          _buildSectionHeader(
            'Database Backup & Restore',
            Icons.restore_rounded,
          ),
          const SizedBox(height: 16),
          Container(
            decoration: AppTheme.glassCard(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Automatic Backups',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A backup of the database is automatically created every time the app starts, before any updates or migrations are applied. '
                  'You can restore a previous backup if an update causes issues. Up to ${DatabaseBackupService.maxBackups} backups are kept.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                _buildBackupsList(),
              ],
            ),
          ),

          const SizedBox(height: 48),

          if (!AppConfig.isProduction) ...[
            // ── Developer Mode ─────────────────────────────────────────────
            _buildSectionHeader('Developer Settings', Icons.code_rounded),
            const SizedBox(height: 16),
            Container(
              decoration: AppTheme.glassCard(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Developer Mode',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enable additional debugging tools and mock data generators. This should only be used for development purposes.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Consumer<SettingsProvider>(
                        builder: (context, settings, _) {
                          return Switch(
                            value: settings.isDeveloperMode,
                            activeThumbColor: AppTheme.accent,
                            onChanged: (val) =>
                                settings.toggleDeveloperMode(val),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],

          // ── About & Licenses ──────────────────────────────────────────
          _buildSectionHeader('About ISKOLINIC', Icons.info_outline_rounded),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The ISKOLINIC Team',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildTeamMember(
                      'assets/dev-rovic.png',
                      'Rovic Aliman',
                      'Developer',
                    ),
                    _buildTeamMember(
                      'assets/dev-ac.png',
                      'Amparito Orticio',
                      'Researcher',
                    ),
                    _buildTeamMember(
                      'assets/dev-marvin.jpg',
                      'Marvin Uneta',
                      'Researcher',
                    ),
                    _buildTeamMember(
                      'assets/dev-aiza.jpg',
                      'Aiza Caballero',
                      'Researcher',
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                Text(
                  'License',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Copyright (c) 2026 IskoLinic Team\n'
                    'All Rights Reserved\n\n'
                    'This software and associated documentation files (the "Software") are proprietary. '
                    'The Software may not be copied, modified, distributed, or used without the express '
                    'written permission of the author.',
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'OLOPSC ISKOLINIC',
                        applicationVersion: _appVersion,
                        applicationIcon: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Image.asset(
                            'assets/app-icon-colored.png',
                            height: 64,
                          ),
                        ),
                        applicationLegalese: 'Developed by the ISKOLINIC Team',
                      );
                    },
                    icon: const Icon(Icons.source_rounded, size: 20),
                    label: const Text('View Third-Party Licenses'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
          if (_appVersion.isNotEmpty)
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Version $_appVersion',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  if (!AppConfig.isProduction) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
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
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.warning,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.accent),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppTheme.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildRadioTile({
    required int value,
    required bool isSelected,
    required String title,
    required String subtitle,
    required IconData icon,
    bool disabled = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: disabled ? 0.4 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.accent : AppTheme.cardLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : AppTheme.textMuted,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Radio<int>(value: value, activeColor: AppTheme.accent),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showUpdateSecretDialog(BuildContext context) async {
    final controller = TextEditingController(text: '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Sync Secret'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the new shared secret key used to authenticate with the cloud relay server.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                obscureText: true,
                decoration: InputDecoration(
                  label: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Sync Secret Key ',
                          style: GoogleFonts.inter(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        TextSpan(
                          text: '*',
                          style: GoogleFonts.inter(
                            color: AppTheme.danger,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await AuthService.instance.updateSyncSecret(controller.text);

                if (ctx.mounted) Navigator.pop(ctx);

                if (context.mounted) {
                  Provider.of<SyncProvider>(
                    context,
                    listen: false,
                  ).reconnectWithNewSecret();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sync secret updated and reconnecting...'),
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRetentionChange(
    BuildContext context,
    SettingsProvider settings,
    int newYears,
  ) async {
    final count = await DatabaseHelper.instance.countOldRecords(newYears);

    if (count > 0) {
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirm Retention Change'),
          content: Text(
            'Changing the retention period to $newYears years will mark $count patient record${count == 1 ? '' : 's'} for deletion.\n\n'
            'Are you sure you want to proceed with this policy change?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm Change'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        settings.updateRetentionYears(newYears);
        await DatabaseHelper.instance.purgeOldRecords(newYears);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Retention policy updated. $count records marked for deletion.',
              ),
            ),
          );
        }
      } else {
        // Revert the dropdown selection in the UI if cancelled or dismissed
        // We increment the counter to force the DropdownButtonFormField (using initialValue) to rebuild
        if (mounted) {
          setState(() {
            _dropdownKeyCounter++;
          });
        }
      }
    } else {
      settings.updateRetentionYears(newYears);
    }
  }

  Future<bool> _verifyPinBeforeExport() async {
    final pinController = TextEditingController();
    String? error;

    final isVerified = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Authentication Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'For security reasons, please enter your 6-digit access PIN to authorize the data export.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Enter PIN',
                  counterText: '',
                  prefixIcon: const Icon(Icons.lock_outline),
                  errorText: error,
                ),
                onChanged: (_) {
                  if (error != null) setDialogState(() => error = null);
                },
                onSubmitted: (value) async {
                  final isValid = await AuthService.instance.verifyPin(value);
                  if (isValid) {
                    if (context.mounted) Navigator.pop(context, true);
                  } else {
                    setDialogState(() => error = 'Incorrect PIN');
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                final isValid = await AuthService.instance.verifyPin(
                  pinController.text,
                );
                if (isValid) {
                  if (context.mounted) Navigator.pop(context, true);
                } else {
                  setDialogState(() => error = 'Incorrect PIN');
                }
              },
              child: const Text('VERIFY & EXPORT'),
            ),
          ],
        ),
      ),
    );
    return isVerified ?? false;
  }

  Future<void> _handleExportPatients(BuildContext context) async {
    // Verify PIN first
    final isAuthorized = await _verifyPinBeforeExport();
    if (!isAuthorized || !context.mounted) return;

    final patientProvider = Provider.of<PatientProvider>(
      context,
      listen: false,
    );

    try {
      final String? outputFile = await FilePicker.saveFile(
        dialogTitle: 'Save Patients List',
        fileName: 'Patients_List_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (outputFile == null) return;

      final path = await patientProvider.exportPatientsReport(
        savePath: outputFile,
      );

      if (path != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Patients list exported successfully to $path'),
            backgroundColor: AppTheme.accent,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export patients: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Widget _buildBackupsList() {
    return FutureBuilder<List<BackupInfo>>(
      future: DatabaseBackupService.listBackups(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final backups = snapshot.data ?? [];

        if (backups.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 12),
                Text(
                  'No backups available yet. A backup will be created the next time the app starts.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
          );
        }

        final dateFormatter = DateFormat('MMM d, yyyy – h:mm a');

        return Column(
          children: backups.map((backup) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.cardLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.dividerColor.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.storage_rounded,
                      color: AppTheme.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'v${backup.appVersion}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${dateFormatter.format(backup.createdAt)}  ·  ${backup.formattedSize}',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _handleRestore(context, backup),
                    icon: const Icon(Icons.restore_rounded, size: 16),
                    label: const Text('Restore/Revert'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.warning,
                      side: BorderSide(
                        color: AppTheme.warning.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _handleRestore(BuildContext context, BackupInfo backup) async {
    String? selectedRevertVersion;
    late Future<List<UpdateInfo>> olderReleasesFuture;

    olderReleasesFuture = () async {
      final packageInfo = await PackageInfo.fromPlatform();
      return await UpdateService.fetchOlderReleases(
        packageInfo.version,
        AppConfig.isProduction,
      );
    }();

    // Step 1: Confirm with user (includes version selector)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
              SizedBox(width: 10),
              Text('Restore Database Backup'),
            ],
          ),
          content: FutureBuilder<List<UpdateInfo>>(
            future: olderReleasesFuture,
            builder: (context, snapshot) {
              final olderReleases = snapshot.data ?? [];
              final isLoading =
                  snapshot.connectionState == ConnectionState.waiting;

              // Auto-select matching version once loaded if not already selected
              if (!isLoading && selectedRevertVersion == null) {
                if (olderReleases.any((r) => r.version == backup.appVersion)) {
                  // We can't call setDialogState directly here during build,
                  // but we can set the local variable for the initial value.
                  selectedRevertVersion = backup.appVersion;
                }
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You are about to restore the database to the backup from v${backup.appVersion} '
                    '(${backup.formattedSize}).',
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.danger.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          size: 18,
                          color: AppTheme.danger.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This will replace the current database with the backup. '
                            'A backup of the current state will be saved first. '
                            'The app will need to restart after restoring.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.danger.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Select App Version to Revert Back To (Optional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: selectedRevertVersion,
                        isExpanded: true,
                        hint: isLoading
                            ? const Text('Loading older versions...')
                            : const Text('Do not revert app version'),
                        disabledHint: isLoading
                            ? const Text('Loading older versions...')
                            : null,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'Only Restore Database (Keep Current App Version)',
                            ),
                          ),
                          ...olderReleases.map(
                            (release) => DropdownMenuItem<String?>(
                              value: release.version,
                              child: Text(
                                'Revert to v${release.version}${release.version == backup.appVersion ? " (Matches Backup)" : ""}',
                              ),
                            ),
                          ),
                        ],
                        onChanged: isLoading
                            ? null
                            : (val) {
                                setDialogState(
                                  () => selectedRevertVersion = val,
                                );
                              },
                      ),
                    ),
                  ),
                  if (selectedRevertVersion != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'The app will download and install v$selectedRevertVersion after restoring the database.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.accent.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warning,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Step 2: Verify PIN
    final isAuthorized = await _verifyPinBeforeExport();
    if (!isAuthorized || !context.mounted) return;

    // Step 3: Close DB and restore
    try {
      await DatabaseHelper.instance.close();
      final success = await DatabaseBackupService.restoreBackup(backup);

      if (!success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to restore backup. Please try again.'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
        return;
      }

      // Step 4: If user opted to revert app version, download the selected version
      if (selectedRevertVersion != null && context.mounted) {
        await _handleAppVersionRevert(context, selectedRevertVersion!);
      } else if (context.mounted) {
        // Just show the restart dialog
        await _showRestoreCompleteDialog(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _handleAppVersionRevert(
    BuildContext context,
    String targetVersion,
  ) async {
    // Show a downloading dialog
    double downloadProgress = 0;
    bool downloadStarted = false;
    String statusText = 'Finding v$targetVersion release...';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Start the download process (only once)
          if (!downloadStarted) {
            downloadStarted = true;
            _downloadOldVersion(
              targetVersion,
              onStatus: (status) {
                if (ctx.mounted) {
                  setDialogState(() => statusText = status);
                }
              },
              onProgress: (progress) {
                if (ctx.mounted) {
                  setDialogState(() => downloadProgress = progress);
                }
              },
              onComplete: (installerFile) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (installerFile != null) {
                    // Launch the old installer and exit
                    UpdateService.launchInstallerAndExit(installerFile);
                  } else {
                    // Download failed, show the restart dialog instead
                    _showRestoreCompleteDialog(
                      context,
                      extraMessage:
                          'Could not download v$targetVersion. The database was restored, but '
                          'the app version could not be reverted. You may need to manually install '
                          'the older version.',
                    );
                  }
                }
              },
            );
          }

          final percent = (downloadProgress * 100).toInt();

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.downloading_rounded, color: AppTheme.accent),
                const SizedBox(width: 10),
                Text(
                  downloadProgress > 0
                      ? 'Downloading v$targetVersion...'
                      : 'Preparing Download',
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(statusText),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: downloadProgress > 0 ? downloadProgress : null,
                    backgroundColor: AppTheme.cardLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.accent,
                    ),
                    minHeight: 6,
                  ),
                ),
                if (downloadProgress > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '$percent%',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accent,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _downloadOldVersion(
    String targetVersion, {
    required void Function(String status) onStatus,
    required void Function(double progress) onProgress,
    required void Function(File? installerFile) onComplete,
  }) async {
    try {
      onStatus('Looking up v$targetVersion on GitHub...');
      final release = await UpdateService.fetchRelease(targetVersion);

      if (release == null || release.downloadUrl.isEmpty) {
        onStatus('Release v$targetVersion not found.');
        await Future.delayed(const Duration(seconds: 1));
        onComplete(null);
        return;
      }

      onStatus('Downloading installer...');
      final file = await UpdateService.downloadInstaller(release.downloadUrl, (
        progress,
      ) {
        onProgress(progress);
        final percent = (progress * 100).toInt();
        onStatus('Downloading installer... $percent%');
      });

      onComplete(file);
    } catch (e) {
      onStatus('Download failed: $e');
      await Future.delayed(const Duration(seconds: 1));
      onComplete(null);
    }
  }

  Future<void> _showRestoreCompleteDialog(
    BuildContext context, {
    String? extraMessage,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.accent),
            SizedBox(width: 10),
            Text('Restore Complete'),
          ],
        ),
        content: Text(
          extraMessage ??
              'The database has been restored successfully. '
                  'Please close and reopen the application for the changes to take effect.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              exit(0);
            },
            child: const Text('Close App'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMember(String assetPath, String name, String role) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 180,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              assetPath,
              fit: BoxFit.fitHeight,
              alignment: Alignment.topCenter,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            role,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
