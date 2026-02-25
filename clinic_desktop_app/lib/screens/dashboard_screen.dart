import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/patient_provider.dart';
import '../providers/emergency_provider.dart';
import '../providers/analytics_provider.dart';
import '../theme/app_theme.dart';
import 'patient_list_screen.dart';
import 'analytics_screen.dart';
import 'emergency_screen.dart';
import 'queue_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  int _todayVisits = 0;

  final List<_NavItem> _navItems = [
    _NavItem(Icons.dashboard_rounded, 'Dashboard'),
    _NavItem(Icons.format_list_numbered_rounded, 'Queue'),
    _NavItem(Icons.people_rounded, 'Patients'),
    _NavItem(Icons.bar_chart_rounded, 'Analytics'),
    _NavItem(Icons.warning_amber_rounded, 'Emergency'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    final patientProvider = context.read<PatientProvider>();
    final emergencyProvider = context.read<EmergencyProvider>();
    final analyticsProvider = context.read<AnalyticsProvider>();

    await patientProvider.loadPatients();
    emergencyProvider.startListening();
    await analyticsProvider.loadAnalytics();
    final visits = await patientProvider.getTodayVisitCount();
    if (mounted) setState(() => _todayVisits = visits);
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardHome();
      case 1:
        return const QueueScreen();
      case 2:
        return const PatientListScreen();
      case 3:
        return const AnalyticsScreen();
      case 4:
        return const EmergencyScreen();
      default:
        return _buildDashboardHome();
    }
  }

  Widget _buildDashboardHome() {
    return Consumer2<PatientProvider, EmergencyProvider>(
      builder: (context, patients, emergency, _) {
        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome back, Admin',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.people_rounded,
                      label: 'Total Patients',
                      value: '${patients.totalPatients}',
                      gradient: AppTheme.accentGradient,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.calendar_today_rounded,
                      label: "Today's Visits",
                      value: '$_todayVisits',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.warning_amber_rounded,
                      label: 'Active Alerts',
                      value: '${emergency.unacknowledgedCount}',
                      gradient: emergency.hasActiveAlerts
                          ? AppTheme.dangerGradient
                          : const LinearGradient(
                              colors: [Color(0xFF475569), Color(0xFF64748B)],
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _QuickAction(
                    icon: Icons.person_add_rounded,
                    label: 'Add Patient',
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                  const SizedBox(width: 16),
                  _QuickAction(
                    icon: Icons.analytics_rounded,
                    label: 'View Analytics',
                    onTap: () => setState(() => _selectedIndex = 3),
                  ),
                  const SizedBox(width: 16),
                  _QuickAction(
                    icon: Icons.notifications_active_rounded,
                    label: 'Check Alerts',
                    onTap: () => setState(() => _selectedIndex = 4),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final emergencyProvider = context.watch<EmergencyProvider>();

    return Scaffold(
      body: Row(
        children: [
          // ── Sidebar ──
          Container(
            width: 240,
            decoration: const BoxDecoration(
              color: AppTheme.sidebarBg,
              border: Border(
                right: BorderSide(color: AppTheme.dividerColor, width: 0.5),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // App Logo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/app-icon-colored.png',
                          width: 40,
                          height: 40,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'IskoLinic',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Nav Items
                ...List.generate(_navItems.length, (i) {
                  final item = _navItems[i];
                  final isSelected = _selectedIndex == i;
                  final hasAlert = i == 4 && emergencyProvider.hasActiveAlerts;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => setState(() => _selectedIndex = i),
                        borderRadius: BorderRadius.circular(12),
                        hoverColor: Colors.white.withValues(alpha: 0.05),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected
                                ? AppTheme.accent.withValues(alpha: 0.12)
                                : Colors.transparent,
                            border: isSelected
                                ? Border.all(
                                    color: AppTheme.accent.withValues(
                                      alpha: 0.3,
                                    ),
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 20,
                                color: isSelected
                                    ? AppTheme.accent
                                    : AppTheme.textMuted,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                item.label,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppTheme.accent
                                      : AppTheme.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  fontSize: 14,
                                ),
                              ),
                              if (hasAlert) ...[
                                const Spacer(),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.danger,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                const Spacer(),

                // Logout
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 20,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => context.read<AuthProvider>().logout(),
                      borderRadius: BorderRadius.circular(12),
                      hoverColor: AppTheme.danger.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.logout_rounded,
                              size: 20,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Logout',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Main Content ──
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem(this.icon, this.label);
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
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
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: Colors.white.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: AppTheme.glassCard(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppTheme.accent, size: 22),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
