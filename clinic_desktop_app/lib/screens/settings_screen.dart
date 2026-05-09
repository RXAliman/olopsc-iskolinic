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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';
  int _dropdownKeyCounter = 0;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
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
                    if (v == null || v == 1) return; // LAN is disabled
                    settings.updateConnectionMode(v);
                    sync.setConnectionMode(v);
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
                        disabled: true, // As requested, grayed out
                        onTap: null,
                      ),
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
                          sync.setConnectionMode(2);
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
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Retention Policy',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
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
              ],
            ),
          ),

          const SizedBox(height: 48),

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
