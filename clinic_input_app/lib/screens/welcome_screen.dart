import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import '../services/persistent_form_service.dart';
import '../widgets/responsive_layout.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  Timer? _resetTimer;
  Timer? _sleepTimer;
  bool _isSleeping = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
    _startTimers();
  }

  void _startTimers() {
    _stopTimers();
    // 10-minute reset timer
    _resetTimer = Timer(const Duration(minutes: 10), () {
      if (mounted) {
        PersistentFormService.instance.clear();
      }
    });

    // 1-hour sleep timer
    _sleepTimer = Timer(const Duration(hours: 1), () {
      if (mounted) {
        setState(() => _isSleeping = true);
        _videoController?.pause();
      }
    });
  }

  void _stopTimers() {
    _resetTimer?.cancel();
    _sleepTimer?.cancel();
  }

  void _initVideo() {
    if (_isSleeping) return;
    _videoController =
        VideoPlayerController.asset('assets/olopsc-hs-clinic-avp.mp4')
          ..initialize().then((_) {
            if (!mounted) return;
            _videoController!.setVolume(0.0);
            _videoController!.setLooping(true);
            _videoController!.play();
            setState(() => _videoInitialized = true);
          });
  }

  Future<void> _handleTap() async {
    if (_isSleeping) {
      setState(() => _isSleeping = false);
      _initVideo();
      _startTimers();
      return;
    }

    if (PersistentFormService.instance.hasData) {
      final choice = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.history_rounded, color: Color(0xFF1B4697)),
              SizedBox(width: 12),
              Text('Resume Progress?'),
            ],
          ),
          content: const Text(
            'We found an unsaved form. Would you like to continue where you left off or start a new form?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'reset'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Start New'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'resume'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4697),
              ),
              child: const Text('Resume'),
            ),
          ],
        ),
      );

      if (choice == 'reset') {
        PersistentFormService.instance.clear();
      } else if (choice == null) {
        return; // Dialog cancelled or dismissed
      }
    }

    // Fully dispose video to release hardware codec buffers for the camera
    await _videoController?.dispose();
    _videoController = null;
    _videoInitialized = false;

    if (!mounted) return;

    final route = PersistentFormService.instance.isEmpty
        ? '/id-method'
        : '/form';
    await Navigator.pushNamed(context, route);

    // Re-initialize video when coming back
    if (mounted) {
      _initVideo();
      _startTimers(); // Restart timers when returning to welcome screen
    }
  }

  @override
  void dispose() {
    _stopTimers();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isSleeping) {
      return GestureDetector(
        onTap: _handleTap,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TAP ANYWHERE TO WAKE',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 16),
                Opacity(
                  opacity: 0.3,
                  child: Image.asset(
                    'assets/app-logo-white.png',
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isMobile = ResponsiveLayout.isMobile(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: _handleTap,
      child: Scaffold(
        extendBody: false,
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
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 32,
                  vertical: isMobile ? 30 : 40,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Upper left: OLOPCS Marikina City Logo
                    Image.asset(
                      'assets/olopsc-marikina-city.png',
                      height: isMobile ? 40 : 80,
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
                                fontSize: isMobile ? 14 : 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('hh:mm a').format(now),
                              style: GoogleFonts.inter(
                                fontSize: isMobile ? 14 : 18,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      'OUR LADY OF PERPETUAL SUCCOR COLLEGE',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 12 : 18,
                        fontWeight: FontWeight.normal,
                        color: Colors.white,
                        letterSpacing: isMobile ? 1.5 : 3.0,
                      ),
                    ),
                    Text(
                      'SCHOOL CLINIC SYSTEM',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 28 : 48,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: isMobile ? 1.0 : 2.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Video player area
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                width: isMobile ? screenWidth : 640,
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
                      child: _videoInitialized && _videoController != null
                          ? VideoPlayer(_videoController!)
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
                      fontSize: isMobile ? 10 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    'assets/app-logo-white.png',
                    height: isMobile ? 25 : 40,
                    fit: BoxFit.contain,
                  ),
                ],
              ),

              const Spacer(flex: 3),

              // Bottom white bar with animated text
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isMobile ? 20 : 32),
                child: Center(
                  child: AnimatedTextKit(
                    animatedTexts: [
                      TyperAnimatedText(
                        'TAP ANYWHERE TO CONTINUE',
                        textStyle: GoogleFonts.inter(
                          fontSize: isMobile ? 18 : 30,
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
