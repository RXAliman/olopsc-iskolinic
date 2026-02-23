import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/medical_provider.dart';
import 'providers/symptom_tracking_provider.dart';
import 'providers/emergency_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  runApp(const StudentApp());
}

class StudentApp extends StatelessWidget {
  const StudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MedicalProvider()),
        ChangeNotifierProvider(create: (_) => SymptomTrackingProvider()),
        ChangeNotifierProvider(create: (_) => EmergencyProvider()),
      ],
      child: MaterialApp(
        title: 'VVella Student',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
