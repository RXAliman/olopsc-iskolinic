import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'providers/patient_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/local_server_provider.dart';
import 'screens/dashboard_screen.dart';
// import 'services/mock_data_generator.dart';
// import 'services/database_helper.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite FFI for Windows desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // TODO: Delete this after testing
  // Clear the database
  // await DatabaseHelper.instance.clearAllData();

  // Seed mock data (only runs if DB is empty)
  // await MockDataGenerator.seedDatabase(count: 100, visitationsPerPatient: 20);

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

  // Wire auto-push: every local write triggers an immediate sync push
  patientProvider.setOnLocalWrite(() => syncProvider.pushChanges());

  // Initialize inventory
  final inventoryProvider = InventoryProvider();
  await inventoryProvider.loadInventory();

  // Wire auto-deduct: visitation supplies auto-deduct from inventory
  patientProvider.setInventoryProvider(inventoryProvider);

  // Initialize local HTTP server for tablet connection
  final localServerProvider = LocalServerProvider();
  await localServerProvider.startServer();

  // When tablet submits a patient, refresh the desktop UI
  localServerProvider.setOnDataChanged(() {
    patientProvider.refreshAll();
  });

  runApp(
    ClinicApp(
      patientProvider: patientProvider,
      syncProvider: syncProvider,
      inventoryProvider: inventoryProvider,
      localServerProvider: localServerProvider,
    ),
  );
}

class ClinicApp extends StatelessWidget {
  final PatientProvider patientProvider;
  final SyncProvider syncProvider;
  final InventoryProvider inventoryProvider;
  final LocalServerProvider localServerProvider;

  const ClinicApp({
    super.key,
    required this.patientProvider,
    required this.syncProvider,
    required this.inventoryProvider,
    required this.localServerProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: patientProvider),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider.value(value: syncProvider),
        ChangeNotifierProvider.value(value: inventoryProvider),
        ChangeNotifierProvider.value(value: localServerProvider),
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
