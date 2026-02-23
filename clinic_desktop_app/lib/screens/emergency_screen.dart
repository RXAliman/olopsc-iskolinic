import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/emergency_provider.dart';
import '../theme/app_theme.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EmergencyProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency Alerts',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${provider.unacknowledgedCount} active alert(s)',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: provider.hasActiveAlerts
                                    ? AppTheme.danger
                                    : AppTheme.textMuted,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Simulate Alert Button (for testing)
                  OutlinedButton.icon(
                    onPressed: () => provider.simulateAlert(),
                    icon: const Icon(Icons.bug_report_rounded, size: 18),
                    label: const Text('Simulate Alert'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.warning,
                      side: const BorderSide(color: AppTheme.warning),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Active Alerts Banner
              if (provider.hasActiveAlerts)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.dangerGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.danger.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_rounded,
                        size: 28,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '⚠ ACTIVE EMERGENCY',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${provider.unacknowledgedCount} unacknowledged alert(s) require attention',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Alert List
              Expanded(
                child: provider.alerts.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        itemCount: provider.alerts.length,
                        itemBuilder: (context, index) {
                          final alert = provider.alerts[index];
                          final isActive = !alert.acknowledged;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppTheme.danger.withValues(alpha: 0.08)
                                  : null,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isActive
                                    ? AppTheme.danger.withValues(alpha: 0.3)
                                    : AppTheme.dividerColor,
                                width: isActive ? 1.5 : 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Status Icon
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppTheme.danger.withValues(alpha: 0.2)
                                        : AppTheme.cardLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isActive
                                        ? Icons.notification_important_rounded
                                        : Icons.check_circle_outline_rounded,
                                    color: isActive
                                        ? AppTheme.danger
                                        : AppTheme.accent,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Alert Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            alert.studentName,
                                            style: TextStyle(
                                              color: isActive
                                                  ? AppTheme.dangerLight
                                                  : AppTheme.textPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? AppTheme.danger.withValues(
                                                      alpha: 0.2,
                                                    )
                                                  : AppTheme.accent.withValues(
                                                      alpha: 0.15,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isActive ? 'ACTIVE' : 'RESOLVED',
                                              style: TextStyle(
                                                color: isActive
                                                    ? AppTheme.dangerLight
                                                    : AppTheme.accent,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${alert.studentNumber} • ${DateFormat('MMM dd, yyyy – hh:mm a').format(alert.timestamp)}',
                                        style: const TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (alert.message.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          alert.message,
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // Acknowledge Button
                                if (isActive)
                                  ElevatedButton(
                                    onPressed: () =>
                                        provider.acknowledgeAlert(alert.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.accent,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text('Acknowledge'),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.shield_rounded,
              size: 40,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(height: 20),
          Text('All Clear', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'No emergency alerts at the moment',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text(
            'Use "Simulate Alert" to test the system',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
