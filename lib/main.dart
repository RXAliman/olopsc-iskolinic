import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'logic/vvella_provider.dart';
import 'ui/vvella_screen.dart';

void main() {
  runApp(const VVellaApp());
}

class VVellaApp extends StatelessWidget {
  const VVellaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VvellaProvider()),
      ],
      child: MaterialApp(
        title: 'VVella',
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const VvellaScreen(),
      ),
    );
  }
}