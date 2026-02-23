import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/medical_provider.dart';
import '../providers/symptom_tracking_provider.dart';
import '../providers/emergency_provider.dart';
import '../theme/app_theme.dart';
import 'dashboard_tab.dart';
import 'medical_records_screen.dart';
import 'symptom_tracking_screen.dart';
import 'profile_screen.dart';
import 'emergency_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    DashboardTab(),
    MedicalRecordsScreen(),
    SymptomTrackingScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    context.read<MedicalProvider>().loadRecords(user.id);
    context.read<SymptomTrackingProvider>().loadVisitations(user.id);
    context.read<EmergencyProvider>().loadAlerts(user.id);
  }

  void _openEmergency() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmergencyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medical_information_rounded),
              label: 'Medical',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.monitor_heart_rounded),
              label: 'Tracking',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEmergency,
        backgroundColor: AppTheme.danger,
        icon: const Icon(Icons.emergency_rounded, color: Colors.white),
        label: const Text(
          'SOS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
