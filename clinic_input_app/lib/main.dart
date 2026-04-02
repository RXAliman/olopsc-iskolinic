import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/qr_scan_screen.dart';
import 'screens/input_form_screen.dart';
import 'screens/barcode_scanner_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/confirmation_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ClinicInputApp());
}

class ClinicInputApp extends StatelessWidget {
  const ClinicInputApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clinic Form',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const QrScanScreen(),
      routes: {
        '/scan': (_) => const QrScanScreen(),
        '/welcome': (_) => const WelcomeScreen(),
        '/barcode': (_) => const BarcodeScannerScreen(),
        '/form': (_) => const InputFormScreen(),
        '/confirmation': (_) => const ConfirmationScreen(),
      },
    );
  }
}
