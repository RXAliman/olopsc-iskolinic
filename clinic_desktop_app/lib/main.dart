import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'providers/patient_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/sync_provider.dart';
import 'screens/dashboard_screen.dart';
// import 'services/mock_data_generator.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite FFI for Windows desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Seed mock data (only runs if DB is empty)
  // await MockDataGenerator.seedDatabase();

  // Initialize CRDT node identity
  final patientProvider = PatientProvider();
  await patientProvider.initCrdt();
  await patientProvider.loadPatients();

  // Initialize sync (no wsUrl = offline mode)
  final syncProvider = SyncProvider();
  await syncProvider.init(
    patientProvider,
    wsUrl: 'wss://olopsc-iskolinic.onrender.com/ws',
  );

  runApp(
    ClinicApp(patientProvider: patientProvider, syncProvider: syncProvider),
  );
}

class ClinicApp extends StatelessWidget {
  final PatientProvider patientProvider;
  final SyncProvider syncProvider;

  const ClinicApp({
    super.key,
    required this.patientProvider,
    required this.syncProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: patientProvider),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider.value(value: syncProvider),
      ],
      child: MaterialApp(
        title: 'IskoLinic App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const DashboardScreen(),
      ),
    );
  }
}
