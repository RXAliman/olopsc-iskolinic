import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset('assets/olopsc-hs-clinic-avp.mp4')
      ..initialize().then((_) {
        _videoController.setVolume(0.0);
        _videoController.setLooping(true);
        _videoController.play();
        setState(() {}); // Update to show video when initialized
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushReplacementNamed(context, '/form'),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/welcome-background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              // Upper portion: Logo (left) and Date/Time (right)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 40,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Upper left: OLOPCS Marikina City Logo
                    Image.asset(
                      'assets/olopsc-marikina-city.png',
                      height: 80, // Adjust size as needed
                      fit: BoxFit.contain,
                    ),
                    // Upper right: Date and Time
                    StreamBuilder(
                      stream: Stream.periodic(const Duration(seconds: 1)),
                      builder: (context, snapshot) {
                        final now = DateTime.now();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('EEEE, MMMM d, yyyy').format(now),
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('hh:mm a').format(now),
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Center texts
              Text(
                'OUR LADY OF PERPETUAL SUCCOR COLLEGE',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                  letterSpacing: 3.0,
                ),
              ),
              Text(
                'SCHOOL CLINIC SYSTEM',
                style: GoogleFonts.inter(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 24),

              // Video player area
              SizedBox(
                width: 640, // Base width, scales aspect ratio
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _videoController.value.isInitialized
                          ? VideoPlayer(_videoController)
                          : const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // POWERED BY + App Logo White
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'POWERED BY: ',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    'assets/app-logo-white.png',
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ],
              ),

              const Spacer(flex: 3),

              // Bottom white bar with animated text
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: AnimatedTextKit(
                    animatedTexts: [
                      TyperAnimatedText(
                        'PRESS ANYWHERE TO CONTINUE',
                        textStyle: GoogleFonts.inter(
                          fontSize: 30,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1B4697),
                          letterSpacing: 1.2,
                        ),
                        speed: const Duration(milliseconds: 60),
                        textAlign: TextAlign.left,
                      ),
                    ],
                    repeatForever: true,
                    pause: const Duration(seconds: 4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
