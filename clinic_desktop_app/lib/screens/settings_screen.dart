import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../constants/app_config.dart';
import '../providers/settings_provider.dart';
import '../providers/sync_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';
  
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
                child: Column(
                  children: [
                    _buildRadioTile(
                      value: 1,
                      groupValue: settings.connectionMode,
                      title: 'Local Area Network (LAN)',
                      subtitle:
                          'Connect directly to other devices on the same Wi-Fi or Ethernet. Best for real-time local sync.',
                      icon: Icons.router_rounded,
                      disabled: true, // As requested, grayed out
                      onChanged: null,
                    ),
                    const Divider(),
                    _buildRadioTile(
                      value: 2,
                      groupValue: settings.connectionMode,
                      title: 'Relay Server',
                      subtitle:
                          'Sync through a central secure server. Works across different networks and over the internet.',
                      icon: Icons.cloud_done_rounded,
                      onChanged: (v) {
                        settings.updateConnectionMode(v);
                        sync.setConnectionMode(v);
                      },
                    ),
                    const Divider(),
                    _buildRadioTile(
                      value: 0,
                      groupValue: settings.connectionMode,
                      title: 'Work Offline',
                      subtitle:
                          'Keep all data on this device only. Synchronization is disabled.',
                      icon: Icons.cloud_off_rounded,
                      onChanged: (v) {
                        settings.updateConnectionMode(v);
                        sync.setConnectionMode(v);
                      },
                    ),
                  ],
                ),
              );
            },
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
                  'Developers',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('The ISKOLINIC Core Development Team'),
                const SizedBox(height: 24),

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
                    'MIT License\n\n'
                    'Copyright (c) 2026 Rovic Xavier Aliman\n\n'
                    'Permission is hereby granted, free of charge, to any person obtaining a copy '
                    'of this software and associated documentation files (the "Software"), to deal '
                    'in the Software without restriction, including without limitation the rights '
                    'to use, copy, modify, merge, publish, distribute, sublicense, and/or sell '
                    'copies of the Software, and to permit persons to whom the Software is '
                    'furnished to do so, subject to the following conditions:\n\n'
                    'The above copyright notice and this permission notice shall be included in all '
                    'copies or substantial portions of the Software.\n\n'
                    'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR '
                    'IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, '
                    'FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE '
                    'AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER '
                    'LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, '
                    'OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE '
                    'SOFTWARE.',
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
                        applicationName: 'ISKOLINIC',
                        applicationVersion: '1.0.0',
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
    required int groupValue,
    required String title,
    required String subtitle,
    required IconData icon,
    bool disabled = false,
    ValueChanged<int>? onChanged,
  }) {
    final isSelected = groupValue == value;
    return InkWell(
      onTap: (disabled || onChanged == null) ? null : () => onChanged(value),
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
              Radio<int>(
                value: value,
                groupValue: groupValue,
                onChanged: (disabled || onChanged == null)
                    ? null
                    : (v) => onChanged(v!),
                activeColor: AppTheme.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
