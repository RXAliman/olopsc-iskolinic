import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_ce_flutter/adapters.dart';
// import 'package:vvella/alt/testing.dart';
import 'package:vvella/pages/home.dart';
import 'package:vvella/services/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  await Hive.openBox(bloodPressureLogBoxName);
  await Hive.openBox(bloodSugarLogBoxName);
  await Hive.openBox(weightLogBoxName);
  await Hive.openBox(exerciseLogBoxName);
  await Hive.openBox(mealLogBoxName);
  await Hive.openBox(sleepLogBoxName);
  await Hive.openBox(waterIntakeLogBoxName);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VVella',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18.0, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 16.0, color: Colors.black54),
          titleLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
        ),
      ),
      home: const HomePage(),
      // home: const TestingPage(),
    );
  }
}