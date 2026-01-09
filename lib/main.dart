import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'logic/vvella_provider.dart';
import 'pages/home.dart';
import 'pages/splash.dart';

void main() {
  runApp(const VVellaApp());
}

class VVellaApp extends StatelessWidget {
  const VVellaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => VvellaProvider())],
      child: MaterialApp(
        title: 'VVella',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: Consumer<VvellaProvider>(
          builder: (context, provider, _) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: provider.state == VoiceState.initializing
                  ? SplashContent(
                      key: const ValueKey('splash'),
                      progress: provider.loadingProgress,
                      message: provider.statusMessage,
                    )
                  : const HomePage(key: ValueKey('home')),
            );
          },
        ),
      ),
    );
  }
}
