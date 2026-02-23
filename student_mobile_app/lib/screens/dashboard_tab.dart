import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/medical_provider.dart';
import '../providers/symptom_tracking_provider.dart';
import '../providers/emergency_provider.dart';
import '../theme/app_theme.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const SizedBox(height: 8),
            Text(
              'Welcome back,',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              user.studentName,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 4),
            Text(
              user.studentNumber,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),

            // Summary Cards
            Consumer3<
              MedicalProvider,
              SymptomTrackingProvider,
              EmergencyProvider
            >(
              builder: (context, medical, tracking, emergency, _) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            icon: Icons.medical_information_rounded,
                            label: 'Medical Records',
                            value: '${medical.totalRecords}',
                            gradient: AppTheme.accentGradient,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            icon: Icons.monitor_heart_rounded,
                            label: 'Clinic Visits',
                            value: '${tracking.totalVisits}',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            icon: Icons.schedule_rounded,
                            label: 'Pending Follow-ups',
                            value: '${tracking.pendingFollowUps}',
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            icon: Icons.check_circle_rounded,
                            label: 'Acknowledged',
                            value: '${medical.acknowledgedCount}',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            // Guardian Status
            Text(
              'Guardian Link',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassCard(),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: user.guardianEmail.isNotEmpty
                          ? AppTheme.accent.withValues(alpha: 0.15)
                          : AppTheme.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      user.guardianEmail.isNotEmpty
                          ? Icons.link_rounded
                          : Icons.link_off_rounded,
                      color: user.guardianEmail.isNotEmpty
                          ? AppTheme.accent
                          : AppTheme.warning,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.guardianEmail.isNotEmpty
                              ? user.guardianName.isNotEmpty
                                    ? user.guardianName
                                    : 'Guardian Linked'
                              : 'No Guardian Linked',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.guardianEmail.isNotEmpty
                              ? user.guardianEmail
                              : 'Link a parent/guardian in Profile',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    user.guardianEmail.isNotEmpty
                        ? Icons.check_circle_rounded
                        : Icons.arrow_forward_ios_rounded,
                    color: user.guardianEmail.isNotEmpty
                        ? AppTheme.accent
                        : AppTheme.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _QuickAction(
              icon: Icons.add_circle_outline_rounded,
              label: 'Upload Medical Data',
              subtitle: 'Add a new medical record or document',
              onTap: () {
                // Navigate to medical tab
                final homeState = context
                    .findAncestorStateOfType<State<StatefulWidget>>();
                if (homeState != null && homeState.mounted) {
                  // Note: handled via bottom nav in home_screen
                }
              },
            ),
            const SizedBox(height: 8),
            Consumer<SymptomTrackingProvider>(
              builder: (context, tracking, _) => _QuickAction(
                icon: Icons.science_rounded,
                label: 'Simulate Clinic Visit',
                subtitle: 'Add a demo visitation for testing',
                onTap: () {
                  tracking.simulateVisitation(user.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Demo visitation added!')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final LinearGradient gradient;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 26, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.glassCard(),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
