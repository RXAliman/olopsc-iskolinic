import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/qr_scan_screen.dart';
import 'screens/input_form_screen.dart';
import 'screens/confirmation_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ClinicInputApp());
}

class ClinicInputApp extends StatelessWidget {
  const ClinicInputApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clinic Input',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const QrScanScreen(),
      routes: {
        '/form': (_) => const InputFormScreen(),
        '/confirmation': (_) => const ConfirmationScreen(),
      },
    );
  }
}
