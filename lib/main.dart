import 'package:flutter/material.dart';
import 'package:vvella/pages/home.dart';

Future<void> main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VVella',
      home: const HomePage(),
    );
  }
}