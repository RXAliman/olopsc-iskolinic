import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/visitation.dart';
import '../providers/patient_provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/sync_provider.dart';
import '../theme/app_theme.dart';
import '../services/database_helper.dart';
import 'patient_list_screen.dart';
import 'patient_detail_screen.dart';
import 'visitation_form_screen.dart';
import 'analytics_screen.dart';
import 'inventory_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  final List<_NavItem> _navItems = [
    _NavItem(Icons.dashboard_rounded, 'Dashboard'),
    _NavItem(Icons.people_rounded, 'Patients'),
    _NavItem(Icons.inventory_2_rounded, 'Inventory'),
    _NavItem(Icons.bar_chart_rounded, 'Analytics'),
  ];

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    final patientProvider = context.read<PatientProvider>();
    final analyticsProvider = context.read<AnalyticsProvider>();

    await patientProvider.loadPatients();
    await analyticsProvider.loadAnalytics();
    await patientProvider.loadTodayVisits();
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardHome();
      case 1:
        return const PatientListScreen();
      case 2:
        return const InventoryScreen();
      case 3:
        return const AnalyticsScreen();
      default:
        return _buildDashboardHome();
    }
  }

  Widget _buildDashboardHome() {
    return Consumer<PatientProvider>(
      builder: (context, patients, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Welcome back!',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // School Info Card + Date/Time
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/OLOPSC.png',
                              width: 52,
                              height: 52,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'OUR LADY OF PERPETUAL SUCCOR COLLEGE',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Marikina City, Philippines',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('MMM. dd, yyyy').format(_now),
                          style: GoogleFonts.chivoMono(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('hh:mm:ss a').format(_now),
                          style: GoogleFonts.chivoMono(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.people_rounded,
                      label: 'Total Patients Recorded',
                      value: '${patients.allPatientsCount}',
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF59E0B),
                          Color(0xFFFBBF24),
                        ], // Yellow gradient
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.calendar_today_rounded,
                      label: "Patient Visits Today",
                      value: '${patients.todayVisits}',
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF3B82F6),
                          Color(0xFF60A5FA),
                        ], // Blue gradient
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                "Quick Actions",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const VisitationFormScreen(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    icon: const Icon(Icons.medical_services_rounded, size: 18),
                    label: const Text('Add Visitation'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reloading...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      await context.read<PatientProvider>().refreshAll();
                      if (context.mounted) {
                        context.read<SyncProvider>().forceSync();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppTheme.accent),
                      ),
                    ),
                    icon: const Icon(Icons.sync_rounded, size: 18),
                    label: const Text('Reload'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                "Today's Visitations",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              if (patients.dashboardVisits.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: AppTheme.glassCard(),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 48,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No visitations recorded today yet.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              else
                Container(
                  decoration: AppTheme.glassCard(),
                  child: Column(
                    children: [
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: patients.dashboardVisits.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: AppTheme.dividerColor,
                        ),
                        itemBuilder: (context, index) {
                          final data = patients.dashboardVisits[index];
                          final patientName =
                              data['patientName'] as String? ?? '';
                          final firstName = data['firstName'] as String? ?? '';
                          final visit = Visitation.fromMap(data);

                          return ListTile(
                            onTap: () async {
                              final provider = context.read<PatientProvider>();
                              final patient = await DatabaseHelper.instance
                                  .getPatient(visit.patientId);
                              if (patient != null) {
                                await provider.selectPatient(patient);
                                if (context.mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (_) => const PatientDetailScreen(),
                                  );
                                }
                              }
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  index == 0 && patients.todayVisits == 1
                                  ? BorderRadius.circular(16)
                                  : index == 0
                                  ? BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    )
                                  : (index ==
                                                patients.dashboardVisitPageSize -
                                                    1 &&
                                            patients.todayVisits ==
                                                patients
                                                    .dashboardVisitPageSize) ||
                                        (index == 1 &&
                                            patients.todayVisits == 2)
                                  ? BorderRadius.only(
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    )
                                  : BorderRadius.zero,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                gradient: AppTheme.accentGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  firstName.isNotEmpty
                                      ? firstName[0].toUpperCase()
                                      : (patientName.isNotEmpty
                                            ? patientName[0].toUpperCase()
                                            : '?'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  patientName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  DateFormat('hh:mm a').format(visit.dateTime),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (visit.symptoms.isNotEmpty)
                                    Text(
                                      'Symptoms: ${visit.symptoms.join(', ')}',
                                      style: const TextStyle(fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (visit.treatment.isNotEmpty ||
                                      visit.suppliesUsed.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Treatment: ${[...visit.suppliesUsed, if (visit.treatment.isNotEmpty) visit.treatment].join(', ')}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 4),
                                    TextButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => VisitationFormScreen(
                                            patientId: visit.patientId,
                                            visitation: visit,
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.add_circle_outline_rounded,
                                        size: 14,
                                      ),
                                      label: const Text(
                                        'Add Missing Intervention Details',
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 0,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        alignment: Alignment.centerLeft,
                                        textStyle: const TextStyle(
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      if (patients.totalDashboardVisitPages > 1)
                        _buildPagination(
                          patients,
                          patients.todayVisits,
                          patients.totalDashboardVisitPages,
                          patients.dashboardVisitPage *
                              patients.dashboardVisitPageSize,
                          (patients.dashboardVisitPage *
                                  patients.dashboardVisitPageSize) +
                              patients.dashboardVisits.length,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPagination(
    PatientProvider provider,
    int totalItems,
    int totalPages,
    int start,
    int end,
  ) {
    final currentPage = provider.dashboardVisitPage;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.dividerColor, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${start + 1}–$end of $totalItems visits',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          Row(
            children: [
              IconButton(
                onPressed: currentPage > 0
                    ? () => provider.firstDashboardVisitPage()
                    : null,
                icon: const Icon(Icons.first_page_rounded, size: 20),
                tooltip: 'First page',
                splashRadius: 18,
              ),
              IconButton(
                onPressed: currentPage > 0
                    ? () => provider.prevDashboardVisitPage()
                    : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 22),
                tooltip: 'Previous',
                splashRadius: 18,
              ),
              const SizedBox(width: 8),
              ..._buildPageNumbers(provider, totalPages),
              const SizedBox(width: 8),
              IconButton(
                onPressed: currentPage < totalPages - 1
                    ? () => provider.nextDashboardVisitPage()
                    : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
                tooltip: 'Next',
                splashRadius: 18,
              ),
              IconButton(
                onPressed: currentPage < totalPages - 1
                    ? () => provider.lastDashboardVisitPage()
                    : null,
                icon: const Icon(Icons.last_page_rounded, size: 20),
                tooltip: 'Last page',
                splashRadius: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers(PatientProvider provider, int totalPages) {
    final current = provider.dashboardVisitPage;
    return [
      Container(
        width: 64,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: AppTheme.accent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          '${current + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                        'ISKOLINIC',
                        style: GoogleFonts.audiowide(
                          textStyle: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B6B7D),
                              ),
                        ),
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

                // Sync Status
                Consumer<SyncProvider>(
                  builder: (context, sync, _) {
                    final isConnected = sync.isConnected;
                    final isConnecting = sync.isConnecting;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isConnected
                                  ? Colors.greenAccent
                                  : isConnecting
                                  ? Colors.orangeAccent
                                  : AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isConnected
                                ? 'Synced'
                                : isConnecting
                                ? 'Connecting...'
                                : 'Offline',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
