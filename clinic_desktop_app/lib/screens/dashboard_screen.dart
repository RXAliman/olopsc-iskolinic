import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/patient_provider.dart';
import '../providers/analytics_provider.dart';
import '../theme/app_theme.dart';
import 'patient_list_screen.dart';
import 'analytics_screen.dart';

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
    _NavItem(Icons.people_rounded, 'Records'),
    _NavItem(Icons.bar_chart_rounded, 'Analytics'),
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
    final analyticsProvider = context.read<AnalyticsProvider>();

    await patientProvider.loadPatients();
    await analyticsProvider.loadAnalytics();
    final visits = await patientProvider.getTodayVisitCount();
    if (mounted) setState(() => _todayVisits = visits);
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardHome();
      case 1:
        return const PatientListScreen();
      case 2:
        return const AnalyticsScreen();
      default:
        return _buildDashboardHome();
    }
  }

  Widget _buildDashboardHome() {
    return Consumer<PatientProvider>(
      builder: (context, patients, _) {
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
                      label: 'Total Recorded',
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
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                const Spacer(),
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
